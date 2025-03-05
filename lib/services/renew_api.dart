import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

base class RenewApi {
  static const String runBeforeKey = 'Api.hasRunBefore';
  static const String authSchema = 'Renew';
  static const _kAccessTokenKey = 'accessToken';
  static const _kRefreshTokenKey = 'refreshToken';
  static const _kUrlKey = 'url';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true)
  );

  final String _appName;
  final String _version;
  String _refreshToken;
  String _url;
  String _accessToken;

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

    await _storage.delete(key: _kUrlKey);
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
    await prefs.setBool(runBeforeKey, true);
  }

  Future<void> _setApiData(String url, String accessToken, String refreshToken) async {
    await _storage.write(key: _kUrlKey, value: url);
    await _storage.write(key: _kAccessTokenKey, value: accessToken);
    await _storage.write(key: _kRefreshTokenKey, value: refreshToken);

    _url = url;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  static Future<RenewApi> init({
    required String appName,
    String? url
  }) async {
    await FkUserAgent.init();
    await _clearSecureStorageOnReinstall();

    return RenewApi._(
      await _storage.read(key: _kUrlKey) ?? url ?? '',
      await _storage.read(key: _kAccessTokenKey) ?? '',
      await _storage.read(key: _kRefreshTokenKey) ?? '',
      (await PackageInfo.fromPlatform()).version,
      appName
    );
  }

  bool get isLoggedIn => _url != '' && _accessToken != '';

  Map<String, String> Function() get _accessGenerator =>
    () => _accessToken.isEmpty ? {} : { 'Authorization': '$authSchema token=$_accessToken' };
  Map<String, String> Function() get _refreshGenerator =>
    () => _refreshToken.isEmpty ? {} : { 'Authorization': '$authSchema token=$_refreshToken' };

  Future<void> login({
    required String url,
    required String login,
    required String password
  }) async {
    await _setApiData(url, '', '');

    loginGenerator() => { 'Authorization': '$authSchema login=$login,password=$password' };
    final result = await _request('v2/authenticate', 'POST', loginGenerator, authRefresh: false);

    await _setApiData(url, result['access_token'], result['refresh_token']);
  }

  Future<void> refresh() async {
    final result = await _request('v2/refresh', 'POST', _refreshGenerator, authRefresh: false);

    await _setApiData(_url, result['access_token'], result['refresh_token']);
  }

  Future<void> logout() async {
    await _setApiData('', '', '');
  }

  Future<void> resetPassword({
    required String url,
    required String login
  }) async {
    await _setApiData(url, '', '');

    resetGenerator() => { 'Authorization': '$authSchema login=$login' };
    await _request('v2/reset_password', 'POST', resetGenerator, authRefresh: false);
  }

  Future<void> register({
    required String url,
    required String email,
    required String telNum,
    required String password
  }) async {
    await _setApiData(url, '', '');

    resetGenerator() => { 'Authorization': authSchema };
    generator() => { 'email': email, 'tel_num': telNum, 'password': password };

    final result =  await _request('v2/register', 'POST', resetGenerator, authRefresh: false, dataGenerator: generator);

    await _setApiData(url, result['access_token'], result['refresh_token']);
  }

  Future<void> unregister() async {
    await _request('v2/unregister', 'POST', _accessGenerator, authRefresh: true);

    await _setApiData('', '', '');
  }

  Future<dynamic> get(
    String apiMethod,
    {
      Map<String, dynamic>? queryParameters
    }
  ) async {
    return _request(
      apiMethod,
      'GET',
      _accessGenerator,
      queryParameters: queryParameters,
      authRefresh: true
    );
  }

  Future<dynamic> post(
    String apiMethod,
    {
      Map<String, dynamic>? queryParameters,
      Object? Function()? dataGenerator
    }
  ) async {
    return _request(
      apiMethod,
      'POST',
      _accessGenerator,
      queryParameters: queryParameters,
      dataGenerator: dataGenerator,
      authRefresh: true
    );
  }

  Future<dynamic> put(
    String apiMethod,
    {
      Map<String, dynamic>? queryParameters,
      Object? Function()? dataGenerator,
      bool authRefresh = true
    }
  ) async {
    return _request(
      apiMethod,
      'PUT',
      _accessGenerator,
      queryParameters: queryParameters,
      dataGenerator: dataGenerator,
      authRefresh: authRefresh
    );
  }

  Future<dynamic> _request(
    String apiMethod,
    String method,
    Map<String, String> Function() authGenerator,
    {
      Map<String, dynamic>? queryParameters,
      Object? Function()? dataGenerator,
      bool authRefresh = true
    }
  ) async {
    try {
      return await _rawRequest(apiMethod, method, authGenerator.call(), queryParameters, dataGenerator?.call());
    } on AuthException {
      if (!authRefresh) rethrow;

      await refresh();

      return await _rawRequest(apiMethod, method, authGenerator.call(), queryParameters, dataGenerator?.call());
    }
  }

  Future<dynamic> _rawRequest(
    String apiMethod,
    String method,
    Map<String, String> headers,
    Map<String, dynamic>? queryParameters,
    Object? data
  ) async {
    final dio = _createDio(_url);
    final options = Options(method: method, headers: headers);

    try {
      return (await dio.request(apiMethod, data: data, queryParameters: queryParameters, options: options)).data;
    } on DioException catch(e) {
      _onDioException(e);
    }
  }

  Dio _createDio(String url) {
    Map<String, dynamic> headers = {
      'Accept': 'application/json',
      _appName: _version,
      HttpHeaders.userAgentHeader: '$_appName/$_version ${FkUserAgent.userAgent}',
    };

    return Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(minutes: 1),
      sendTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 10),
      headers: headers,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));
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
