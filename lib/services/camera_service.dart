import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// 카메라 서비스. 사진 미션에서 사진을 찍을 때 사용합니다.
/// 폰 브라우저와 앱에서는 카메라가 열리고,
/// PC의 Chrome에서는 카메라 대신 파일 선택 창이 열립니다 (테스트용 사진을 고르면 됨).
class CameraService {
  static final _picker = ImagePicker();

  /// 사진을 찍어 이미지 데이터로 돌려줌 (취소하면 null)
  static Future<Uint8List?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024, // 용량을 줄이기 위해 크기 제한
      imageQuality: 80,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}