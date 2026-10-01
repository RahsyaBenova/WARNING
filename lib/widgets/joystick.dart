import 'package:flutter/material.dart';

/// A very small on-screen joystick widget.
/// Emits normalized offset in range [-1,1] for both axes while the user drags.
class Joystick extends StatefulWidget {
  const Joystick({super.key, this.size = 120.0, required this.onChange});
  final double size;
  final void Function(Offset offset) onChange;

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _knob = Offset.zero;

  void _updateFromLocal(Offset local) {
    final radius = widget.size / 2;
    final center = Offset(radius, radius);
    var delta = local - center;
    // clamp to circle
    final r = delta.distance;
    if (r > radius) delta = Offset.fromDirection(delta.direction, radius);

    // normalized -1..1
    final norm = Offset(delta.dx / radius, -delta.dy / radius);
    setState(() => _knob = delta);
    widget.onChange(norm);
  }

  void _reset() {
    setState(() => _knob = Offset.zero);
    widget.onChange(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanStart: (e) => _updateFromLocal(e.localPosition),
        onPanUpdate: (e) => _updateFromLocal(e.localPosition),
        onPanEnd: (e) => _reset(),
        onPanCancel: () => _reset(),
        child: CustomPaint(
          painter: _JoystickPainter(knob: _knob),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset knob;
  _JoystickPainter({required this.knob});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black26;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    // background
    canvas.drawCircle(center, radius, paint);

    // crosshair
    final cross = Paint()..color = Colors.black12..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), cross);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), cross);

    // knob
    final knobPaint = Paint()..color = Colors.white;
    final knobPos = center + knob;
    canvas.drawCircle(knobPos, radius * 0.28, knobPaint);
    canvas.drawCircle(knobPos, radius * 0.28, Paint()..color = Colors.black12..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter old) => old.knob != knob;
}
