import 'package:flutter/material.dart';
import '../game_state.dart';
import 'road_view.dart';
import 'route_map_view.dart';

/// 메인 화면의 여행 영역. 오른쪽 위 버튼으로 길 화면 ↔ 지도 화면을 바꿈
class TravelView extends StatefulWidget {
  const TravelView({super.key, required this.game});
  final GameState game;

  @override
  State<TravelView> createState() => _TravelViewState();
}

class _TravelViewState extends State<TravelView> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _showMap ? RouteMapView(game: widget.game) : RoadView(game: widget.game),
          Positioned(
            top: 8,
            right: 8,
            child: FilledButton.tonalIcon(
              onPressed: () => setState(() => _showMap = !_showMap),
              icon: Icon(_showMap ? Icons.directions_walk : Icons.map_outlined, size: 18),
              label: Text(_showMap ? 'Road' : 'Map'),
            ),
          ),
        ],
      ),
    );
  }
}