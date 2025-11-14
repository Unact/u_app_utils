import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Future<bool> hasBluetoothPermission() async {
    if (Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
      ].request();

      return statuses.values.every((element) => element.isGranted);
    }

    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan
      ].request();

      return statuses.values.every((element) => element.isGranted);
    }

    return false;
  }

  static Future<bool> hasCameraPermissions() async {
    return (await Permission.camera.request()).isGranted;
  }

  static Future<bool> hasPhotosPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt <= 32) {
        return (await Permission.storage.request()).isGranted;
      }
    }

    final request = await Permission.photos.request();

    return request.isGranted || request.isLimited;
  }

  static Future<bool> hasLocationPermissions() async {
    return (await Permission.location.request()).isGranted;
  }
}
