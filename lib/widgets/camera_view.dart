part of u_app_utils;

class CameraView extends StatefulWidget {
  final Function(String) onError;
  final Function(XFile) onTakePicture;

  CameraView({
    required this.onError,
    required this.onTakePicture,
    Key? key,
  }) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  List<camera.CameraDescription> _cameras = [];
  camera.CameraController? _controller;
  bool _flashOn = false;
  camera.CameraDescription? _backCamera;
  camera.CameraDescription? _frontCamera;

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  Future<void> _initCameras() async {
    _cameras = await camera.availableCameras();

    if (_cameras.isEmpty) {
      widget.onError('Нет доступных камер');

      Navigator.of(context).pop();
      return;
    }

    final backCameras = _cameras.where((el) => el.lensDirection == camera.CameraLensDirection.back);
    final frontCameras = _cameras.where((el) => el.lensDirection == camera.CameraLensDirection.front);

    _backCamera = backCameras.isNotEmpty ? backCameras.first : null;
    _frontCamera = frontCameras.isNotEmpty ? frontCameras.first : null;

    await _setDefaultCamera();
  }

  Future<void> _setDefaultCamera() async {
    _setCamera(_backCamera ?? _cameras[0]);
  }

  Future<void> _setCamera(camera.CameraDescription cam) async {
    _controller = camera.CameraController(cam, camera.ResolutionPreset.max, enableAudio: false);

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(camera.FlashMode.off);

      if (!mounted) return;
      setState(() {});
    } on CameraException catch(e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          widget.onError('Не разрешена работа с камерой');
          break;
        default:
          widget.onError('Произошла ошибка: ${e.code} - ${e.description ?? ''}');
          break;
      }
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(_controller?.value.isInitialized ?? false)) {
      return Container();
    }

    double scale = MediaQuery.of(context).size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flash_on),
            onPressed: () async {
              if (_flashOn) {
                _controller!.setFlashMode(camera.FlashMode.off);
                _flashOn = false;
              } else {
                _controller!.setFlashMode(camera.FlashMode.torch);
                _flashOn = true;
              }
            }
          ),
          _frontCamera == null ? null : IconButton(
            color: Colors.white,
            icon: const Icon(Icons.switch_camera),
            onPressed: () async {
              if (_frontCamera != null && _controller!.description != _frontCamera) {
                _setCamera(_frontCamera!);
                return;
              }

              if (_backCamera != null && _controller!.description != _backCamera) {
                _setCamera(_backCamera!);
                return;
              }
            }
          )
        ].whereType<Widget>().toList()
      ),
      body: Transform.scale(scale: scale, child: Center(child: camera.CameraPreview(_controller!))),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        onPressed: () async {
          if (!(_controller?.value.isInitialized ?? false)) return;

          try {
            widget.onTakePicture(await _controller!.takePicture());
            Navigator.of(context).pop();
          } on CameraException catch (e) {
            widget.onError('Произошла ошибка: ${e.code} - ${e.description ?? ''}');
          }
        },
        child: const Icon(Icons.camera_alt,),
      ),
    );
  }
}
