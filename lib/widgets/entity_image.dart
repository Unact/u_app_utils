part of u_app_utils;

class EntityImage extends StatelessWidget {
  final String imageUrl;
  final String imagePath;
  final bool local;
  final Color color;
  final void Function()? onTap;

  EntityImage({
    Key? key,
    required this.imageUrl,
    required this.imagePath,
    required this.local,
    this.color = Colors.blue,
    this.onTap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!local) return RetryableImage(imageUrl: imageUrl, color: color, onTap: onTap);

    return FutureBuilder(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(width: 0, height: 0);

        final file = File(p.join(snapshot.data!.path, imagePath));

        if (!file.existsSync()) return const SizedBox(width: 0, height: 0);

        return GestureDetector(
          onTap: onTap,
          child: Image.file(
            file,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: color)
          ),
        );
      }
    );
  }
}
