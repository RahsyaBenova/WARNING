import 'package:flutter/material.dart';
import '../data/regions.dart';
import '../data/outfits.dart';
import '../game_state.dart';
import 'world_dialog.dart';

/// 지역 도착 후 이어지는 팝업 흐름. 메인 화면과 산책 결과 화면이 함께 씁니다.
/// 도착 팝업 → (완주했으면) 전통 의상 보상 팝업 → 국가 선택 팝업
Future<void> showArrivalFlow(
    BuildContext context, GameState game, List<Region> reached) async {
  if (reached.isEmpty) return;
  await _showArrival(context, reached);
  final outfit = game.takeOutfitReward();
  if (outfit != null && context.mounted) {
    await _showOutfitReward(context, game, outfit);
  }
  if (game.isCourseComplete && context.mounted) {
    await showWorldDialog(context, game);
  }
}

Future<void> _showArrival(BuildContext context, List<Region> regions) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('New region reached!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in regions)
            ListTile(
              leading: const SizedBox(width: 48, height: 48, child: Placeholder()),
              title: Text(r.name),
              subtitle: Text('You got ${r.item}'),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ),
  );
}

Future<void> _showOutfitReward(BuildContext context, GameState game, Outfit o) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Course complete!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 120, height: 160, child: Placeholder()),
          const SizedBox(height: 12),
          Text('You received the ${o.name}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(o.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
        FilledButton(
          onPressed: () {
            game.equipOutfit(o);
            Navigator.pop(ctx);
          },
          child: const Text('Wear now'),
        ),
      ],
    ),
  );
}