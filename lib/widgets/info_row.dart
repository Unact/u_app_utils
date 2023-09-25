part of u_app_utils;

class InfoRow extends StatelessWidget {
  final EdgeInsets padding;
  final Widget title;
  final Widget? trailing;
  final int titleFlex;
  final int trailingFlex;

  InfoRow({
    Key? key,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    required this.title,
    this.trailing,
    this.titleFlex = 1,
    this.trailingFlex = 1
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Row(
        children: [
          Flexible(
            flex: titleFlex,
            child: SizedBox(
              height: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(child: title)
              )
            ),
          ),
          Flexible(
            flex: trailingFlex,
            child: SizedBox(
              height: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: SingleChildScrollView(child: trailing)
              )
            )
          )
        ]
      ),
    );
  }
}
