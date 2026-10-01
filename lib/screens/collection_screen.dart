import 'package:flutter/material.dart';
import '../data/courses.dart';
import '../data/landmarks.dart';
import '../data/outfits.dart';
import '../data/missions.dart';
import '../game_state.dart';
import '../services/ad_service.dart';

/// 도감 탭: 나라별로 지역 특산물과 랜드마크 스페셜을 나눠서 보여줌
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, required this.game});
  final GameState game;

  /// 놓친 랜드마크를 눌렀을 때: 광고를 보고 되찾기
  Future<void> _recover(BuildContext context, Course c, Landmark l) async {
    final messenger = ScaffoldMessenger.of(context);
    if (game.adsLeftToday <= 0) {
      messenger.showSnackBar(
          const SnackBar(content: Text("You've used all of today's ads")));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Recover ${l.name}'),
        content: Text('Watch an ad to collect this missed special item.\n'
            'Ads left today: ${game.adsLeftToday}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Watch ad')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final watched = await AdService.showRewarded(context);
    if (watched && game.recoverLandmark(c, l)) {
      messenger.showSnackBar(SnackBar(content: Text('Collected ${l.name}!')));
    }
  }

  /// 전통 의상 도감 구역 (갈아입기는 메인 탭의 옷걸이 버튼에서)
  List<Widget> _outfitSection() {
    final owned = kOutfits.where(game.ownsOutfit).length;
    return [
      Text('Outfits $owned / ${kOutfits.length}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _TileGrid(children: [
        for (final o in kOutfits)
          if (game.ownsOutfit(o))
            _CollectionTile(
              title: o.name,
              caption: game.currentOutfitId == o.id ? 'Wearing' : 'Owned',
              state: TileState.owned,
            )
          else
            _CollectionTile(title: '???', caption: o.unlockHint, state: TileState.locked),
      ]),
      const SizedBox(height: 32),
    ];
  }

  /// 사진 미션 도감에서 획득한 칸을 눌렀을 때: 공식 이미지 + 내가 찍은 사진
  void _showMissionPhoto(BuildContext context, Mission m) {
    final photo = game.missionPhotos[m.id];
    if (photo == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 우리가 정한 콜렉션 이미지 자리 (와이어프레임)
            const SizedBox(width: 220, height: 150, child: Placeholder()),
            const SizedBox(height: 12),
            const Text('Your photo', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            SizedBox(width: 220, height: 220, child: Image.memory(photo, fit: BoxFit.cover)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  /// 사진 미션 도감 구역. 도감 그림은 우리가 정한 이미지,
  /// 유저가 찍은 사진은 칸을 누르면 볼 수 있음
  List<Widget> _missionSection(BuildContext context) {
    final found = kMissions.where(game.isMissionDone).length;
    final today = game.todayMissions;
    return [
      Text('Photo missions $found / ${kMissions.length}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _TileGrid(children: [
        for (final m in kMissions)
          if (game.isMissionDone(m))
            _CollectionTile(
              title: m.title,
              caption: 'Found! Tap to see your photo',
              state: TileState.owned,
              onTap: () => _showMissionPhoto(context, m),
            )
          else
            _CollectionTile(
              title: m.title,
              caption: today.contains(m) ? "Today's mission" : 'Not today',
              state: TileState.locked,
            ),
      ]),
      const SizedBox(height: 32),
    ];
  }

  /// 나라 하나의 도감 구역
  List<Widget> _courseSection(BuildContext context, Course c) {
    final header = Text(c.country,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));

    if (!game.isUnlocked(c)) {
      return [
        header,
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 24),
          child: Text('Locked. Unlock it from the globe on the Walk tab.',
              style: TextStyle(color: Colors.grey)),
        ),
      ];
    }

    final regionOwned = c.regions.where((r) => game.collectedIds.contains(r.id)).length;
    final landmarkOwned = c.landmarks.where((l) => game.landmarkIds.contains(l.id)).length;

    return [
      header,
      const SizedBox(height: 12),
      _sectionTitle('Local specialties $regionOwned / ${c.regions.length}'),
      _TileGrid(children: [
        for (final r in c.regions)
          if (game.collectedIds.contains(r.id))
            _CollectionTile(title: r.item, caption: r.name, state: TileState.owned)
          else
            _CollectionTile(title: '???', caption: r.name, state: TileState.locked),
      ]),
      const SizedBox(height: 24),
      _sectionTitle('Landmark specials $landmarkOwned / ${c.landmarks.length}'),
      _TileGrid(children: [
        for (final l in c.landmarks)
          if (game.landmarkIds.contains(l.id))
            _CollectionTile(title: l.name, caption: 'Special', state: TileState.owned)
          else if (game.isLandmarkMissed(c, l))
            _CollectionTile(
              title: l.name,
              caption: 'Missed (tap to recover)',
              state: TileState.missed,
              onTap: () => _recover(context, c, l),
            )
          else
            _CollectionTile(
                title: '???',
                caption: 'At ${l.km.toStringAsFixed(0)} km',
                state: TileState.locked),
      ]),
      const SizedBox(height: 32),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: game,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._outfitSection(),
              ..._missionSection(context),
              for (final c in kCourses)
                if (!c.comingSoon) ..._courseSection(context, c),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
}

enum TileState { owned, locked, missed }

/// 3열 격자. 바깥 ListView가 스크롤을 담당
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.75,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

/// 도감 한 칸: 획득(이미지 자리), 미획득(자물쇠), 놓침(광고로 되찾기)
class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.title,
    required this.caption,
    required this.state,
    this.onTap,
  });
  final String title;
  final String caption;
  final TileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
        child: Column(
          children: [
            Expanded(
              child: switch (state) {
                TileState.owned => const Placeholder(),
                TileState.locked =>
                  const Center(child: Icon(Icons.lock_outline, color: Colors.grey)),
                TileState.missed =>
                  const Center(child: Icon(Icons.play_circle_outline, color: Colors.grey)),
              },
            ),
            const SizedBox(height: 6),
            Text(title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 12)),
            Text(caption,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}