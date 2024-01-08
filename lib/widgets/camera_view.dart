part of u_app_utils;

class CameraView extends StatefulWidget {
  final bool compress;
  final Function(String) onError;
  final Function(XFile) onTakePicture;

  const CameraView({
    this.compress = false,
    required this.onError,
    required this.onTakePicture,
    Key? key,
  }) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  static const int _kMaxFileSize = 1024 * 1024 * 2;

  List<camera.CameraDescription> _cameras = [];
  camera.CameraController? _controller;
  bool _flashOn = false;
  camera.CameraDescription? _backCamera;
  camera.CameraDescription? _frontCamera;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _controller = camera.CameraController(
        _controller!.description,
        camera.ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: camera.ImageFormatGroup.yuv420
      );
    }
  }

  @override
  void initState() {
    _initCameras();
    super.initState();
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

  Future<void> _setCamera(camera.CameraDescription cameraDescription) async {
    _controller = camera.CameraController(
      cameraDescription,
      camera.ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: camera.ImageFormatGroup.yuv420
    );

    try {
      await _controller!.initialize();

      if (!mounted) return;
      setState(() {});
    } on camera.CameraException catch(e) {
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
    final initialized = _controller?.value.isInitialized ?? false;
    double aspectRatio = initialized ? (_controller?.value.aspectRatio ?? 1) : 1;
    double scale = MediaQuery.of(context).size.aspectRatio * aspectRatio;
    if (scale < 1) scale = 1 / scale;

    Widget body = initialized ?
      Transform.scale(scale: scale, child: Center(child: camera.CameraPreview(_controller!))) :
      Container();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Вспышка',
            color: Colors.white,
            icon: const Icon(Icons.flash_on),
            onPressed:  () async {
              try {
                if (_flashOn) {
                  await _controller!.setFlashMode(camera.FlashMode.off);
                  _flashOn = false;
                } else {
                  await _controller!.setFlashMode(camera.FlashMode.torch);
                  _flashOn = true;
                }
              } on camera.CameraException catch(e) {
                switch (e.code) {
                  case 'setFlashModeFailed':
                    widget.onError('Вспышка не поддерживается');
                    break;
                  default:
                    widget.onError('Произошла ошибка: ${e.code} - ${e.description ?? ''}');
                    break;
                }
              }
            }
          ),
          _frontCamera == null ? null : IconButton(
            tooltip: 'Поменять камеру',
            color: Colors.white,
            icon: const Icon(Icons.switch_camera),
            onPressed: () async {
              if (_frontCamera != null && _controller!.description != _frontCamera) {
                await _setCamera(_frontCamera!);
                return;
              }

              if (_backCamera != null && _controller!.description != _backCamera) {
                await _setCamera(_backCamera!);
                return;
              }
            }
          )
        ].whereType<Widget>().toList()
      ),
      body: body,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        onPressed: () async {
          if (!(_controller?.value.isInitialized ?? false)) return;

          try {
            final picture = await _controller!.takePicture();
            final compressedPicture = widget.compress ? await compressFile(picture) : picture;

            if (compressedPicture != null) {
              widget.onTakePicture(compressedPicture);
            } else {
              widget.onError('Произошла ошибка: Не удалось сохранить фотографию');
            }

            Navigator.of(context).pop();
          } on camera.CameraException catch (e) {
            widget.onError('Произошла ошибка: ${e.code} - ${e.description ?? ''}');
          } on CompressError catch (e) {
            widget.onError('Произошла ошибка: ${e.message}');
          }
        },
        child: const Icon(Icons.camera_alt,),
      ),
    );
  }

  Future<XFile?> compressFile(XFile? file, [int quality = 100]) async {
    if (file == null || quality <= 10) return null;
    if (await file.length() <= _kMaxFileSize) return file;
    quality -= 10;

    return compressFile(await _compress(file, quality), quality);
  }

  Future<XFile?> _compress(XFile file, int quality) async {
    final directory = await getTemporaryDirectory();

    return await FlutterImageCompress.compressAndGetFile(
      file.path,
      "${directory.path}/$quality-${file.name}",
      quality: quality,
      numberOfRetries: 1
    );
  }
}
