/// 추천 친구 (프로토타입용 예시 데이터).
/// 나중에 서버가 생기면 실제 유저 데이터로 바뀔 자리입니다.
class Friend {
  final String name;
  final Map<String, int> completed; // 완주한 나라 ID → 완주 횟수
  final double collectionPct; // 콜렉션 완료 비율 (0.0 ~ 1.0)
  final String courseId; // 지금 여행 중인 나라
  final double km; // 그 나라 코스에서 지금까지 온 거리

  const Friend({
    required this.name,
    required this.completed,
    required this.collectionPct,
    required this.courseId,
    required this.km,
  });
}

/// 팝업을 열 때 이 중에서 무작위로 kFriendSuggestions명을 보여줌
const int kFriendSuggestions = 4;

const List<Friend> kFriendPool = [
  Friend(name: 'Mina', completed: {'korea': 2, 'japan': 1}, collectionPct: 0.64, courseId: 'thailand', km: 312),
  Friend(name: 'Arif', completed: {'korea': 1, 'indonesia': 1}, collectionPct: 0.48, courseId: 'thailand', km: 95),
  Friend(name: 'Ploy', completed: {'korea': 1}, collectionPct: 0.31, courseId: 'indonesia', km: 410),
  Friend(name: 'Kenji', completed: {'korea': 3, 'indonesia': 1, 'thailand': 1}, collectionPct: 0.82, courseId: 'japan', km: 260),
  Friend(name: 'Sofia', completed: {}, collectionPct: 0.12, courseId: 'korea', km: 140),
  Friend(name: 'Daniel', completed: {'korea': 1}, collectionPct: 0.27, courseId: 'korea', km: 88),
  Friend(name: 'Haruka', completed: {'korea': 1, 'japan': 2}, collectionPct: 0.57, courseId: 'indonesia', km: 175),
  Friend(name: 'Budi', completed: {}, collectionPct: 0.08, courseId: 'korea', km: 310),
  Friend(name: 'Nok', completed: {'korea': 1, 'thailand': 1}, collectionPct: 0.45, courseId: 'japan', km: 40),
  Friend(name: 'Jisoo', completed: {'korea': 4}, collectionPct: 0.36, courseId: 'korea', km: 395),
];