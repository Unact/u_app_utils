part of u_app_utils;

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
    required String dsn,
    required bool isDebug,
    required Future<SentryUser> Function() userGenerator
  }) async {
    if (isDebug) return;

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.beforeSend = (SentryEvent event, {dynamic hint}) async {
          return event.copyWith(user: await userGenerator.call());
        };
      },
    );
  }
}
