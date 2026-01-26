import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

base class RenewApi {
  static const String runBeforeKey = 'Api.hasRunBefore';
  static const String authSchema = 'Renew';
  static const String _kAccessTokenKey = 'accessToken';
  static const String _kRefreshTokenKey = 'refreshToken';
  static const Duration _kRefreshPeriod = Duration(minutes: 10);
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)
  );

  final String _appName;
  final String _version;
  final String _url;
  String _refreshToken;
  String _accessToken;

  Completer<Object?>? _refreshCompleter;
  DateTime? _tokenSetTime;

  RenewApi._(
    this._url,
    this._accessToken,
    this._refreshToken,
    this._version,
    this._appName
  );

  // https://github.com/mogol/flutter_secure_storage/issues/88#issuecomment-1151689347
  static Future<void> _clearSecureStorageOnReinstall() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(runBeforeKey) ?? false) return;

    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
    await prefs.setBool(runBeforeKey, true);
  }

  Future<void> _setApiData(String accessToken, String refreshToken) async {
    await _storage.write(key: _kAccessTokenKey, value: accessToken);
    await _storage.write(key: _kRefreshTokenKey, value: refreshToken);

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenSetTime = DateTime.now();
  }

  static Future<RenewApi> init({required String appName, required String url}) async {
    await FkUserAgent.init();
    await _clearSecureStorageOnReinstall();

    return RenewApi._(
      url,
      await _storage.read(key: _kAccessTokenKey) ?? '',
      await _storage.read(key: _kRefreshTokenKey) ?? '',
      (await PackageInfo.fromPlatform()).version,
      appName
    );
  }

  bool get isLoggedIn => _accessToken != '';

  Future<void> login({required String login, required String password}) async {
    await _setApiData('', '');

    final result = await _rawRequest(
      'v2/authenticate',
      'POST',
      { 'Authorization': '$authSchema login=$login,password=$password' }
    );

    await _setApiData(result['access_token'], result['refresh_token']);
  }

  Future<void> logout() async {
    await _setApiData('', '');
  }

  Future<void> register({required String email, required String telNum, required String password}) async {
    await _setApiData('', '');

    final result =  await _rawRequest(
      'v2/register',
      'POST',
      { 'Authorization': authSchema },
      null,
      { 'email': email, 'tel_num': telNum, 'password': password }
    );

    await _setApiData(result['access_token'], result['refresh_token']);
  }

  Future<void> unregister() async {
    await _rawRequest('v2/unregister', 'POST', { 'Authorization': '$authSchema token=$_accessToken' });

    await _setApiData('', '');
  }

  Future<void> resetPassword({required String login}) async {
    await _setApiData('', '');

    await _rawRequest('v2/reset_password', 'POST', { 'Authorization': '$authSchema login=$login' });
  }

  Future<dynamic> get(String apiMethod, {Map<String, dynamic>? query}) async {
    await _refreshTokens();

    return await _rawRequest(apiMethod, 'GET', { 'Authorization': '$authSchema token=$_accessToken' }, query);
  }

  Future<dynamic> post(String apiMethod, {Map<String, dynamic>? query, Object? data}) async {
    await _refreshTokens();

    return await _rawRequest(apiMethod, 'POST', { 'Authorization': '$authSchema token=$_accessToken' }, query, data);
  }

  Future<dynamic> put(String apiMethod, {Map<String, dynamic>? query, Object? data}) async {
    await _refreshTokens();

    return await _rawRequest(apiMethod, 'PUT', { 'Authorization': '$authSchema token=$_accessToken' }, query, data);
  }

  Future<void> _refreshTokens() async {
    if (_tokenSetTime != null && DateTime.now().difference(_tokenSetTime!) < _kRefreshPeriod) return;

    if (_refreshCompleter != null) {
      final error = await _refreshCompleter!.future;

      if (error != null) throw error;
      return;
    }

    try {
      _refreshCompleter = Completer();
      final result = await _rawRequest('v2/refresh', 'POST', { 'Authorization': '$authSchema token=$_refreshToken' });

      await _setApiData(result['access_token'], result['refresh_token']);
      _refreshCompleter!.complete(null);
    } catch(e) {
      _refreshCompleter!.complete(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<dynamic> _rawRequest(
    String apiMethod,
    String method,
    Map<String, String> headers,
    [
      Map<String, dynamic>? query,
      Object? data
    ]
  ) async {
    Map<String, dynamic> baseHeaders = {
      'Accept': 'application/json',
      _appName: _version,
      HttpHeaders.userAgentHeader: '$_appName/$_version ${FkUserAgent.userAgent}',
    };
    final dio = Dio(BaseOptions(
      baseUrl: _url,
      connectTimeout: const Duration(minutes: 1),
      sendTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 10),
      headers: baseHeaders,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));
    final options = Options(method: method, headers: headers);

    try {
      return (await dio.request(apiMethod, data: data, queryParameters: query, options: options)).data;
    } on DioException catch(e) {
      _onDioException(e);
    }
  }

  static void _onDioException(DioException e) {
    if (e.response != null) {
      final int statusCode = e.response!.statusCode!;
      final dynamic body = e.response!.data;

      if (statusCode < 200) {
        throw ApiException('Ошибка при получении данных', statusCode);
      }

      if (statusCode >= 500) {
        throw ServerException(statusCode);
      }

      if (statusCode == 413) {
        throw PayloadTooLargeException();
      }

      if (body is! Map) {
        throw UnknownApiException('Не известная ошибка: $body', statusCode);
      }

      if (statusCode == 401) {
        throw AuthException(body['error']);
      }

      if (statusCode == 410) {
        throw VersionException(body['error']);
      }

      if (statusCode >= 400) {
        throw ApiException(body['error'], statusCode);
      }
    } else {
      if (
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout
      ) {
        throw ApiConnTimeoutException();
      }

      if (
        e.error is SocketException ||
        e.error is HandshakeException ||
        e.error is HttpException ||
        e.error is TlsException
      ) {
        throw ApiConnException();
      }

      throw e;
    }
  }
}

class ApiException implements Exception {
  String errorMsg;
  int statusCode;

  ApiException(this.errorMsg, this.statusCode);
}

class AuthException extends ApiException {
  AuthException(errorMsg) : super('Необходимо заново войти в приложение. $errorMsg', 401);
}

class ServerException extends ApiException {
  ServerException(statusCode) : super('Нет связи с сервером', statusCode);
}

class ApiConnTimeoutException extends ApiException {
  ApiConnTimeoutException() : super('Сервер не отвечает', 522);
}

class ApiConnException extends ApiException {
  ApiConnException() : super('Не удается установить соединение с сервером', 503);
}

class VersionException extends ApiException {
  VersionException(errorMsg) : super(errorMsg, 410);
}

class PayloadTooLargeException extends ApiException {
  PayloadTooLargeException() : super('Объем отправляемых данных слишком большой', 413);
}

class UnknownApiException extends ApiException {
  UnknownApiException(super.errorMsg, super.statusCode);
}
