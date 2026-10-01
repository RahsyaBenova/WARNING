import 'dart:math';
import 'package:flutter/material.dart';
import '../data/courses.dart';
import '../data/friends.dart';
import '../game_state.dart';

/// 친구 버튼을 누르면 뜨는 추천 친구 팝업. 친구를 누르면 업적이 펼쳐짐
Future<void> showFriendsDialog(BuildContext context, GameState game) {
  return showDialog(
    context: context,
    builder: (_) => _FriendsDialog(game: game),
  );
}

class _FriendsDialog extends StatefulWidget {
  const _FriendsDialog({required this.game});
  final GameState game;

  @override
  State<_FriendsDialog> createState() => _FriendsDialogState();
}

class _FriendsDialogState extends State<_FriendsDialog> {
  late List<Friend> _friends = _pick();

  /// 친구 목록에서 무작위로 몇 명 고르기
  List<Friend> _pick() =>
      ([...kFriendPool]..shuffle(Random())).take(kFriendSuggestions).toList();

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final myPct =
        game.collectionTotal == 0 ? 0.0 : game.collectionOwned / game.collectionTotal;

    return AlertDialog(
      title: const Text('Suggested friends'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tap a friend to see how far they have traveled.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              for (final f in _friends) _FriendTile(friend: f, myPct: myPct),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => setState(() => _friends = _pick()),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Shuffle'),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

/// 친구 한 명: 접혀 있을 땐 요약, 펼치면 업적 (현재 위치, 완주한 나라, 콜렉션)
class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.myPct});
  final Friend friend;
  final double myPct;

  @override
  Widget build(BuildContext context) {
    final course = kCourses.firstWhere((c) => c.id == friend.courseId);
    final place = _placeName(course, friend.km);
    final pct = friend.collectionPct;
    final diff = ((pct - myPct) * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: ExpansionTile(
        shape: const Border(), // 펼쳤을 때 생기는 기본 테두리 제거
        leading: const SizedBox(width: 40, height: 40, child: Placeholder()), // 친구 캐릭터 자리
        title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${course.country} · ${(pct * 100).round()}% collected',
            style: const TextStyle(fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 위치
          _heading(Icons.place_outlined, 'Now traveling'),
          Text('${course.country}, near $place'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: (friend.km / course.totalKm).clamp(0.0, 1.0)),
          Text('${friend.km.toStringAsFixed(0)} / ${course.totalKm.toStringAsFixed(0)} km',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),

          // 완주한 나라와 횟수
          _heading(Icons.flag_outlined, 'Completed countries'),
          if (friend.completed.isEmpty)
            const Text('None yet', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in friend.completed.entries)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                        '${_countryName(e.key)}${e.value > 1 ? ' ×${e.value}' : ''}',
                        style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          const SizedBox(height: 12),

          // 콜렉션 완료 비율 + 나와 비교
          _heading(Icons.collections_bookmark_outlined, 'Collection'),
          LinearProgressIndicator(value: pct),
          const SizedBox(height: 4),
          Text(
            diff > 0
                ? '${(pct * 100).round()}% · $diff% ahead of you. Keep walking!'
                : diff < 0
                    ? "${(pct * 100).round()}% · You're ${-diff}% ahead!"
                    : "${(pct * 100).round()}% · You're neck and neck!",
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _heading(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  /// 마지막으로 지난 지역 (없으면 출발 도시)
  static String _placeName(Course c, double km) {
    var name = c.routeName.split(' → ').first;
    for (final r in c.regions) {
      if (r.km <= km) name = r.name;
    }
    return name;
  }

  static String _countryName(String courseId) {
    final match = kCourses.where((c) => c.id == courseId);
    return match.isEmpty ? courseId : match.first.country;
  }
}