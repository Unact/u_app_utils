part of u_app_utils;

class EntityImage extends StatelessWidget {
  final String imageUrl;
  final String imagePath;
  final bool local;

  EntityImage({
    Key? key,
    required this.imageUrl,
    required this.imagePath,
    required this.local
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!local) return RetryableImage(imageUrl: imageUrl);

    return FutureBuilder(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(width: 0, height: 0);

        final file = File(p.join(snapshot.data!.path, imagePath));

        if (!file.existsSync()) return const SizedBox(width: 0, height: 0);

        return Image.file(file, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error));
      }
    );
  }
}
