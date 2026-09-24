import 'package:flutter_test/flutter_test.dart';
import 'package:n_vents/config/gemini_config.dart';
import 'package:n_vents/services/gemini_service.dart';

void main() {
  test('Gemini API Key Connection Test', () async {
    final result = await GeminiService.testConnection();
    if (GeminiConfig.apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      expect(result['success'], isFalse);
      expect(result['message'], isNotNull);
    } else {
      expect(result['success'], isTrue);
      expect(result['model'], isNotNull);
    }
  });
}
