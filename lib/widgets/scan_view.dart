import 'dart:async';

import 'package:camera/camera.dart' as camera;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:soundpool/soundpool.dart';
import 'package:vibration/vibration.dart';

enum _ScanMode {
  scanner,
  camera
}

class ScanView extends StatefulWidget {
  final Widget child;
  final bool showScanner;
  final bool barcodeMode;
  final Function(String) onRead;

  const ScanView({
    required this.child,
    this.showScanner = false,
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
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.itf,
      BarcodeFormat.dataMatrix
    ]
  );
  bool _hasCamera = false;
  _ScanMode _scanMode = _ScanMode.scanner;
  bool _paused = false;
  bool _editingFinished = false;
  final BarcodeScannerFieldFocusNode barcodeScannerFocusNode = BarcodeScannerFieldFocusNode();
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

    _initScanMode();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initScanMode() async {
    _hasCamera = (await camera.availableCameras()).isNotEmpty;

    setState(() {});
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

    if (_scanMode == _ScanMode.camera) return;

    switch (state) {
      case AppLifecycleState.detached:
        barcodeScannerFocusNode.unfocus();
      case AppLifecycleState.resumed:
        barcodeScannerFocusNode.requestFocus();
      case AppLifecycleState.inactive:
        barcodeScannerFocusNode.unfocus();
      case AppLifecycleState.hidden:
        barcodeScannerFocusNode.unfocus();
      case AppLifecycleState.paused:
        barcodeScannerFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showScanner) return _buildCameraView(context);

    return _scanMode == _ScanMode.camera ? _buildCameraView(context) : _buildScannerView(context);
  }

  String? translateChar(KeyEvent rawKeyEvent) {
    return _keyCodeMap[rawKeyEvent.physicalKey];
  }

  void _onEditingFinished() {
    if (!_editingFinished) return;
    if (_textEditingController.text == '') return;

    widget.onRead(_textEditingController.text);
    _editingFinished = false;
    _textEditingController.text = '';
  }

  Widget _buildScannerView(BuildContext context) {
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
        appBar: AppBar(
          backgroundColor: Colors.black,
          actions: <Widget?>[
            !_hasCamera ? null : IconButton(
              color: Colors.white,
              icon: const Icon(Icons.camera),
              onPressed: () {
                setState(() => _scanMode = _ScanMode.camera);
              }
            )
          ].whereType<Widget>().toList(),
        ),
        extendBodyBehindAppBar: false,
        body: Stack(
          children: [
            Center(
              child: _BarcodeScannerField(
                focusNode: barcodeScannerFocusNode,
                controller: _textEditingController,
                onChanged: (String changed) => _onEditingFinished()
              )
            ),
            Container(
              padding: const EdgeInsets.only(top: 32),
              color: const Color.fromRGBO(0, 0, 0, 0.5),
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

  Widget _buildCameraView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: <Widget?>[
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flash_on),
            onPressed: _controller.toggleTorch
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.switch_camera),
            onPressed: _controller.switchCamera
          ),
          !widget.showScanner ? null : IconButton(
            color: Colors.white,
            icon: const Icon(Icons.keyboard),
            onPressed: () {
              setState(() => _scanMode = _ScanMode.scanner);
            }
          )
        ].whereType<Widget>().toList()
      ),
      extendBodyBehindAppBar: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          Center(
            child: MobileScanner(
              key: _qrKey,
              controller: _controller,
              onDetect: (BarcodeCapture capture) {
                if (_paused) return;

                setState(() => _paused = true);
                _beep();
                _vibrate();
                widget.onRead(capture.barcodes.firstOrNull?.rawValue ?? '');
                setState(() => _paused = false);
              },
              errorBuilder: (context, error, child) {
                return Text(error.errorDetails?.message ?? 'ww');
              }
            ),
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

class _BarcodeScannerField extends EditableText {
  _BarcodeScannerField({
    Key? key,
    FocusNode? focusNode,
    required TextEditingController controller,
    required void Function(String) onChanged
  }) : super(
    key: key,
    autofocus: true,
    showCursor: false,
    onChanged: onChanged,
    controller: controller,
    focusNode: focusNode ?? BarcodeScannerFieldFocusNode(),
    style: const TextStyle(),
    cursorColor: Colors.transparent,
    backgroundCursorColor: Colors.transparent
  );

  @override
  _BarcodeScannerFieldState createState() => _BarcodeScannerFieldState();
}

class _BarcodeScannerFieldState extends EditableTextState {
  @override
  void initState() {
    widget.focusNode.addListener(funcionListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(funcionListener);
    super.dispose();
  }

  @override
  void requestKeyboard() {
    super.requestKeyboard();

    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void funcionListener() {
    if (widget.focusNode.hasFocus) requestKeyboard();
  }
}

class BarcodeScannerFieldFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() {
    return false;
  }
}
