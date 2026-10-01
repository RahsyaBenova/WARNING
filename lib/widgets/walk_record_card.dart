import 'package:flutter/material.dart';
import '../game_state.dart';

/// 걷기 기록 박스: 걸은 거리(km)를 크게, 그 아래에 줄인 탄소와 칼로리.
/// Profile 탭(오늘·달력)과 산책 결과 화면이 함께 씁니다.
class WalkRecordCard extends StatelessWidget {
  const WalkRecordCard({super.key, required this.steps, this.emptyText = 'No walk recorded'});
  final int steps;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final km = steps * kStepLengthKm;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 걸은 거리 (가장 크게)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(km.toStringAsFixed(2),
                  style: const TextStyle(
                      fontSize: 56, fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(width: 6),
              const Text('km',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(steps == 0 ? emptyText : 'walked',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // 부가 정보
          Row(
            children: [
              _subStat(Icons.eco_outlined, (km * kCo2KgPerKm).toStringAsFixed(2), 'kg CO₂ saved'),
              Container(width: 1, height: 36, color: Colors.grey.shade300),
              _subStat(Icons.local_fire_department_outlined,
                  (steps * kKcalPerStep).toStringAsFixed(0), 'kcal burned'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subStat(IconData icon, String value, String label) => Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
}