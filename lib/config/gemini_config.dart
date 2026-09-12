class GeminiConfig {
  // Gemini API Key (pass via --dart-define=GEMINI_API_KEY=your_key or replace placeholder)
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
  );
  static const String primaryModel = 'gemini-2.5-flash';
  static const String fallbackModel = 'gemini-3.5-flash';
}
