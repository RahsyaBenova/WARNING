import 'package:flutter/material.dart';
import '../data/courses.dart';
import '../game_state.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';

/// 지구본 버튼을 누르면 뜨는 국가 선택 · 해금 팝업
Future<void> showWorldDialog(BuildContext context, GameState game) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Travel the world'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: game,
            builder: (ctx, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in kCourses) _CourseTile(game: game, course: c),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.game, required this.course});
  final GameState game;
  final Course course;

  Future<void> _buy(BuildContext context) async {
    final paid = await PurchaseService.buy(context,
        title: 'Unlock ${course.country}', price: course.price);
    if (paid) game.unlockByPurchase(course);
  }

  Future<void> _watchAd(BuildContext context) async {
    final watched = await AdService.showRewarded(context);
    if (watched) game.addUnlockAd(course);
  }

  void _select(BuildContext context) {
    if (game.selectCourse(course)) Navigator.pop(context);
  }

  /// 코스 상태에 따라 아래쪽에 보여줄 버튼들
  List<Widget> _actions(BuildContext context) {
    final isCurrent = game.currentCourseId == course.id;

    if (course.comingSoon) {
      return [const Text('Coming soon', style: TextStyle(color: Colors.grey))];
    }
    if (isCurrent) {
      return [
        Text('You are here  ${game.kmFor(course).toStringAsFixed(0)} / '
            '${course.totalKm.toStringAsFixed(0)} km'),
      ];
    }
    if (game.isUnlocked(course)) {
      return [
        OutlinedButton(
          onPressed: game.isWalking ? null : () => _select(context),
          child: Text(game.isWalking ? 'End your walk to switch' : 'Travel here'),
        ),
      ];
    }
    return [
      FilledButton(
        onPressed: () => _buy(context),
        child: Text('Unlock for ${course.price}'),
      ),
      const SizedBox(height: 6),
      OutlinedButton.icon(
        onPressed: () => _watchAd(context),
        icon: const Icon(Icons.play_circle_outline),
        label: Text('Watch ads  ${game.unlockAdsWatched(course)} / $kUnlockAdsRequired'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = game.currentCourseId == course.id;
    final locked = !game.isUnlocked(course);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700, width: isCurrent ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(course.country,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (locked && !course.comingSoon)
                const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
            ],
          ),
          Text(course.routeName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          ..._actions(context),
        ],
      ),
    );
  }
}