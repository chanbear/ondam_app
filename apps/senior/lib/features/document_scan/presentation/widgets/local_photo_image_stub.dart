import 'package:flutter/widgets.dart';

/// Web: `path` is already a `blob:` URL (from `XFile.path`) that
/// `Image.network` loads directly — no filesystem access involved.
Widget buildLocalPhotoImage(
  String path, {
  required double width,
  required double height,
  required BoxFit fit,
}) {
  return Image.network(path, width: width, height: height, fit: fit);
}
