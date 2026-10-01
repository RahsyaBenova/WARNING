import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../widgets/joystick.dart';

/// Camera-overlay scene that shows the back camera preview and overlays a
/// movable "character" widget that the joystick controls. This is a pragmatic
/// fallback to give a live-camera + interactive model experience without full
/// AR (ARCore/ARKit) integration. To upgrade to real AR, integrate a plugin
/// such as `ar_flutter_plugin` (requires additional platform setup).
class ARScene extends StatefulWidget {
  const ARScene({super.key});

  @override
  State<ARScene> createState() => _ARSceneState();
}

class _ARSceneState extends State<ARScene> {
  final GlobalKey _captureKey = GlobalKey();
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _cameraError;
  Uint8List? _webImageBytes;
  bool _webCameraBusy = false;
  Offset _modelOffset = const Offset(0, -0.05); // relative center (-1..1)
  double _modelScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _cameraError = null;
        _webImageBytes = null;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _cameraError = 'No camera was found on this device or browser.';
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      _cameraError = 'Camera startup failed: $e';
      if (mounted) setState(() {});
    }
  }

  Future<void> _openWebCamera() async {
    setState(() {
      _webCameraBusy = true;
      _cameraError = null;
    });

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _webImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Browser camera failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _webCameraBusy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // joystick supplies normalized -1..1 offsets; convert to on-screen movement
  void _onJoystick(Offset norm) {
    // change per tick
    const step = 0.03;
    setState(() {
      _modelOffset = Offset(_modelOffset.dx + norm.dx * step, _modelOffset.dy + norm.dy * step);
      // clamp to -0.9..0.9 to avoid going off-screen
      _modelOffset = Offset(_modelOffset.dx.clamp(-0.9, 0.9), _modelOffset.dy.clamp(-0.9, 0.9));
    });
  }

  Future<void> _captureFrame() async {
    final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: View.of(context).devicePixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data?.buffer.asUint8List();
    if (!mounted || bytes == null) return;
    Navigator.of(context).pop<Uint8List>(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller != null && _controller!.value.isInitialized;
    final isWeb = kIsWeb;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR camera mission'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _modelOffset = const Offset(0, -0.05);
                _modelScale = 1.0;
              });
            },
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset',
          ),
          IconButton(
            onPressed: _captureFrame,
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Capture',
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (isWeb) {
            return _buildWebCameraView(context);
          }

          if (!isReady) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _cameraError ?? 'Camera not available in this browser/session.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _cameraError = null;
                          _initFuture = _initCamera();
                        });
                      },
                      child: const Text('Retry camera'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RepaintBoundary(
            key: _captureKey,
            child: Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                _buildModelOverlay(context),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Joystick(size: 120, onChange: _onJoystick),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'Move the white mesh with the joystick, then capture',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebCameraView(BuildContext context) {
    final captured = _webImageBytes;

    return Stack(
      children: [
        Positioned.fill(
          child: captured == null
              ? Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Chrome camera capture uses the browser camera picker on web.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _webCameraBusy ? null : _openWebCamera,
                          child: Text(_webCameraBusy ? 'Opening camera...' : 'Open Chrome camera'),
                        ),
                        if (_cameraError != null) ...[
                          const SizedBox(height: 12),
                          Text(_cameraError!, textAlign: TextAlign.center),
                        ],
                      ],
                    ),
                  ),
                )
              : Image.memory(captured, fit: BoxFit.cover),
        ),
        if (captured != null)
          RepaintBoundary(
            key: _captureKey,
            child: Stack(
              children: [
                Positioned.fill(child: Image.memory(captured, fit: BoxFit.cover)),
                _buildModelOverlay(context),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Joystick(size: 120, onChange: _onJoystick),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            onPressed: _captureFrame,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Use photo'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _webImageBytes = null),
                            icon: const Icon(Icons.replay),
                            label: const Text('Retake'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'Move the white mesh with the joystick, then use the photo.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildModelOverlay(BuildContext context) {
    // center position in screen coordinates
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final pos = center + Offset(size.width * _modelOffset.dx / 2, size.height * _modelOffset.dy / 2);

    return Positioned(
      left: pos.dx - 64 * _modelScale,
      top: pos.dy - 64 * _modelScale,
      child: Transform.scale(
        scale: _modelScale,
        child: Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: ModelViewer(
            src: 'assets/character.glb',
            backgroundColor: Colors.transparent,
            autoRotate: true,
            cameraControls: false,
            disableZoom: true,
            interactionPrompt: InteractionPrompt.none,
          ),
        ),
      ),
    );
  }
}
