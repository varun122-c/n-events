import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for sending transactional emails via Sender.net API v2
/// (https://api.sender.net/v2/)
class SenderEmailService {
  static const String _baseUrl = 'https://api.sender.net/v2';
  static const String _prefApiKey = 'sender_net_api_key';
  static const String _prefSenderEmail = 'sender_net_from_email';
  static const String _prefSenderName = 'sender_net_from_name';

  /// Default API Token supplied by configuration
  static const String defaultApiToken =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiZDRhYmQ1NzIxNjM3NWI5Y2NkM2JlZGUyZjhlOTM2MWVhYWRmYjAxZjcyZTNmMzkwMzYwMDVmZWFhNzBlMjg5YjRiMGQ4MmFiYjJkYzY4NTkiLCJpYXQiOjE3OTAwMDkxNzUuNzQ3NDEyLCJuYmYiOjE3OTAwMDkxNzUuNzQ3NDE1LCJleHAiOjQ5NDM2MDkxNzUuNzQ0OTY3LCJzdWIiOiIxMTAxMjA1Iiwic2NvcGVzIjpbXX0.sBigtnkL755rcbnu-c9fZ_BJfVJkpJ0CcgeiJb-SHqlwkLznoL3gdMjmRQGlaXb9Vh5eJBCI-GvesU6TlFSpndsVo3jWh50BkIc_lp6xbuYrM9P8n9oG52dd9MyGYiYUqDpHqsLjdOkijYMrT07Q_xu85d6MDcKEmwYjnN5RAIX1GS5DIzcpxJn_DyxF9meQSdi2hitSW74UVytgWzMoytDP5DyV7DZg9_SCAKzY7Dz8EVoQZwMDXVY40zcOCZm6n9jC6ctCpSAfXaoZ8VbJ07wAyLGR-pqc77c_OjDwOz4y_ebYtVTl6BRAx9r-SM0gogKbp4C4NyqU3n4K2nKc_NRUiE2RrsIEigU3DI29HqSTTIBCAuPuQcerNvLEsPe4Jpzi9JuVycjMMjRrDSON4GoxHg0hj8Wpd77wGUmh6GJCHjFM5gCmxXNCSsx7RcFJUL61oiTeJXbr973q3sVjUyMHy9P1kLvjABn-gEZYSd5rC3KQjgGlg8MM6JUNn-nEFmu64BWfBsinxaqbqctq5nwZCdBxx9jLBMrVa6DP6G0uRXZyDuPm3PJCrTlyYRpRFJKPO6Zl4Q0RCBgXEJxMuAH21FWL7xQZBdNHsrD9TfLaJCEY0Jtl9OUTLMMC3c7gwHwkqgrJNbkv0FQ_tXWE1lZ_VRQgA5peNdp9dChg-T0';

  static const String defaultFromEmail = 'support@n-events.tech';
  static const String defaultFromName = 'N Events Platform';

  static String _currentApiToken = defaultApiToken;
  static String _currentFromEmail = defaultFromEmail;
  static String _currentFromName = defaultFromName;

