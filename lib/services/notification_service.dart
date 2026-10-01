import 'dart:async';
import 'package:flutter/material.dart';
import '../data/landmarks.dart';

/// 폰 알림 서비스.
/// 지금은 Chrome에서도 테스트할 수 있도록 화면 위에 "떠 있는" 가짜 알림 카드를 띄웁니다.
/// 게임 화면 위에 겹쳐서 표시되므로 화면 배치를 밀어내지 않습니다.
/// 폰 연결 후 실제 알림(flutter_local_notifications)을 붙일 때
/// 이 파일의 _show 안쪽만 바꾸면 됩니다.
class NotificationService {
  /// 앱 어디서든 알림 카드를 띄우기 위한 열쇠. main.dart의 MaterialApp에 연결되어 있음
  static final navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _current;
  static Timer? _timer;

  /// 랜드마크 근처에 들어섰을 때
  static void landmarkNearby(Landmark l) {
    _show(
      title: '${l.name} is nearby!',
      body: 'Open the app before you walk past it to collect a special item.',
    );
  }

  static void _show({required String title, required String body}) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _hide();
    _current = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 8,
        left: 12,
        right: 12,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _hide, // 누르면 닫힘
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notification (test)',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(body, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_current!);
    // 실제 폰 알림처럼 잠시 뒤 자동으로 사라짐
    _timer = Timer(const Duration(seconds: 4), _hide);
  }

  static void _hide() {
    _timer?.cancel();
    _current?.remove();
    _current = null;
  }
}