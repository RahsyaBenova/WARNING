# walk_trip

A new Flutter project.

## AR photo mission setup

The today photo mission now opens the live AR camera screen, overlays the 3D model from `assets/character.glb`, and sends the captured image to the Gemini API for verification.

Run the app with your Gemini key as a build-time define:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
```

The app expects Gemini to return JSON with at least `match` and `message` fields.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