  /// Initialize and load saved API settings if modified
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentApiToken = prefs.getString(_prefApiKey) ?? defaultApiToken;
      _currentFromEmail = prefs.getString(_prefSenderEmail) ?? defaultFromEmail;
      _currentFromName = prefs.getString(_prefSenderName) ?? defaultFromName;
    } catch (e) {
      debugPrint('SenderEmailService init error: $e');
    }
  }

  /// Getters
  static String get apiToken => _currentApiToken;
  static String get fromEmail => _currentFromEmail;
  static String get fromName => _currentFromName;

  /// Save new API configuration settings
  static Future<void> updateConfig({
    String? apiToken,
    String? fromEmail,
    String? fromName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (apiToken != null && apiToken.trim().isNotEmpty) {
      _currentApiToken = apiToken.trim();
      await prefs.setString(_prefApiKey, _currentApiToken);
    }
    if (fromEmail != null && fromEmail.trim().isNotEmpty) {
      _currentFromEmail = fromEmail.trim();
      await prefs.setString(_prefSenderEmail, _currentFromEmail);
    }
    if (fromName != null && fromName.trim().isNotEmpty) {
      _currentFromName = fromName.trim();
      await prefs.setString(_prefSenderName, _currentFromName);
    }
  }

  /// Reset settings back to default
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefApiKey);
    await prefs.remove(_prefSenderEmail);
    await prefs.remove(_prefSenderName);
    _currentApiToken = defaultApiToken;
    _currentFromEmail = defaultFromEmail;
    _currentFromName = defaultFromName;
  }

  /// Send a raw transactional email via Sender.net v2 API (`/message/send`)
  static Future<Map<String, dynamic>> sendEmail({
    required String toEmail,
    String? toName,
    required String subject,
    required String htmlContent,
    String? textContent,
    String? customFromEmail,
    String? customFromName,
    String? overrideToken,
  }) async {
    final token = overrideToken ?? _currentApiToken;
    final senderEmail = customFromEmail ?? _currentFromEmail;
    final senderName = customFromName ?? _currentFromName;

    final url = Uri.parse('$_baseUrl/message/send');

    final body = {
      'from': {
        'email': senderEmail,
        'name': senderName,
      },
      'to': [
        {
          'email': toEmail.trim(),
          if (toName != null && toName.trim().isNotEmpty) 'name': toName.trim(),
        }
      ],
      'subject': subject,
      'html': htmlContent,
      if (textContent != null && textContent.trim().isNotEmpty)
        'text': textContent,
    };

    try {
      debugPrint('Sending email via Sender.net to $toEmail...');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('Sender.net response statusCode: ${response.statusCode}');
      debugPrint('Sender.net response body: ${response.body}');

      Map<String, dynamic> responseJson;
      try {
        responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        responseJson = {'raw': response.body};
      }

      final isSuccess = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          responseJson['success'] != false;

      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'data': responseJson,
        'message': responseJson['message'] ??
            (isSuccess ? 'Email sent successfully!' : 'Failed to send email'),
      };
    } catch (e, stack) {
      debugPrint('SenderEmailService send error: $e\n$stack');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Error sending email: $e',
      };
    }
  }

  /// Launch native device mail client using mailto: (Zero API key / zero setup required!)
  static Future<bool> launchNativeMailto({
    required String toEmail,
    String? subject,
    String? body,
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: toEmail.trim(),
      queryParameters: {
        if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
        if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
      },
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        return await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('launchNativeMailto error: $e');
      return false;
    }
  }

  // ─── HIGH-LEVEL TRANSACTIONAL EMAIL TEMPLATES ─────────────────────────────

  /// Send Event Registration Confirmation Email with pass code and details
  static Future<Map<String, dynamic>> sendRegistrationConfirmation({
    required String recipientEmail,
    required String recipientName,
    required String eventTitle,
    required String eventDate,
    required String eventLocation,
    required String ticketCode,
    String? category,
  }) async {
    final subject = '🎉 Registration Confirmed: $eventTitle';
    final html = _buildRegistrationHtml(
      name: recipientName,
      eventTitle: eventTitle,
      eventDate: eventDate,
      location: eventLocation,
      ticketCode: ticketCode,
      category: category ?? 'Campus Event',
    );

    return await sendEmail(
      toEmail: recipientEmail,
      toName: recipientName,
      subject: subject,
      htmlContent: html,
      textContent:
          'Hi $recipientName,\n\nYour registration for "$eventTitle" is confirmed!\nTicket Pass Code: $ticketCode\nDate: $eventDate\nVenue: $eventLocation\n\nThank you,\nN-Events Team',
    );
  }

  /// Send Staff Role Assignment Email
  static Future<Map<String, dynamic>> sendStaffAssignmentEmail({
    required String recipientEmail,
    required String recipientName,
    required String eventTitle,
    required String assignedRole,
  }) async {
    final subject = '🛡️ Staff Role Assigned: $assignedRole for $eventTitle';
    final html = _buildStaffAssignmentHtml(
      name: recipientName,
      eventTitle: eventTitle,
      role: assignedRole,
    );

    return await sendEmail(
      toEmail: recipientEmail,
      toName: recipientName,
      subject: subject,
      htmlContent: html,
      textContent:
          'Hi $recipientName,\n\nYou have been assigned as $assignedRole for "$eventTitle".\n\nPlease check your N-Events app dashboard for details.',
    );
  }

  /// Send Custom Announcement or Broadcast Email
  static Future<Map<String, dynamic>> sendAnnouncementEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String announcementText,
    String? eventTitle,
  }) async {
    final html = _buildAnnouncementHtml(
      name: recipientName,
      subject: subject,
      bodyText: announcementText,
      eventTitle: eventTitle,
    );

    return await sendEmail(
      toEmail: recipientEmail,
      toName: recipientName,
      subject: subject,
      htmlContent: html,
      textContent: 'Hi $recipientName,\n\n$announcementText\n\nN-Events Team',
    );
  }

  // ─── BEAUTIFUL HTML TEMPLATE GENERATORS ───────────────────────────────────

  static String _buildRegistrationHtml({
    required String name,
    required String eventTitle,
    required String eventDate,
    required String location,
    required String ticketCode,
    required String category,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Event Booking Confirmed</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0f172a; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #f8fafc;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0f172a; padding: 30px 10px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" max-width="600" style="max-width: 600px; background-color: #1e293b; border-radius: 16px; overflow: hidden; border: 1px solid #334155; box-shadow: 0 10px 25px rgba(0,0,0,0.5);">
          <!-- Header Banner -->
          <tr>
            <td style="background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); padding: 32px 24px; text-align: center;">
              <h1 style="margin: 0; font-size: 26px; font-weight: 800; color: #ffffff; letter-spacing: 0.5px;">N EVENTS</h1>
              <p style="margin: 8px 0 0 0; font-size: 14px; color: #93c5fd;">Campus Event Management Platform</p>
            </td>
          </tr>
          <!-- Main Content -->
          <tr>
            <td style="padding: 32px 24px;">
              <h2 style="margin: 0 0 16px 0; font-size: 20px; color: #38bdf8;">🎉 Registration Confirmed!</h2>
              <p style="font-size: 15px; line-height: 1.6; color: #cbd5e1; margin: 0 0 24px 0;">
                Hello <strong style="color: #ffffff;">$name</strong>,<br>
                You are successfully registered for <strong>$eventTitle</strong>. Below are your pass details for entry.
              </p>

              <!-- Ticket Box -->
              <div style="background-color: #090d16; border: 2px dashed #0284c7; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
                <span style="font-size: 12px; font-weight: 700; color: #38bdf8; text-transform: uppercase; letter-spacing: 1px;">YOUR 10-DIGIT PASS CODE</span>
                <div style="font-size: 28px; font-weight: 900; color: #38bdf8; letter-spacing: 4px; margin: 12px 0;">$ticketCode</div>
                <p style="font-size: 12px; color: #94a3b8; margin: 0;">Show this pass code or your QR code at the entry gate.</p>
              </div>

              <!-- Details List -->
              <table width="100%" cellspacing="0" cellpadding="8" style="font-size: 14px; color: #cbd5e1; border-collapse: collapse;">
                <tr style="border-bottom: 1px solid #334155;">
                  <td style="padding: 10px 0; color: #94a3b8; font-weight: 600;">Event Name:</td>
                  <td style="padding: 10px 0; color: #ffffff; text-align: right; font-weight: 700;">$eventTitle</td>
                </tr>
                <tr style="border-bottom: 1px solid #334155;">
                  <td style="padding: 10px 0; color: #94a3b8; font-weight: 600;">Category:</td>
                  <td style="padding: 10px 0; color: #ffffff; text-align: right;">$category</td>
                </tr>
                <tr style="border-bottom: 1px solid #334155;">
                  <td style="padding: 10px 0; color: #94a3b8; font-weight: 600;">Date & Time:</td>
                  <td style="padding: 10px 0; color: #ffffff; text-align: right;">$eventDate</td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; color: #94a3b8; font-weight: 600;">Venue:</td>
                  <td style="padding: 10px 0; color: #ffffff; text-align: right;">$location</td>
                </tr>
              </table>

              <div style="margin-top: 32px; text-align: center;">
                <p style="font-size: 13px; color: #94a3b8;">Need help or have questions? Open the N-Events app to check updates or contact coordinators.</p>
              </div>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background-color: #0f172a; padding: 20px; text-align: center; border-top: 1px solid #334155; font-size: 12px; color: #64748b;">
              © 2026 N Events. All rights reserved.<br>
              Annamacharya Institute of Technology and Sciences, Tirupati.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  static String _buildStaffAssignmentHtml({
    required String name,
    required String eventTitle,
    required String role,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Staff Role Assignment</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0f172a; font-family: sans-serif; color: #f8fafc;">
  <table width="100%" cellspacing="0" cellpadding="0" style="background-color: #0f172a; padding: 30px 10px;">
    <tr>
      <td align="center">
        <table width="100%" max-width="600" style="max-width: 600px; background-color: #1e293b; border-radius: 16px; border: 1px solid #334155;">
          <tr>
            <td style="background: linear-gradient(135deg, #059669 0%, #10b981 100%); padding: 28px; text-align: center; color: white;">
              <h2 style="margin: 0; font-size: 22px;">🛡️ N EVENTS STAFF DUTY ASSIGNED</h2>
            </td>
          </tr>
          <tr>
            <td style="padding: 30px;">
              <p style="font-size: 16px; color: #e2e8f0;">Hello <strong>$name</strong>,</p>
              <p style="font-size: 14px; color: #cbd5e1; line-height: 1.5;">
                You have been assigned a official staff role for the upcoming campus event:
              </p>
              <div style="background-color: #0f172a; padding: 20px; border-radius: 10px; border-left: 4px solid #10b981; margin: 20px 0;">
                <p style="margin: 0 0 8px 0; font-size: 14px; color: #94a3b8;">Event Title:</p>
                <p style="margin: 0 0 16px 0; font-size: 18px; font-weight: bold; color: #ffffff;">$eventTitle</p>
                <p style="margin: 0 0 8px 0; font-size: 14px; color: #94a3b8;">Assigned Role / Responsibility:</p>
                <p style="margin: 0; font-size: 18px; font-weight: bold; color: #34d399;">$role</p>
              </div>
              <p style="font-size: 13px; color: #94a3b8;">Please login to your N-Events account to access scanner tools and management features.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  static String _buildAnnouncementHtml({
    required String name,
    required String subject,
    required String bodyText,
    String? eventTitle,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$subject</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0f172a; font-family: sans-serif; color: #f8fafc;">
  <table width="100%" cellspacing="0" cellpadding="0" style="background-color: #0f172a; padding: 30px 10px;">
    <tr>
      <td align="center">
        <table width="100%" max-width="600" style="max-width: 600px; background-color: #1e293b; border-radius: 16px; border: 1px solid #334155;">
          <tr>
            <td style="background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); padding: 28px; text-align: center; color: white;">
              <h2 style="margin: 0; font-size: 22px;">📢 N EVENTS ANNOUNCEMENT</h2>
            </td>
          </tr>
          <tr>
            <td style="padding: 30px;">
              <p style="font-size: 16px; color: #e2e8f0;">Hello <strong>$name</strong>,</p>
              ${eventTitle != null ? '<p style="font-size: 14px; color: #60a5fa; font-weight: bold; margin-bottom: 16px;">Regarding: $eventTitle</p>' : ''}
              <div style="font-size: 15px; color: #cbd5e1; line-height: 1.6; white-space: pre-wrap; margin: 16px 0;">$bodyText</div>
              <hr style="border: none; border-top: 1px solid #334155; margin: 24px 0;">
              <p style="font-size: 12px; color: #94a3b8; text-align: center;">Sent via N Events Campus Notification System</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }
}
