part of u_app_utils;

class NumTextField extends StatefulWidget {
  final TextEditingController? controller;
  final TextStyle? style;
  final bool decimal;
  final bool? enabled;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final InputDecoration? decoration;
  final void Function()? onTap;

  NumTextField({
    Key? key,
    this.controller,
    this.decimal = true,
    this.style,
    this.enabled,
    this.textAlign = TextAlign.end,
    this.textAlignVertical,
    this.decoration,
    this.onTap
  }) : super(key: key);

  @override
  State<NumTextField> createState() => _NumTextFieldState();
}

class _NumTextFieldState extends State<NumTextField> {
  final FocusNode sumNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return KeyboardActions(
      disableScroll: true,
      config: KeyboardActionsConfig(
        nextFocus: false,
        defaultDoneWidget: const Text(
          'Готово',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
        ),
        actions: [
          KeyboardActionsItem(
            focusNode: sumNode,
            onTapAction: () => sumNode.unfocus()
          )
        ]
      ),
      child: TextFormField(
        textAlign: widget.textAlign,
        textAlignVertical: widget.textAlignVertical,
        focusNode: sumNode,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
        controller: widget.controller,
        enabled: widget.enabled,
        maxLines: 1,
        style: widget.style,
        decoration: widget.decoration,
        onEditingComplete: () => sumNode.unfocus(),
        onChanged: (_) => widget.onTap?.call()
      )
    );
  }
}
