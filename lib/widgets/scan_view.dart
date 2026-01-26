import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_datawedge/flutter_datawedge.dart' as dw;
import 'package:permission_handler/permission_handler.dart';

import '../utils/permissions.dart';

class ScanView extends StatefulWidget {
  final List<Widget> actions;
  final Widget child;
  final bool paused;
  final bool beep;
  final bool vibrate;
  final Function(String) onRead;
  final Function(String? errorMessage)? onError;

  const ScanView({
    required this.child,
    this.actions = const [],
    this.paused = false,
    this.beep = true,
    this.vibrate = true,
    required this.onRead,
    this.onError,
    super.key
  });

  @override
  ScanViewState createState() => ScanViewState();
}

class ScanViewState extends State<ScanView> {
  final player = AudioPlayer();
  static final String _kCryptoSeparator = '\u001D';
  static final String _kBTScannerPrefix = 'SR5600';
  final GlobalKey _qrKey = GlobalKey();
  final MobileScannerController _controller = MobileScannerController(
    cameraResolution: Size(1920, 1080),
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.itf,
      BarcodeFormat.dataMatrix
    ]
  );
  String lastScan = '';

  StreamSubscription? dataWedgeScanSubscription;
  StreamSubscription? mobileScannerScanSubscription;
  StreamSubscription? onBLEScanSubscription;
  StreamSubscription? onBLEStateSubscription;

  Future<void> _beep() async {
    await player.play(AssetSource('../packages/u_app_utils/assets/beep.mp3'));
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator()) await Vibration.vibrate();
  }

  @override
  void initState() {
    super.initState();

    setupMobileScanner();
    setupDataWedgeScanner();
    setupBLEScanner();
  }

  void setupMobileScanner() {
    mobileScannerScanSubscription = _controller.barcodes.listen((res) {
      Barcode? barcode = res.barcodes.firstOrNull;
      String currentScan = barcode?.rawValue ?? '';

      if (barcode == null || barcode.format == BarcodeFormat.unknown) return;

      if (barcode.rawValue == null) {
        currentScan = '';
      } else {
        if (barcode.format == BarcodeFormat.dataMatrix && barcode.rawValue![0] == _kCryptoSeparator) {
          currentScan = barcode.rawValue!.substring(1);
        }
      }

      scanCode(currentScan);
    });
  }

  void setupDataWedgeScanner() {
    if (!Platform.isAndroid) return;

    dataWedgeScanSubscription = dw.FlutterDataWedge().onScanResult.listen((res) => scanCode(res.data));
  }

  Future<void> setupBLEScanner() async {
    if (await FlutterBluePlus.isSupported == false) return;
    if (await Permission.location.serviceStatus.isDisabled) return;
    if (await Permissions.hasBluetoothPermission() == false || await Permissions.hasLocationPermissions() == false) {
      return;
    }

    onBLEStateSubscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) async {
      if (state != BluetoothAdapterState.on) return;

      BluetoothDevice? btScanner = FlutterBluePlus.connectedDevices
        .firstWhereOrNull((device) => device.platformName.contains(_kBTScannerPrefix));

      if (btScanner == null) {
        await FlutterBluePlus.startScan(withKeywords:[_kBTScannerPrefix], timeout: Duration(seconds: 2));
        await FlutterBluePlus.isScanning.where((val) => val == false).first;

        btScanner = (await FlutterBluePlus.scanResults.first)
          .firstWhereOrNull((res) => res.device.platformName.contains(_kBTScannerPrefix))?.device;

        if (btScanner == null) return;
      }

      try {
        if (!btScanner.isConnected) await btScanner.connect();

        final dataCharacteristic = (await btScanner.discoverServices())
          .firstWhereOrNull((service) => service.serviceUuid == Guid('fff0'))
          ?.characteristics
          .firstWhereOrNull((char) => char.characteristicUuid == Guid('fff1'));

        if (dataCharacteristic == null) return;

        await dataCharacteristic.setNotifyValue(true);

        onBLEScanSubscription = dataCharacteristic.onValueReceived.listen((value) {
          final data = String.fromCharCodes(value).replaceAll('\n\r', '');
          final code = data.substring(1);

          scanCode(code);
        });
      } on FlutterBluePlusException catch(e) {
        widget.onError?.call('${e.description ?? 'Unknown error'} - ${e.code}');
      }
    });
  }

  Future<void> scanCode(String scanData) async {
    if (widget.paused) return;
    if (scanData == lastScan) return;

    lastScan = scanData;

    if (widget.beep) _beep();
    if (widget.vibrate) _vibrate();
    widget.onRead(lastScan);
  }

  @override
  void dispose() {
    _controller.dispose();
    mobileScannerScanSubscription?.cancel();
    dataWedgeScanSubscription?.cancel();
    onBLEScanSubscription?.cancel();
    onBLEStateSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Rect scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(const Offset(0, -100)),
      width: 300,
      height: 150,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: widget.actions
      ),
      extendBodyBehindAppBar: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            key: _qrKey,
            controller: _controller,
            scanWindow: scanWindow,
            errorBuilder: (context, error) {
              return Text(error.errorDetails?.message ?? '');
            },
            placeholderBuilder: (context) {
              return Container(color: Colors.transparent);
            }
          ),
          ScanWindowOverlay(
            scanWindow: scanWindow,
            controller: _controller,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderWidth: 2
          ),
          Container(
            padding: const EdgeInsets.only(top: 32),
            child: Align(
              alignment: Alignment.topCenter,
              child: widget.child
            )
          )
        ]
      )
    );
  }
}
