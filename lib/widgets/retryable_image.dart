import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class RetryableImage extends StatefulWidget {
  final double? width;
  final double? height;
  final String imageUrl;
  final Color color;
  final void Function()? onTap;
  final bool cached;
  final String? cacheKey;
  final BaseCacheManager? cacheManager;

  RetryableImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.onTap,
    this.cached = false,
    this.color = Colors.blue,
    this.cacheKey,
    this.cacheManager,
  }) : super(key: key);

  @override
  RetryableImageState createState() => RetryableImageState();
}

class RetryableImageState extends State<RetryableImage> {
  final _rebuildNotifier = ValueNotifier('');

  @override
  Widget build(BuildContext context) {
    if (!widget.cached) return buildRemote(context);

    if (widget.cacheKey == null || widget.cacheManager == null) {
      return SizedBox(width: widget.width, height: widget.height, child: Icon(Icons.error, color: widget.color));
    }

    return buildCached(context);
  }

  Widget buildCached(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Image(
        image: _CachedImageProvider(widget.cacheKey!, widget.cacheManager!),
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: widget.color)
      ),
    );
  }

  Widget buildRemote(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _rebuildNotifier,
      builder: (context, value, child) => CachedNetworkImage(
        key: ValueKey(value),
        cacheManager: widget.cacheManager,
        cacheKey: widget.cacheKey,
        imageUrl: widget.imageUrl,
        imageBuilder: (context, imageProvider) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(image: DecorationImage(image: imageProvider))
            )
          );
        },
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(color: widget.color)
        ),
        errorWidget: (context, url, error) => IconButton(
          icon: Icon(Icons.refresh, color: widget.color),
          tooltip: 'Загрузить заново',
          onPressed: () {
            _rebuildNotifier.value = const Uuid().v1();
          }
        )
      )
    );
  }
}

@immutable
class _CachedImageProvider extends ImageProvider<_CachedImageProvider> {
  const _CachedImageProvider(
    this.cacheKey,
    this.cacheManager
  );

  final BaseCacheManager cacheManager;

  final String cacheKey;

  @override
  Future<_CachedImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<_CachedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(_CachedImageProvider key, ImageDecoderCallback decode) {
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
    if (other is _CachedImageProvider) {
      return (cacheKey == other.cacheKey);
    }
    return false;
  }

  @override
  int get hashCode => cacheKey.hashCode;

  @override
  String toString() => 'CachedImageProvider("$cacheKey")';
}
