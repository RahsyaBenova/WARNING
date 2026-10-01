import 'courses.dart';

/// 캐릭터 의상. 나라 코스를 완주하면 그 나라의 전통 의상을 받습니다.
/// 유료 판매 없이, 걸어서만 모을 수 있는 컬렉션입니다.
class Outfit {
  final String id;
  final String name;
  final String description;
  final String? courseId; // 완주하면 받는 코스 (null이면 처음부터 가진 기본 의상)

  const Outfit({
    required this.id,
    required this.name,
    required this.description,
    this.courseId,
  });

  /// 아직 없는 의상에 보여줄 획득 방법 안내
  String get unlockHint {
    if (courseId == null) return 'Starter outfit';
    final course = kCourses.where((c) => c.id == courseId);
    return course.isEmpty ? 'Coming soon' : 'Complete ${course.first.country}';
  }
}

/// 첫 번째 의상이 기본 의상입니다. 새 나라를 추가하면 여기에 전통 의상도 추가하세요.
const List<Outfit> kOutfits = [
  Outfit(
    id: 'basic',
    name: 'Walking Gear',
    description: 'Your everyday walking outfit',
  ),
  Outfit(
    id: 'hanbok',
    name: 'Hanbok',
    description: 'Traditional Korean attire, earned by walking across Korea',
    courseId: 'korea',
  ),
  Outfit(
    id: 'batik',
    name: 'Batik',
    description: 'Traditional Indonesian attire, earned by walking across Indonesia',
    courseId: 'indonesia',
  ),
  Outfit(
    id: 'chut_thai',
    name: 'Chut Thai',
    description: 'Traditional Thai attire, earned by walking across Thailand',
    courseId: 'thailand',
  ),
  Outfit(
    id: 'kimono',
    name: 'Kimono',
    description: 'Traditional Japanese attire, earned by walking across Japan',
    courseId: 'japan',
  ),
];