/// 랜드마크 스페셜 컬렉션.
/// 캐릭터가 랜드마크 근처(앞뒤 kLandmarkRangeKm 이내)를 지나는 동안
/// 앱을 켜서 직접 눌러야 획득할 수 있습니다. 지나쳐버리면 놓칩니다.
class Landmark {
  final String id; // 저장용 고유 ID (영문)
  final String name; // 랜드마크 이름
  final double km; // 출발점(서울)에서의 가상 거리

  const Landmark({required this.id, required this.name, required this.km});
}

/// 랜드마크 앞뒤로 이 거리 안에 있을 때만 획득 가능
const double kLandmarkRangeKm = 5;

const List<Landmark> kLandmarks = [
  Landmark(id: 'hwaseong', name: 'Hwaseong Fortress', km: 40),
  Landmark(id: 'independence_hall', name: 'Independence Hall', km: 95),
  Landmark(id: 'hanbit_tower', name: 'Hanbit Tower', km: 160),
  Landmark(id: 'chupungnyeong', name: 'Chupungnyeong Pass', km: 225),
  Landmark(id: 'gwangan_bridge', name: 'Gwangan Bridge', km: 415),
];