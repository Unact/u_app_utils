library u_app_utils;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart' as camera;
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:f_logs/f_logs.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundpool/soundpool.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';

part 'services/renew_api.dart';

part 'utils/extensions.dart';
part 'utils/format.dart';
part 'utils/initialization.dart';
part 'utils/misc.dart';
part 'utils/parsing.dart';
part 'utils/permissions.dart';

part 'widgets/camera_view.dart';
part 'widgets/entity_image.dart';
part 'widgets/expanding_text.dart';
part 'widgets/images_view.dart';
part 'widgets/info_row.dart';
part 'widgets/qr_dialog.dart';
part 'widgets/progress_dialog.dart';
part 'widgets/retryable_image.dart';
part 'widgets/scan_view.dart';
part 'widgets/sum_text_field.dart';
