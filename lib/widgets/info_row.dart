part of u_app_utils;

class InfoRow extends StatelessWidget {
  final EdgeInsets padding;
  final Widget title;
  final Widget? trailing;
  final int titleFlex;
  final int trailingFlex;
  final Alignment titleAlignment;
  final Alignment trailingAlignment;

  InfoRow.page({
    required this.title,
    this.trailing,
    super.key
  }) :
    padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    titleFlex = 1,
    titleAlignment = Alignment.centerLeft,
    trailingFlex = 2,
    trailingAlignment = Alignment.centerLeft;

  InfoRow({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    required this.title,
    this.trailing,
    this.titleFlex = 1,
    this.trailingFlex = 1,
    this.titleAlignment = Alignment.centerLeft,
    this.trailingAlignment = Alignment.centerRight
  });

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
                alignment: titleAlignment,
                child: SingleChildScrollView(child: title)
              )
            ),
          ),
          Flexible(
            flex: trailingFlex,
            child: SizedBox(
              height: 60,
              child: Align(
                alignment: trailingAlignment,
                child: SingleChildScrollView(child: trailing)
              )
            )
          )
        ]
      ),
    );
  }
}
