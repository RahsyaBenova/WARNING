import 'package:flutter/material.dart';
import '../data/landmarks.dart';
import '../game_state.dart';
import 'arrival_flow.dart';
import 'walk_result_screen.dart';
import 'world_dialog.dart';
import 'mission_dialog.dart';
import 'friends_dialog.dart';
import '../widgets/travel_view.dart';
import 'ar_scene.dart';

/// 메인 탭: 여행 진행 상황, 랜드마크 카드, START / END, 의상 · 국가 버튼
class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.game});
  final GameState game;

  Future<void> _walk(BuildContext context, int steps) async {
    final reached = game.addSteps(steps);
    await showArrivalFlow(context, game, reached);
  }

  /// END: 세션을 끝내고, 걸은 게 있으면 산책 결과 화면으로 이동
  void _endWalk(BuildContext context) {
    game.endSession();
    if (game.sessionSteps == 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WalkResultScreen(game: game)),
    );
  }

  void _collectLandmark(BuildContext context, Landmark l) {
    if (!game.collectLandmark(l)) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Special item collected!'),
        content: ListTile(
          leading: const SizedBox(width: 48, height: 48, child: Placeholder()),
          title: Text(l.name),
          subtitle: const Text('Landmark special'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bigButton = Size.fromHeight(56);

    return SafeArea(
      child: ListenableBuilder(
        listenable: game,
        builder: (context, _) {
          final course = game.course;
          final next = game.nextRegion;
          final landmark = game.nearbyLandmark;
          final progress = (game.traveledKm / course.totalKm).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(course.country,
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(course.routeName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // 추천 친구 팝업 버튼
                    IconButton.outlined(
                      onPressed: () => showFriendsDialog(context, game),
                      icon: const Icon(Icons.group_outlined),
                      tooltip: 'Friends',
                    ),
                    const SizedBox(width: 8),
                    // 사진 미션 팝업 버튼
                    IconButton.outlined(
                      onPressed: () => showMissionDialog(context, game),
                      icon: const Icon(Icons.photo_camera),
                      tooltip: 'Photo missions',
                    ),
                    const SizedBox(width: 8),
                    // AR character button
                    IconButton.outlined(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ARScene())),
                      icon: const Icon(Icons.view_in_ar),
                      tooltip: 'AR Character (Joystick)',
                    ),
                    const SizedBox(width: 8),
                    // 국가 선택 · 해금 팝업 버튼
                    IconButton.outlined(
                      onPressed: () => showWorldDialog(context, game),
                      icon: const Icon(Icons.public),
                      tooltip: 'Travel the world',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 여행 화면: 2.5D 길 ↔ 루트 지도 (오른쪽 위 버튼으로 전환)
                Expanded(child: TravelView(game: game)),

                // 랜드마크 근처를 지날 때만 나타나는 카드
                if (landmark != null) ...[
                  const SizedBox(height: 12),
                  _LandmarkCard(
                    landmark: landmark,
                    onTap: () => _collectLandmark(context, landmark),
                  ),
                ],
                const SizedBox(height: 16),

                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text('Traveled ${game.traveledKm.toStringAsFixed(1)} / '
                    '${course.totalKm.toStringAsFixed(0)} km'),
                Text(next == null
                    ? 'Course complete! Tap the globe to travel abroad'
                    : '${(next.km - game.traveledKm).toStringAsFixed(1)} km '
                        'to ${next.name}'),
                if (game.isWalking)
                  Text('This walk: ${game.sessionRealKm.toStringAsFixed(2)} km'),
                const SizedBox(height: 16),

                if (game.isWalking) ...[
                  // 실제 걸음 수 연동 전까지 쓰는 테스트 버튼
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: bigButton),
                    onPressed: () => _walk(context, 1000),
                    child: const Text('+0.7 km (test)'), // 1,000걸음 = 약 0.7km
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: bigButton),
                    onPressed: () => _endWalk(context),
                    child: const Text('END'),
                  ),
                ] else ...[
                  // 완주한 나라를 처음부터 다시 여행하는 버튼
                  if (game.isCourseComplete) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: bigButton),
                      onPressed: () => game.restartCourse(),
                      icon: const Icon(Icons.replay),
                      label: Text('Travel ${course.country} again'),
                    ),
                    const SizedBox(height: 4),
                    const Text('Souvenirs stay yours. Missed landmarks get a second chance!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: bigButton),
                    onPressed: game.startSession,
                    child: const Text('START'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "Passing near OO" 카드. 누르면 스페셜 컬렉션 획득
class _LandmarkCard extends StatelessWidget {
  const _LandmarkCard({required this.landmark, required this.onTap});
  final Landmark landmark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade700, width: 2),
        ),
        child: Row(
          children: [
            const SizedBox(width: 56, height: 56, child: Placeholder()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Passing near ${landmark.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('Tap before you pass it to collect a special item',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.touch_app),
          ],
        ),
      ),
    );
  }
}