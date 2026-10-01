import 'package:flutter/material.dart';
import '../data/outfits.dart';
import '../game_state.dart';

/// 옷장 화면 (Profile 탭에서 들어옴). 위쪽은 지금 입은 옷 미리보기, 아래는 의상 목록
class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key, required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wardrobe')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            final owned = kOutfits.where(game.ownsOutfit).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 캐릭터 전신 미리보기 (와이어프레임). 화면 높이의 절반 크기
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const Placeholder(),
                ),
                const SizedBox(height: 12),
                Text(game.outfit.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(game.outfit.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 24),

                Text('Outfits $owned / ${kOutfits.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Complete a country to receive its traditional outfit.',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                  children: [
                    for (final o in kOutfits) _OutfitTile(game: game, outfit: o),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 의상 한 칸: 가진 옷은 눌러서 입기, 없는 옷은 획득 방법 안내
class _OutfitTile extends StatelessWidget {
  const _OutfitTile({required this.game, required this.outfit});
  final GameState game;
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    final owned = game.ownsOutfit(outfit);
    final wearing = game.currentOutfitId == outfit.id;
    final caption = wearing
        ? 'Wearing'
        : owned
            ? 'Tap to wear'
            : outfit.unlockHint;

    return InkWell(
      onTap: owned ? () => game.equipOutfit(outfit) : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: wearing ? Colors.grey.shade800 : Colors.grey,
            width: wearing ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: owned
                  ? const Placeholder()
                  : const Center(child: Icon(Icons.lock_outline, color: Colors.grey)),
            ),
            const SizedBox(height: 4),
            Text(owned ? outfit.name : '???',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            Text(caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}