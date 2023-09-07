part of u_app_utils;

class Misc {
  static Future<void> callPhone(phone, {Function? onError}) async {
    Uri uri = Uri.parse('tel://${phone.replaceAll(RegExp(r'\s|\(|\)|\-'), '')}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      onError?.call();
    }
  }

  static bool isDebug() {
    bool isDebug = false;
    assert(isDebug = true);

    return isDebug;
  }

  static Future<void> reportError(dynamic error, dynamic stackTrace) async {
    Frame methodFrame = Trace.current().frames.length > 1 ? Trace.current().frames[1] : Trace.current().frames[0];

    debugPrint(error.toString());
    debugPrint(stackTrace.toString());

    FLog.error(
      methodName: methodFrame.member!.split('.')[1],
      text: error.toString(),
      exception: error,
      stacktrace: stackTrace
    );

    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  static Map<String, String> stackFrame(int frame) {
    String? member = Trace.current().frames[frame + 1].member;

    if (member != null) {
      List<String> frameData = member.split('.');

      return {
        'className': frameData[0],
        'methodName': frameData[1],
      };
    }

    return {
      'className': '',
      'methodName': '',
    };
  }

  static void unfocus(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus) currentFocus.unfocus();
  }

  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> clearFiles(String folder, [Set<String> newRelFilePaths = const <String>{}]) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$folder';
    final pathDirectory = await Directory(path).create(recursive: true);
    final filePaths = (pathDirectory.listSync()).map((e) => e.path).toSet();
    final newFilePaths = newRelFilePaths.map((e) => p.join(directory.path, e)).toSet();

    for (var filePath in filePaths.difference(newFilePaths)) {
      await File(filePath).delete();
    }
  }

  static Future<void> launchAppUpdate({
    required String repoName,
    required String version,
    Function? onError
  }) async {
    String manifestRepoUrl = 'https://unact.github.io/mobile_apps/$repoName';
    String appRepoUrl = 'https://github.com/Unact/$repoName';
    String androidUpdateUrl = '$appRepoUrl/releases/download/$version/app-release.apk';
    String iosUpdateUrl = 'itms-services://?action=download-manifest&url=$manifestRepoUrl/manifest.plist';
    Uri uri = Uri.parse(Platform.isIOS ? iosUpdateUrl : androidUpdateUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      onError?.call();
    }
  }
}
