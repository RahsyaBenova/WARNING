import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/courses.dart';
import '../data/map_points.dart';
import '../game_state.dart';

/// 지도 화면: 정해진 루트, 지역(동그라미), 랜드마크(마름모), 지금 캐릭터 위치를 표시
class RouteMapView extends StatelessWidget {
  const RouteMapView({super.key, required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final course = game.course;
    final stops = _stopsFor(course);
    if (stops == null) {
      return const Center(
          child: Text('Map coming soon', style: TextStyle(color: Colors.grey)));
    }

    return Container(
      color: Colors.grey.shade100, // 지도 그림 자리 (나중에 실제 지도 이미지로 교체)
      child: TweenAnimationBuilder<double>(
        key: ValueKey(course.id),
        tween: Tween(end: game.traveledKm),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, km, _) => CustomPaint(
          size: Size.infinite,
          painter: _RoutePainter(
            course: course,
            stops: stops,
            km: km,
            landmarkIds: game.landmarkIds,
          ),
        ),
      ),
    );
  }
}

/// 루트 위의 점 (출발 도시 + 지역들)
class _Stop {
  const _Stop({required this.name, required this.km, required this.point});
  final String name;
  final double km;
  final (double, double) point; // (위도, 경도)
}

/// 코스의 출발 도시와 지역 위치를 모음. 위치 정보가 하나라도 없으면 null
List<_Stop>? _stopsFor(Course c) {
  final start = kMapPoints[c.id];
  if (start == null) return null;
  final stops = [_Stop(name: c.routeName.split(' → ').first, km: 0, point: start)];
  for (final r in c.regions) {
    final p = kMapPoints[r.id];
    if (p == null) return null;
    stops.add(_Stop(name: r.name, km: r.km, point: p));
  }
  return stops;
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.course,
    required this.stops,
    required this.km,
    required this.landmarkIds,
  });
  final Course course;
  final List<_Stop> stops;
  final double km;
  final Set<String> landmarkIds;

  @override
  void paint(Canvas canvas, Size size) {
    // 위도·경도를 화면 좌표로 (루트 전체가 화면에 꽉 차게)
    const pad = 44.0;
    final xs = stops.map((s) => s.point.$2);
    final ys = stops.map((s) => -s.point.$1);
    final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
    final dx = math.max(maxX - minX, 0.01), dy = math.max(maxY - minY, 0.01);
    final scale = math.min((size.width - pad * 2) / dx, (size.height - pad * 2) / dy);
    final ox = (size.width - dx * scale) / 2, oy = (size.height - dy * scale) / 2;
    Offset toScreen((double, double) p) =>
        Offset(ox + (p.$2 - minX) * scale, oy + (-p.$1 - minY) * scale);
    final pts = [for (final s in stops) toScreen(s.point)];

    // 루트 위 거리 k의 화면 위치 (지역 사이를 거리 비율로 나눔)
    Offset posAt(double k) {
      for (var i = 0; i < stops.length - 1; i++) {
        if (k <= stops[i + 1].km) {
          final span = stops[i + 1].km - stops[i].km;
          final t = span <= 0 ? 0.0 : ((k - stops[i].km) / span).clamp(0.0, 1.0);
          return Offset.lerp(pts[i], pts[i + 1], t)!;
        }
      }
      return pts.last;
    }

    final dark = Colors.grey.shade800;
    Paint line(Color c) => Paint()
      ..color = c
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 전체 루트 (연한 선) + 지나온 길 (진한 선)
    canvas.drawPath(Path()..addPolygon(pts, false), line(Colors.grey.shade400));
    final done = <Offset>[pts.first];
    for (var i = 1; i < stops.length && stops[i].km <= km; i++) {
      done.add(pts[i]);
    }
    done.add(posAt(km));
    canvas.drawPath(Path()..addPolygon(done, false), line(dark));

    final outline = Paint()
      ..color = dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 랜드마크: 마름모 (획득하면 칠해짐)
    for (final l in course.landmarks) {
      final p = posAt(l.km);
      final diamond = Path()
        ..moveTo(p.dx, p.dy - 7)
        ..lineTo(p.dx + 7, p.dy)
        ..lineTo(p.dx, p.dy + 7)
        ..lineTo(p.dx - 7, p.dy)
        ..close();
      canvas.drawPath(diamond, Paint()..color = landmarkIds.contains(l.id) ? dark : Colors.white);
      canvas.drawPath(diamond, outline);
    }

    // 지역: 동그라미 (지나왔으면 칠해짐) + 이름
    for (var i = 0; i < stops.length; i++) {
      final p = pts[i];
      canvas.drawCircle(p, 6, Paint()..color = stops[i].km <= km ? dark : Colors.white);
      canvas.drawCircle(p, 6, outline);
      final tp = TextPainter(
        text: TextSpan(text: stops[i].name, style: TextStyle(fontSize: 11, color: dark)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p + const Offset(10, -7));
    }

    // 캐릭터 위치
    final c = posAt(km);
    canvas.drawCircle(c, 11, Paint()..color = Colors.white);
    canvas.drawCircle(c, 11, Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawCircle(c, 4, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => true;
}