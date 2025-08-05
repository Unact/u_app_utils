import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:soundpool/soundpool.dart';
import 'package:vibration/vibration.dart';


class ScanView extends StatefulWidget {
  final List<Widget> actions;
  final Widget child;
  final bool barcodeMode;
  final bool paused;
  final Function(String) onRead;

  const ScanView({
    required this.child,
    this.actions = const [],
    this.paused = false,
    this.barcodeMode = false,
    required this.onRead,
    super.key
  });

  @override
  ScanViewState createState() => ScanViewState();
}

class ScanViewState extends State<ScanView> with WidgetsBindingObserver {
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
  bool _editingFinished = false;
  final FocusNode barcodeScannerFocusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  static final List<PhysicalKeyboardKey> _finishKeys = [
    PhysicalKeyboardKey.enter,
    PhysicalKeyboardKey.gameButtonLeft1
  ];
  static final Map<PhysicalKeyboardKey, String> _keyCodeMap = {
    PhysicalKeyboardKey.digit0: '0',
    PhysicalKeyboardKey.digit1: '1',
    PhysicalKeyboardKey.digit2: '2',
    PhysicalKeyboardKey.digit3: '3',
    PhysicalKeyboardKey.digit4: '4',
    PhysicalKeyboardKey.digit5: '5',
    PhysicalKeyboardKey.digit6: '6',
    PhysicalKeyboardKey.digit7: '7',
    PhysicalKeyboardKey.digit8: '8',
    PhysicalKeyboardKey.digit9: '9',
    PhysicalKeyboardKey.period: '.',
    PhysicalKeyboardKey.semicolon: ':',
    PhysicalKeyboardKey.minus: '-',
    PhysicalKeyboardKey.space: ' ',
    PhysicalKeyboardKey.keyA: 'A',
    PhysicalKeyboardKey.keyB: 'B',
    PhysicalKeyboardKey.keyC: 'C',
    PhysicalKeyboardKey.keyD: 'D',
    PhysicalKeyboardKey.keyE: 'E',
    PhysicalKeyboardKey.keyF: 'F',
    PhysicalKeyboardKey.keyG: 'G',
    PhysicalKeyboardKey.keyH: 'H',
    PhysicalKeyboardKey.keyI: 'I',
    PhysicalKeyboardKey.keyJ: 'J',
    PhysicalKeyboardKey.keyK: 'K',
    PhysicalKeyboardKey.keyL: 'L',
    PhysicalKeyboardKey.keyM: 'M',
    PhysicalKeyboardKey.keyN: 'N',
    PhysicalKeyboardKey.keyO: 'O',
    PhysicalKeyboardKey.keyP: 'P',
    PhysicalKeyboardKey.keyQ: 'Q',
    PhysicalKeyboardKey.keyR: 'R',
    PhysicalKeyboardKey.keyS: 'S',
    PhysicalKeyboardKey.keyT: 'T',
    PhysicalKeyboardKey.keyU: 'U',
    PhysicalKeyboardKey.keyV: 'V',
    PhysicalKeyboardKey.keyW: 'W',
    PhysicalKeyboardKey.keyX: 'X',
    PhysicalKeyboardKey.keyY: 'Y',
    PhysicalKeyboardKey.keyZ: 'Z'
  };

  static final Soundpool _kPool = Soundpool.fromOptions(options: const SoundpoolOptions());
  static final Future<int> _kBeepId = rootBundle
    .load('packages/u_app_utils/assets/beep.mp3')
    .then((soundData) => _kPool.load(soundData));

  static Future<void> _beep() async {
    await _kPool.play(await _kBeepId);
  }

  static Future<void> _vibrate() async {
    if (await Vibration.hasVibrator()) Vibration.vibrate();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        barcodeScannerFocusNode.unfocus();
        return;
      case AppLifecycleState.resumed:
        unawaited(_controller.start());
        barcodeScannerFocusNode.requestFocus();
      case AppLifecycleState.inactive:
        unawaited(_controller.stop());
    }
  }

  String? translateChar(KeyEvent rawKeyEvent) {
    return _keyCodeMap[rawKeyEvent.physicalKey];
  }

  void _onEditingFinished() {
    if (widget.paused) return;
    if (!_editingFinished) return;
    if (_textEditingController.text == '') return;

    widget.onRead(_textEditingController.text);
    _editingFinished = false;
    _textEditingController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.barcodeMode ? 300 : 200;
    final double height = widget.barcodeMode ? 150 : 200;
    final Rect scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(const Offset(0, -100)),
      width: width,
      height: height,
    );

    return Focus(
      autofocus: false,
      onKeyEvent: (FocusNode focusNode, KeyEvent rawKeyEvent) {
        if (rawKeyEvent is! KeyUpEvent) {
          _textEditingController.text = _textEditingController.text + (translateChar(rawKeyEvent) ?? '');
        }

        if (!_finishKeys.contains(rawKeyEvent.physicalKey)) return KeyEventResult.handled;

        _editingFinished = true;
        _onEditingFinished();

        return KeyEventResult.handled;
      },
      child: Scaffold(
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
            Center(
              child: TextField(
                keyboardType: TextInputType.none,
                focusNode: barcodeScannerFocusNode,
                controller: _textEditingController,
                decoration: InputDecoration(border: InputBorder.none),
                onChanged: (String changed) => _onEditingFinished(),
                autofocus: true,
                showCursor: false,
                cursorColor: Colors.transparent
              )
            ),
            MobileScanner(
              key: _qrKey,
              controller: _controller,
              scanWindow: scanWindow,
              onDetect: (BarcodeCapture capture) {
                Barcode? barcode = capture.barcodes.firstOrNull;
                String currentScan = barcode?.rawValue ?? '';

                if (widget.paused) return;
                if (barcode == null || barcode.format == BarcodeFormat.unknown) return;
                if (currentScan == lastScan) return;

                lastScan = currentScan;

                _beep();
                _vibrate();
                widget.onRead(lastScan);
              },
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
      )
    );
  }
}
