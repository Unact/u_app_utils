import 'dart:async';

import 'package:f_logs/f_logs.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Initialization {
  static void intializeFlogs({
    required bool isDebug,
    bool enabled = true
  }) {
    LogsConfig config = LogsConfig();

    // В прод режими логируем все
    config.activeLogLevel = isDebug ? LogLevel.INFO : LogLevel.ALL;
    config.formatType = FormatType.FORMAT_SQUARE;
    config.timestampFormat = TimestampFormat.TIME_FORMAT_FULL_3;
    config.isLogsEnabled = enabled;

    FLog.applyConfigurations(config);
  }

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
        options.beforeSend = (SentryEvent event, {dynamic hint}) async {
          if (isDebug) return null;

          return event.copyWith(user: await userGenerator.call());
        };
      },
      appRunner: appRunner
    );
  }
}
