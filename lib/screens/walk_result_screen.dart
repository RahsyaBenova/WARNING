import 'package:flutter/material.dart';
import '../game_state.dart';
import '../services/ad_service.dart';
import 'arrival_flow.dart';
import '../widgets/walk_record_card.dart';

/// END를 누르면 나오는 산책 결과 화면.
/// 걸은 거리, 줄인 탄소, 칼로리, 이번 산책에서 얻은 컬렉션을 보여줌
class WalkResultScreen extends StatelessWidget {
  const WalkResultScreen({super.key, required this.game});
  final GameState game;

  Future<void> _watchAdForDouble(BuildContext context) async {
    final watched = await AdService.showRewarded(context);
    if (!watched || !context.mounted) return;
    final reached = game.applyDoubleBonus();
    await showArrivalFlow(context, game, reached);
  }

  @override
  Widget build(BuildContext context) {
    const bigButton = Size.fromHeight(56);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            final course = game.course;
            final progress = (game.traveledKm / course.totalKm).clamp(0.0, 1.0);
            final newItems = [
              for (final r in game.sessionRegions) r.item,
              for (final l in game.sessionLandmarks) l.name,
              for (final o in game.sessionOutfits) o.name,
            ];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        const Text('Walk complete!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        // 캐릭터 일러스트 자리 (와이어프레임)
                        const SizedBox(height: 140, child: Placeholder()),
                        const SizedBox(height: 16),

                        // 걸은 거리(크게) + 줄인 탄소 · 칼로리
                        WalkRecordCard(steps: game.sessionSteps),
                        const SizedBox(height: 20),

                        // 가상 여행 진행
                        Text('Journey: +${game.sessionVirtualKm.toStringAsFixed(1)} km '
                            'on ${course.routeName}'
                            '${game.bonusClaimed ? ' (2x)' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 20),

                        // 이번 산책에서 얻은 컬렉션
                        const Text('New this walk',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (newItems.isEmpty)
                          const Text('Nothing new this time. Keep walking!',
                              style: TextStyle(color: Colors.grey))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [for (final name in newItems) Chip(label: Text(name))],
                          ),
                        const SizedBox(height: 20),

                        Text('Total CO₂ saved so far: '
                            '${game.totalCo2Kg.toStringAsFixed(2)} kg',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2배 보너스는 결과 화면에서만 제안
                  if (game.canDoubleSession) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: bigButton),
                      onPressed: () => _watchAdForDouble(context),
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(
                          'Watch an ad to double this journey (ads left: ${game.adsLeftToday})'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: bigButton),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}