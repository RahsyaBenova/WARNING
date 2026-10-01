import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// VerificationService sends the captured image directly to the Gemini API.
/// Configure at build/run time using `--dart-define=GEMINI_API_KEY=your_key`.
class VerificationService {
  static final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static final String _model = const String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-1.5-flash');

  /// Attempts to verify [imageBytes] for [missionId].
  /// Returns a map with keys: `success` (bool), `match` (bool?), `message` (String).
  /// If the key is not configured this returns success=false.
  static Future<Map<String, dynamic>> verifyMission(Uint8List imageBytes, String missionId) async {
    if (_apiKey.isEmpty) {
      return {'success': false, 'message': 'No Gemini API key configured (GEMINI_API_KEY).'};
    }

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
      );
      final prompt = '''
You are verifying a mission photo.
Mission ID: $missionId

Return strict JSON only with these keys:
{
  "match": true or false,
  "message": "short human-readable reason"
}

Treat the image as a walk-photo mission image and decide whether it matches the mission.
''';

      final resp = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Encode(imageBytes),
                  }
                },
              ],
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (resp.statusCode != 200) {
        return {'success': false, 'message': 'Gemini returned ${resp.statusCode}: ${resp.body}'};
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final text = (((data['candidates'] as List?)?.firstOrNull as Map?)?['content'] as Map?)?['parts'] as List?;
      final rawText = (text?.firstOrNull as Map?)?['text']?.toString() ?? resp.body;
      final parsed = json.decode(rawText) as Map<String, dynamic>;
      final match = parsed['match'] as bool?;
      final message = parsed['message']?.toString() ?? 'Verification complete';
      return {'success': true, 'match': match, 'message': message, 'raw': parsed};
    } catch (e) {
      return {'success': false, 'message': 'Verification failed: $e'};
    }
  }
}
