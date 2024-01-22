part of u_app_utils;

@immutable
class CachedImageProvider extends ImageProvider<CachedImageProvider> {
  const CachedImageProvider(
    this.cacheKey,
    this.cacheManager
  );

  final BaseCacheManager cacheManager;

  final String cacheKey;

  @override
  Future<CachedImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<CachedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(CachedImageProvider key, ImageDecoderCallback decode) {
    return MultiImageStreamCompleter(
      codec: _loadImageAsync(decode),
      scale: 1,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );
  }

  Stream<Codec> _loadImageAsync(ImageDecoderCallback decode) {
    return _load(
      cacheKey,
      (bytes) async {
        final buffer = await ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      },
      cacheManager
    );
  }

  Stream<Codec> _load(
    String cacheKey,
    Future<Codec> Function(Uint8List) decode,
    BaseCacheManager cacheManager,
  ) async* {
    final result = await cacheManager.getFileFromCache(cacheKey);

    if (result is FileInfo) {
      final file = result.file;
      final bytes = await file.readAsBytes();
      final decoded = await decode(bytes);
      yield decoded;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is CachedImageProvider) {
      return (cacheKey == other.cacheKey);
    }
    return false;
  }

  @override
  int get hashCode => cacheKey.hashCode;

  @override
  String toString() => 'CachedImageProvider("$cacheKey")';
}
