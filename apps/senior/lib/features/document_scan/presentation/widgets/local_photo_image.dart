// `dart:io`'s `File` isn't valid on web — conditional export picks the
// `Image.file` implementation where `dart:io` exists, and an
// `Image.network` (blob: URL) implementation where it doesn't.
export 'local_photo_image_stub.dart'
    if (dart.library.io) 'local_photo_image_io.dart';
