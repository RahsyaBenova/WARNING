/// 여행 경로 위의 지역(거점)과 그 지역의 특산물 컬렉션.
/// 기획 담당은 이 파일만 수정해서 지역과 특산물을 추가·변경할 수 있습니다.
class Region {
  final String id; // 저장용 고유 ID (영문)
  final String name; // 지역 이름
  final String item; // 획득하는 특산물 컬렉션
  final double km; // 출발점(서울)에서의 가상 거리

  const Region({
    required this.id,
    required this.name,
    required this.item,
    required this.km,
  });
}

/// 첫 번째 코스: 서울 → 부산
const List<Region> kRoute = [
  Region(id: 'suwon', name: 'Suwon', item: 'Suwon Galbi', km: 35),
  Region(id: 'cheonan', name: 'Cheonan', item: 'Walnut Cakes', km: 85),
  Region(id: 'gongju', name: 'Gongju', item: 'Gongju Chestnuts', km: 120),
  Region(id: 'yeongdong', name: 'Yeongdong', item: 'Yeongdong Grapes', km: 200),
  Region(id: 'gimcheon', name: 'Gimcheon', item: 'Gimcheon Plums', km: 240),
  Region(id: 'daegu', name: 'Daegu', item: 'Daegu Apples', km: 300),
  Region(id: 'cheongdo', name: 'Cheongdo', item: 'Cheongdo Persimmons', km: 330),
  Region(id: 'busan', name: 'Busan', item: 'Busan Fish Cakes', km: 420),
];

const String kRouteName = 'Seoul → Busan';
const double kRouteTotalKm = 420;