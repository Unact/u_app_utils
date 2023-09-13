part of u_app_utils;

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
    return FutureBuilder(
      future: widget.cacheManager!.getFileFromCache(widget.cacheKey!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(width: 0, height: 0);

        return GestureDetector(
          onTap: widget.onTap,
          child: Image.file(
            snapshot.data!.file,
            width: widget.width,
            height: widget.height,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: widget.color)
          ),
        );
      }
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
