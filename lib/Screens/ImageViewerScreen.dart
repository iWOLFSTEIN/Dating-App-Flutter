import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageViewerScreen extends StatefulWidget {
  ImageViewerScreen({
    Key key,
    this.imageUrl,
    // this.name
  }) : super(key: key);

  // final name;
  final imageUrl;

  @override
  _ImageViewerScreenState createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      appBar: AppBar(
        backgroundColor: Color(0xFF13293D),
        title: Text('Image Viewer'),
      ),
      body: Container(
        child: Center(
            child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          fit: BoxFit.contain,
        )),
      ),
    );
  }
}
