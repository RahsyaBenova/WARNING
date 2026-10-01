import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A lightweight interactive mesh simulator.
/// Shows a movable white square (the "mesh") over a scene and returns
/// a PNG image of the composed view when the user presses Capture.
class InteractiveMeshDialog extends StatefulWidget {
  const InteractiveMeshDialog({super.key, required this.priceText});
  final String priceText;

  /// Shows the dialog and returns bytes for the captured image, or null on cancel.
  static Future<Uint8List?> show(BuildContext context, String priceText) {
    return showDialog<Uint8List>(
      context: context,
      builder: (ctx) => Dialog(child: SizedBox(width: 360, height: 520, child: InteractiveMeshDialog(priceText: priceText))),
    );
  }

  @override
  State<InteractiveMeshDialog> createState() => _InteractiveMeshDialogState();
}

class _InteractiveMeshDialogState extends State<InteractiveMeshDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  Offset _meshPos = const Offset(120, 160);

  void _move(Offset delta) => setState(() => _meshPos += delta);

  Future<void> _capture() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final img = await boundary.toImage(pixelRatio: pixelRatio);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = bd?.buffer.asUint8List();
    if (!mounted) return;
    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Background scene (simple grey grid)
                  Container(color: Colors.grey[300]),
                  Positioned(
                    left: 40,
                    top: 60,
                    child: Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.yellow[700], borderRadius: BorderRadius.circular(8)),
                      child: Text(widget.priceText, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  // The white mesh (movable)
                  Positioned(
                    left: _meshPos.dx,
                    top: _meshPos.dy,
                    child: GestureDetector(
                      onPanUpdate: (e) => _move(e.delta),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black54)),
                        child: const Center(child: Text('White Mesh')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => _move(const Offset(0, -10)), icon: const Icon(Icons.arrow_upward)),
                  IconButton(onPressed: () => _move(const Offset(-10, 0)), icon: const Icon(Icons.arrow_back)),
                  IconButton(onPressed: () => _move(const Offset(10, 0)), icon: const Icon(Icons.arrow_forward)),
                  IconButton(onPressed: () => _move(const Offset(0, 10)), icon: const Icon(Icons.arrow_downward)),
                  ElevatedButton(onPressed: _capture, child: const Text('Capture')),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
