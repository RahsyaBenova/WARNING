import 'dart:async';
import 'package:flutter/material.dart';

/// 보상형 광고 서비스.
/// 지금은 Chrome에서도 테스트할 수 있도록 가짜 광고(5초 카운트다운)를 보여줍니다.
/// 폰 연결 후 실제 AdMob을 붙일 때는 이 파일의 showRewarded 안쪽만 바꾸면 됩니다.
class AdService {
  /// 광고를 끝까지 보면 true, 건너뛰면 false
  static Future<bool> showRewarded(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FakeAdDialog(),
    );
    return result ?? false;
  }
}

class _FakeAdDialog extends StatefulWidget {
  const _FakeAdDialog();

  @override
  State<_FakeAdDialog> createState() => _FakeAdDialogState();
}

class _FakeAdDialogState extends State<_FakeAdDialog> {
  int remaining = 5;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining <= 1) t.cancel();
      setState(() => remaining--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = remaining <= 0;
    return AlertDialog(
      title: const Text('Ad (test)'),
      content: SizedBox(
        width: 280,
        height: 180,
        child: Column(
          children: [
            const Expanded(child: Placeholder()),
            const SizedBox(height: 8),
            Text(done ? 'Ad complete!' : 'Reward available in ${remaining}s'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: done ? () => Navigator.pop(context, true) : null,
          child: const Text('Claim reward'),
        ),
      ],
    );
  }
}