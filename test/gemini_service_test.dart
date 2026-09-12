import 'package:flutter_test/flutter_test.dart';
import 'package:n_vents/services/gemini_service.dart';

void main() {
  test('Gemini API Key Connection Test', () async {
    final result = await GeminiService.testConnection();
    expect(result['success'], isTrue);
    expect(result['model'], isNotNull);
    print('Gemini API Connection Success! Model: ${result['model']}, Output: ${result['message']}');
  });
}
