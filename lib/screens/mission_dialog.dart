import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/missions.dart';
import '../game_state.dart';
import '../services/ad_service.dart';
import '../services/verification_service.dart';
import 'ar_scene.dart';

/// 카메라 버튼을 누르면 뜨는 오늘의 사진 미션 팝업
Future<void> showMissionDialog(BuildContext context, GameState game) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Today's photo mission"),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: game,
            builder: (ctx, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    'Find it on your walk and snap a photo to add it to your collection.',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                for (final m in game.todayMissions) _MissionTile(game: game, mission: m),
                const SizedBox(height: 4),
                _BonusMissionArea(game: game),
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

/// 오늘 미션을 다 끝낸 뒤 보여주는 영역: 광고로 추가 미션 받기 또는 안내 문구
class _BonusMissionArea extends StatelessWidget {
  const _BonusMissionArea({required this.game});
  final GameState game;

  Future<void> _watchAd(BuildContext context) async {
    final watched = await AdService.showRewarded(context);
    if (watched) game.addBonusMission();
  }

  @override
  Widget build(BuildContext context) {
    const grey = TextStyle(fontSize: 12, color: Colors.grey);
    final allDone = game.todayMissions.every(game.isMissionDone);

    if (!allDone) return const SizedBox.shrink(); // 아직 할 미션이 있으면 표시 안 함
    if (!game.hasNewMissions) {
      return const Text("You've found everything! More missions coming soon.",
          textAlign: TextAlign.center, style: grey);
    }
    if (game.canAddBonusMission) {
      return OutlinedButton.icon(
        onPressed: () => _watchAd(context),
        icon: const Icon(Icons.play_circle_outline),
        label: Text('Watch an ad for another mission (${game.bonusMissionsLeft} left)'),
      );
    }
    return const Text("That's all for today. A new mission arrives tomorrow!",
        textAlign: TextAlign.center, style: grey);
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.game, required this.mission});
  final GameState game;
  final Mission mission;

  /// 사진 찍기 → 유저가 직접 확인 → 도감에 저장. "Retake"를 누르면 다시 찍기
  /// (나중에 AI 판정을 붙일 때는 이 함수에서 확인 창 대신 AI 결과를 보여주면 됨)
  Future<void> _snap(BuildContext context) async {
    if (!context.mounted) return;
    while (true) {
      if (!context.mounted) return;
      final navigator = Navigator.of(context);
      final bytes = await navigator.push<Uint8List>(
        MaterialPageRoute(builder: (_) => const ARScene()),
      );
      if (bytes == null || !context.mounted) return;

      // Try verification first if configured
      final ver = await VerificationService.verifyMission(bytes, mission.id);
      if (ver['success'] == true && ver['match'] == true) {
        game.completeMission(mission, bytes);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mission verified: ${ver['message']}')),
        );
        return;
      }

      // Otherwise fall back to manual confirm, showing verification message if present
      if (!context.mounted) return;
      final collect = await _showManualConfirm(context, bytes, verificationMessage: ver['message']?.toString());
      if (collect == true) {
        game.completeMission(mission, bytes);
        return;
      }
      if (collect != false) return;
    }
  }

  /// 찍은 사진이 미션과 맞는지 유저가 직접 확인하는 창
  Future<bool?> _showManualConfirm(BuildContext context, Uint8List bytes, {String? verificationMessage}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mission.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 240, height: 240, child: Image.memory(bytes, fit: BoxFit.cover)),
            if (verificationMessage != null) ...[
              const SizedBox(height: 8),
              Text('AI verification: $verificationMessage', style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ],
            const SizedBox(height: 8),
            const Text('Does your photo match the mission?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retake')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Collect')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = game.missionPhotos[mission.id];
    final done = photo != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: done
                ? Image.memory(photo, fit: BoxFit.cover)
                : const Center(child: Icon(Icons.photo_camera_outlined, color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(done ? 'Found!' : mission.hint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          done
              ? const Icon(Icons.check_circle)
              : OutlinedButton(onPressed: () => _snap(context), child: const Text('Snap')),
        ],
      ),
    );
  }
}