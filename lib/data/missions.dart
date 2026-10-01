/// 일상 속 사진 미션. 미션 대상을 찾아서 카메라로 찍으면 도감에 사진이 모입니다.
/// 매일 아직 못 찾은 미션 중 하나가 "오늘의 미션"으로 나오고,
/// 광고를 보면 하루 최대 kMaxBonusMissionsPerDay개까지 추가 미션을 받을 수 있습니다.
class Mission {
  final String id;
  final String title; // 미션 문구
  final String hint; // 찾는 데 도움이 되는 설명

  const Mission({required this.id, required this.title, required this.hint});
}

/// 하루에 무료로 나오는 미션 개수
const int kFreeMissionsPerDay = 1;

/// 광고를 보고 추가로 받을 수 있는 미션 개수 (하루 기준, 일반 광고 제한과 별도)
const int kMaxBonusMissionsPerDay = 3;

const List<Mission> kMissions = [
  Mission(id: 'red_flower', title: 'Find a red flower', hint: 'Roses, tulips, any red bloom'),
  Mission(id: 'yellow_leaf', title: 'Find a yellow leaf', hint: 'Look under the trees'),
  Mission(id: 'cat', title: 'Spot a cat', hint: 'Alleys and parks are good places'),
  Mission(id: 'bicycle', title: 'Find a parked bicycle', hint: 'Another way to travel green'),
  Mission(id: 'bench', title: 'Find a park bench', hint: 'A good spot to rest'),
  Mission(id: 'recycling_bin', title: 'Find a recycling bin', hint: 'Help keep the streets clean'),
  Mission(id: 'mural', title: 'Find a street mural', hint: 'Art painted on a wall'),
  Mission(id: 'big_tree', title: 'Find the biggest tree nearby', hint: 'Look up!'),
  Mission(id: 'cloud', title: 'Find a cloud with a funny shape', hint: 'What does it look like to you?'),
];