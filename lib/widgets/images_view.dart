import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImagesView extends StatefulWidget {
  final List<Widget> images;
  final int idx;
  final FutureOr<void> Function(int idx)? onDelete;

  ImagesView({
    required this.images,
    this.idx = 0,
    this.onDelete,
    super.key
  });

  @override
  ImagesViewState createState() => ImagesViewState();
}

class ImagesViewState extends State<ImagesView> {
  late int _curIdx = widget.idx;
  late final _pageController = PageController(initialPage: _curIdx);

  @override
  void initState() {
    super.initState();

    if (widget.images.isEmpty) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(widget.images.isEmpty ? '' : '${_curIdx + 1} из ${widget.images.length}'),
        actions: widget.onDelete == null ?
          [] :
          [
            IconButton(
              onPressed: () async {
                await widget.onDelete!(_curIdx);
                widget.images.removeAt(_curIdx);

                if (widget.images.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
                  return;
                }

                setState(() { _curIdx = _curIdx > 0 ? _curIdx - 1 : 0; });
              },
              icon: const Icon(Icons.delete),
              tooltip: 'Удалить фотографию',
            )
          ]
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragEnd: (details) => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: PhotoViewGallery.builder(
            pageController: _pageController,
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions.customChild(
                initialScale: 0.8,
                child: widget.images[_curIdx]
              );
            },
            onPageChanged: (idx) => setState(() { _curIdx = idx; }),
            itemCount: widget.images.length,
          ),
        ),
      )
    );
  }
}
