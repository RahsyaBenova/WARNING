import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game_state.dart';

/// 화면에 보이는 앞쪽 거리 (가상 km). 이 거리 안의 특산물·랜드마크가 길가에 보임
const double _viewKm = 20;

/// 지평선 위치 (화면 위에서부터 높이 비율)
const double _horizon = 0.38;

/// 앞쪽 거리 d → 원근 비율 (바로 앞이면 1, 멀수록 0에 가까워짐)
double _depthScale(double d) => 1 / (1 + d / 2.5);

/// 2.5D 길 화면: 배경 → 길 → 길가 물건 → 캐릭터 뒷모습 순서로 겹쳐 그림.
/// 걸어서 거리가 늘면 길 무늬와 길가 물건이 앞으로 다가옴
class RoadView extends StatefulWidget {
  const RoadView({super.key, required this.game});
  final GameState game;

  @override
  State<RoadView> createState() => _RoadViewState();
}

class _RoadViewState extends State<RoadView> with TickerProviderStateMixin {
  // 산책 중 캐릭터가 통통 튀는 움직임
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  // 길가 물건이 둥실둥실 떠 있는 움직임 (항상)
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  GameState get game => widget.game;

  @override
  void initState() {
    super.initState();
    game.addListener(_syncBob);
    _syncBob();
  }

  void _syncBob() {
    if (game.isWalking) {
      if (!_bob.isAnimating) _bob.repeat(reverse: true);
    } else if (_bob.isAnimating || _bob.value != 0) {
      _bob.stop();
      _bob.value = 0;
    }
  }

  @override
  void dispose() {
    game.removeListener(_syncBob);
    _bob.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => TweenAnimationBuilder<double>(
        // 거리가 바뀌면 1.2초 동안 부드럽게 전진
        key: ValueKey(game.course.id),
        tween: Tween(end: game.traveledKm),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, km, _) => _scene(box.maxWidth, box.maxHeight, km),
      ),
    );
  }

  Widget _scene(double w, double h, double km) {
    final course = game.course;
    final horizonY = h * _horizon;
    final unit = w / 360; // 화면 폭에 비례한 크기 단위

    // 앞쪽 _viewKm 안에 있는 특산물(왼쪽)과 랜드마크(오른쪽). 먼 것부터 그려야 가까운 게 위로 옴
    final items = <_RoadItem>[
      for (final r in course.regions)
        if (r.km - km > 0 && r.km - km <= _viewKm)
          _RoadItem(label: r.item, d: r.km - km, onLeft: true, size: 56),
      for (final l in course.landmarks)
        if (l.km - km > 0 && l.km - km <= _viewKm)
          _RoadItem(label: l.name, d: l.km - km, onLeft: false, size: 84),
    ]..sort((a, b) => b.d.compareTo(a.d));

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // 1. 배경 (지역마다 바뀔 그림 자리)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: horizonY,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Placeholder(color: Colors.grey.shade400),
              Center(child: _Label('Background: ${_placeName(km)}')),
            ],
          ),
        ),
        // 2. 땅과 길
        Positioned.fill(child: CustomPaint(painter: _RoadPainter(km: km))),
        // 3. 길가에 떠 있는 물건
        for (final it in items) _itemWidget(it, w, h, horizonY, unit),
        // 4. 캐릭터 뒷모습
        _character(w, unit),
      ],
    );
  }

  /// 지금 지나고 있는 곳 이름 (마지막으로 지난 지역, 없으면 출발 도시)
  String _placeName(double km) {
    final course = game.course;
    var name = course.routeName.split(' → ').first;
    for (final r in course.regions) {
      if (r.km <= km) name = r.name;
    }
    return name;
  }

  Widget _itemWidget(_RoadItem it, double w, double h, double horizonY, double unit) {
    final s = _depthScale(it.d);
    final y = horizonY + (h - horizonY) * s; // 길 위 그 거리의 화면 높이
    final halfRoad = w * (0.03 + 0.42 * s);
    final size = it.size * unit * s * 1.5;
    final cx = w / 2 + (it.onLeft ? -1 : 1) * (halfRoad + size * 0.7);
    final showLabel = s > 0.3; // 너무 멀면 이름은 숨김

    return Positioned(
      left: cx - size / 2,
      top: y - size - (showLabel ? 14 : 0),
      width: size,
      height: size + (showLabel ? 14 : 0),
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -size * 0.12 * _float.value),
          child: child,
        ),
        child: Column(
          children: [
            SizedBox(width: size, height: size, child: const Placeholder()),
            if (showLabel)
              SizedBox(
                height: 14,
                child: Text(it.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _character(double w, double unit) {
    final cw = 80 * unit;
    final ch = cw * 1.3;
    return Positioned(
      left: w / 2 - cw / 2,
      bottom: 8,
      width: cw,
      height: ch,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, -6 * _bob.value), child: child),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Theme.of(context).colorScheme.surface), // 길 무늬가 비치지 않게
            const Placeholder(),
            Align(alignment: Alignment.bottomCenter, child: _Label(game.outfit.name)),
          ],
        ),
      ),
    );
  }
}

class _RoadItem {
  const _RoadItem({required this.label, required this.d, required this.onLeft, required this.size});
  final String label;
  final double d; // 앞쪽 거리 (가상 km)
  final bool onLeft;
  final double size; // 바로 앞에 있을 때의 기준 크기
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: Theme.of(context).colorScheme.surface,
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}

/// 땅, 소실점으로 좁아지는 길, 앞으로 흘러오는 중앙 점선
class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.km});
  final double km;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final hy = h * _horizon;
    double y(double d) => hy + (h - hy) * _depthScale(d);
    double half(double d) => w * (0.03 + 0.42 * _depthScale(d));
    const far = 200.0; // 지평선 근처까지 길을 이어 그림

    // 땅
    canvas.drawRect(Rect.fromLTRB(0, hy, w, h), Paint()..color = Colors.grey.shade100);

    // 길
    final road = Path()
      ..moveTo(w / 2 - half(far), y(far))
      ..lineTo(w / 2 + half(far), y(far))
      ..lineTo(w / 2 + half(0), h)
      ..lineTo(w / 2 - half(0), h)
      ..close();
    canvas.drawPath(road, Paint()..color = Colors.grey.shade300);

    final edge = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w / 2 - half(far), y(far)), Offset(w / 2 - half(0), h), edge);
    canvas.drawLine(Offset(w / 2 + half(far), y(far)), Offset(w / 2 + half(0), h), edge);
    canvas.drawLine(Offset(0, hy), Offset(w, hy), edge);

    // 중앙 점선: 걸은 거리만큼 앞으로 밀려와서 걷는 느낌을 줌
    const spacing = 2.0, dashLen = 0.9;
    final dash = Paint()..color = Colors.grey.shade700;
    for (var d = -(km % spacing); d < _viewKm; d += spacing) {
      final d0 = math.max(d, 0.0);
      final d1 = d + dashLen;
      if (d1 <= 0) continue;
      dash.strokeWidth = 1 + 6 * _depthScale(d0);
      canvas.drawLine(Offset(w / 2, y(d0)), Offset(w / 2, y(d1)), dash);
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.km != km;
}