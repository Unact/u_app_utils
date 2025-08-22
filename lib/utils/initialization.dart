import 'dart:async';
import 'dart:io';

import 'package:flutter_datawedge/flutter_datawedge.dart';
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

  static Future<void> initializeDataWedge({required String appName, bool audioFeedback = false }) async {
    if (!Platform.isAndroid) return;

    FlutterDataWedge dw = FlutterDataWedge();

    await dw.initialize();
    await dw.createDefaultProfile(profileName: appName);
    await dw.updateProfile(
      profileName: appName,
      pluginName: 'BARCODE',
      config: {
        'scanner_selection': 'auto',
        'decoder_i2of5': true,
        'decoder_qrcode': true,
        'decoder_code128': true,
        'decoder_ean8': true,
        'decoder_ean13': true,
        'decoder_datamatrix': true,
        'decoder_gs1_datamatrix': true,
        'decode_audio_feedback_uri': audioFeedback ? 'decode-short' : ''
      }
    );
  }
}
