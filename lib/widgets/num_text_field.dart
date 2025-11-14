import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class NumTextField extends StatefulWidget {
  final String? initialValue;
  final TextEditingController? controller;
  final TextStyle? style;
  final bool? enabled;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final InputDecoration? decoration;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputType? keyboardType;
  final int? maxLines;

  NumTextField({
    super.key,
    this.initialValue,
    this.controller,
    this.style,
    this.enabled,
    this.textAlign = TextAlign.end,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.textAlignVertical,
    this.decoration,
    this.inputFormatters,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLines
  });

  @override
  State<NumTextField> createState() => _NumTextFieldState();
}

class _NumTextFieldState extends State<NumTextField> {
  final FocusNode focusNode = FocusNode();
  late final TextEditingController controller = widget.controller ?? TextEditingController(text: widget.initialValue);

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
        actions: Platform.isAndroid ? [] : [
          KeyboardActionsItem(
            focusNode: focusNode,
            onTapAction: () {
              focusNode.unfocus();
              widget.onFieldSubmitted?.call(controller.text);
            }
          )
        ]
      ),
      child: TextFormField(
        textAlign: widget.textAlign,
        textAlignVertical: widget.textAlignVertical,
        focusNode: focusNode,
        keyboardType: widget.keyboardType,
        controller: controller,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        style: widget.style,
        decoration: widget.decoration,
        inputFormatters: widget.inputFormatters,
        onEditingComplete: () => focusNode.unfocus(),
        onFieldSubmitted: widget.onFieldSubmitted,
        onChanged: widget.onChanged
      )
    );
  }
}
