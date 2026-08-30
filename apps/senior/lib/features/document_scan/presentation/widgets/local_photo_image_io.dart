import 'dart:io';

import 'package:flutter/widgets.dart';

Widget buildLocalPhotoImage(
  String path, {
  required double width,
  required double height,
  required BoxFit fit,
}) {
  return Image.file(File(path), width: width, height: height, fit: fit);
}
