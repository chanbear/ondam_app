import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/camera_flash_mode.dart';

void main() {
  group('CameraFlashMode.next', () {
    test('cycles off -> on -> auto -> off', () {
      expect(CameraFlashMode.off.next, CameraFlashMode.on);
      expect(CameraFlashMode.on.next, CameraFlashMode.auto);
      expect(CameraFlashMode.auto.next, CameraFlashMode.off);
    });
  });
}
