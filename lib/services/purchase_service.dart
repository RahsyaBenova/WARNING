import 'package:flutter/material.dart';

/// 인앱 결제 서비스.
/// 지금은 Chrome에서도 테스트할 수 있도록 가짜 결제 창을 보여줍니다.
/// 폰 연결 후 실제 결제(RevenueCat 등)를 붙일 때 이 파일의 buy 안쪽만 바꾸면 됩니다.
class PurchaseService {
  /// 결제에 성공하면 true
  static Future<bool> buy(BuildContext context,
      {required String title, required String price}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purchase (test)'),
        content: Text('$title\n$price'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buy')),
        ],
      ),
    );
    return result ?? false;
  }
}