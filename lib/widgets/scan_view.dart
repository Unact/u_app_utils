part of u_app_utils;

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
    Key? key
  }) : super(key: key);

  @override
  ScanViewState createState() => ScanViewState();
}

class ScanViewState extends State<ScanView> {
  final GlobalKey _qrKey = GlobalKey();
  QRViewController? _controller;
  StreamSubscription? _subscription;
  bool _hasCamera = false;
  _ScanMode _scanMode = _ScanMode.scanner;
  bool _paused = false;
  bool _editingFinished = false;
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
    if (await Vibration.hasVibrator() ?? false) Vibration.vibrate();
  }

  @override
  void initState() {
    super.initState();

    _initScanMode();
  }

  Future<void> _initScanMode() async {
    _hasCamera = (await camera.availableCameras()).isNotEmpty;

    setState(() {});
  }

  @override
  void reassemble() {
    super.reassemble();

    if (_controller == null) return;

    if (Platform.isAndroid) {
      _controller!.pauseCamera();
    }

    _controller!.resumeCamera();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showScanner) return _buildCameraView(context);

    return _scanMode == _ScanMode.camera ? _buildCameraView(context) : _buildScannerView(context);
  }

  String? translateChar(RawKeyEvent rawKeyEvent) {
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
    return RawKeyboardListener(
      autofocus: false,
      focusNode: FocusNode(),
      onKey: (RawKeyEvent rawKeyEvent) async {
        if (rawKeyEvent is! RawKeyUpEvent) {
          _textEditingController.text = _textEditingController.text + (translateChar(rawKeyEvent) ?? '');
        }

        if (!_finishKeys.contains(rawKeyEvent.physicalKey)) return;

        _editingFinished = true;
        _onEditingFinished();
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
            onPressed: () async {
              try { _controller!.toggleFlash(); } on CameraException catch(_) {}
            }
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.switch_camera),
            onPressed: () async {
              try { _controller!.flipCamera(); } on CameraException catch(_) {}
            }
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
        children: [
          Center(
            child: QRView(
              key: _qrKey,
              formatsAllowed: const [
                BarcodeFormat.qrcode,
                BarcodeFormat.code128,
                BarcodeFormat.ean13,
                BarcodeFormat.dataMatrix
              ],
              overlay: QrScannerOverlayShape(
                borderColor: Colors.white,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutWidth: widget.barcodeMode ? 300 : 200,
                cutOutHeight: widget.barcodeMode ? 150 : 200
              ),
              onPermissionSet: (QRViewController controller, bool permission) {
                DateTime? lastScan;

                // https://github.com/juliuscanute/qr_code_scanner/issues/560
                _controller!.resumeCamera();

                _subscription = _controller!.scannedDataStream.listen((scanData) async {
                  final currentScan = DateTime.now();

                  if (_paused) return;

                  if (lastScan == null || currentScan.difference(lastScan!) > const Duration(seconds: 2)) {
                    lastScan = currentScan;

                    setState(() => _paused = true);
                    _beep();
                    _vibrate();
                    widget.onRead(scanData.code ?? '');
                    setState(() => _paused = false);
                  }
                });
              },
              onQRViewCreated: (QRViewController controller) {
                _controller = controller;
              },
            )
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
    required TextEditingController controller,
    required void Function(String) onChanged
  }) : super(
    key: key,
    autofocus: true,
    showCursor: false,
    onChanged: onChanged,
    controller: controller,
    focusNode: _BarcodeScannerFieldFocusNode(),
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

class _BarcodeScannerFieldFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() {
    return false;
  }
}
