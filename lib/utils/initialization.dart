import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

class Initialization {
  static Future<void> initializeSentry({
    required FutureOr<void> Function() appRunner,
    required String dsn,
    required bool isDebug,
    required Future<SentryUser> Function() userGenerator
  }) async {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.attachScreenshot = true;
        options.beforeSend = (SentryEvent event, dynamic hint) async {
          if (isDebug) return null;

          return event.copyWith(user: await userGenerator.call());
        };
      },
      appRunner: appRunner
    );
  }
}
