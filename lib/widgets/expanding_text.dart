import 'package:flutter/material.dart';

class ExpandingText extends StatefulWidget {
  final String content;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? limit;

  ExpandingText(this.content, {
    super.key,
    this.style,
    this.textAlign = TextAlign.right,
    this.limit = 40
  });

  @override
  ExpandingTextState createState() => ExpandingTextState();
}

class ExpandingTextState extends State<ExpandingText> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: RichText(
        textAlign: widget.textAlign,
        text: TextSpan(
          children: [
            TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 13).merge(widget.style),
              text: widget.limit != null && widget.content.length > widget.limit! && !_showAll ?
                widget.content.substring(0, widget.limit) :
                widget.content
            ),
            widget.limit == null || widget.content.length <= widget.limit! ? const TextSpan() : WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAll = true;
                  });
                },
                child: Text(
                  _showAll ? '' : '...',
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            )
          ]
        )
      )
    );
  }
}
