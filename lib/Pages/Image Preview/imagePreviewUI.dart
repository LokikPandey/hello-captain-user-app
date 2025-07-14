import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

class ImagePreviewUI extends StatelessWidget {
  final String imgUrl;
  final XFile? fileImage;
  const ImagePreviewUI({super.key, required this.imgUrl, this.fileImage});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: imgUrl,
      child:
          fileImage != null
              ? PhotoView(
                minScale: .1,
                imageProvider: FileImage(File(fileImage!.path)),
              )
              : PhotoView(minScale: .1, imageProvider: NetworkImage(imgUrl)),
    );
  }
}
