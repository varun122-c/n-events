import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../config/gemini_config.dart';
import '../providers/auth_provider.dart';
import '../providers/app_state_provider.dart';

class GeminiService {
  /// Test if the Gemini API key is active and responding
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final modelsToTest = [GeminiConfig.primaryModel, GeminiConfig.fallbackModel];
      for (final model in modelsToTest) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${GeminiConfig.apiKey}',
        );

        final client = HttpClient();
        final request = await client.postUrl(url);
        request.headers.contentType = ContentType.json;

        final requestPayload = jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": "Hello, respond with ONLINE."}
              ]
            }
          ]
        });

        request.write(requestPayload);
        final response = await request.close();
        final responseString = await response.transform(utf8.decoder).join();
        client.close();

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(responseString);
          final String? responseText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (responseText != null && responseText.trim().isNotEmpty) {
            return {
              'success': true,
              'model': model,
              'message': responseText.trim(),
            };
          }
        }
      }
      return {
        'success': false,
        'message': 'API returned an error response.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Generate AI response using user prompt and app state context
  static Future<String?> generateResponse({
    required String userPrompt,
    required AuthProvider authProvider,
    required AppStateProvider stateProvider,
  }) async {
    final modelsToTry = [GeminiConfig.primaryModel, GeminiConfig.fallbackModel];

    for (final model in modelsToTry) {
      try {
        final studentName = authProvider.studentName.isNotEmpty ? authProvider.studentName : 'Student';
        final studentRoll = authProvider.studentRoll.isNotEmpty ? authProvider.studentRoll : 'N/A';
        final participantCode = authProvider.participantCode;
        final dept = authProvider.studentDept.isNotEmpty ? authProvider.studentDept : 'N/A';
        final year = authProvider.studentYear.isNotEmpty ? authProvider.studentYear : 'N/A';
        final email = authProvider.currentUser?.email ?? 'N/A';

        // Build structured app context
        final eventsSummary = stateProvider.events.isEmpty
            ? 'No active events currently.'
            : stateProvider.events.map((e) {
                final dateStr = DateFormat('MMM d, yyyy @ h:mm a').format(e.dateTime);
                return '- Title: "${e.title}" | ID: "${e.id}" | Date: $dateStr | Venue: "${e.venue}" | Category: "${e.category}" | Coordinator: "${e.coordinatorName}" (${e.coordinatorPhone}) | Summary: "${e.description}"';
              }).join('\n');

        final userRegs = stateProvider.registrations
            .where((r) => studentRoll.isNotEmpty && r.rollNumber.toLowerCase() == studentRoll.toLowerCase())
            .toList();
        final totalRegsCount = userRegs.length;
        final attendedCount = userRegs.where((r) => r.status == 'Attended').length;

        final systemInstructions = '''
You are N.ai, the official, fully-authorized AI Campus Assistant for N Events application. You have complete access to local app data and event systems.

[LIVE STUDENT PROFILE DATA]
- Name: $studentName
- Student Roll / User ID: $studentRoll
- Permanent 10-Digit Participant Code: $participantCode
- Email: $email
- Department: $dept
- Year of Study: $year
- Registrations: $totalRegsCount ($attendedCount attended/certificates earned)

[LIVE CAMPUS EVENTS DATA]
$eventsSummary

[FULL ACCESS CAPABILITIES & INSTRUCTIONS]
- You have full access to guide the user on filling event registration forms, viewing event tickets, accessing certificates, and retrieving permanent 10-digit codes.
- When asked to register or fill form details for an event, confirm the student's autofilled profile ($studentName, ID: $studentRoll, Code: $participantCode) and instruct them to tap the event card to finalize registration.
- Provide direct, intelligent answers based on live app data. Keep responses clean, well-formatted, professional, and emoji-free.
- DO NOT output raw Markdown symbols like asterisks (** or *) or hash symbols (#). Use standard clean bullet points (•) and plain text headings.
''';

        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${GeminiConfig.apiKey}',
        );

        final client = HttpClient();
        final request = await client.postUrl(url);
        request.headers.contentType = ContentType.json;

        final requestPayload = jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": "$systemInstructions\n\nStudent Query: $userPrompt"}
              ]
            }
          ]
        });

        request.write(requestPayload);
        final response = await request.close();

        if (response.statusCode == 200) {
          final responseString = await response.transform(utf8.decoder).join();
          final jsonResponse = jsonDecode(responseString);
          final String? responseText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
          client.close();
          if (responseText != null && responseText.trim().isNotEmpty) {
            final cleaned = responseText.trim()
                .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1')
                .replaceAll(RegExp(r'\*([^*]+)\*'), r'\1')
                .replaceAll(RegExp(r'^\s*[\*]\s+', multiLine: true), '• ')
                .replaceAll(RegExp(r'^\s*#+\s*', multiLine: true), '');
            return cleaned;
          }
        } else {
          if (kDebugMode) {
            final errBody = await response.transform(utf8.decoder).join();
            print('Gemini API [$model] Status ${response.statusCode}: $errBody');
          }
          client.close();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error querying Gemini model [$model]: $e');
        }
      }
    }
    return null;
  }
}
