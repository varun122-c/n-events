import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/sender_email_service.dart';

class AdminEmailSettingsScreen extends StatefulWidget {
  const AdminEmailSettingsScreen({super.key});

  @override
  State<AdminEmailSettingsScreen> createState() =>
      _AdminEmailSettingsScreenState();
}

class _AdminEmailSettingsScreenState extends State<AdminEmailSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for API Config
  late TextEditingController _apiTokenController;
  late TextEditingController _fromEmailController;
  late TextEditingController _fromNameController;

  // Controllers for Quick Test
  final TextEditingController _testRecipientController =
      TextEditingController(text: 'support@n-events.tech');
  bool _isTesting = false;
  Map<String, dynamic>? _lastTestResponse;

  // Controllers for Dispatcher
  final TextEditingController _dispatchToController = TextEditingController();
  final TextEditingController _dispatchSubjectController =
      TextEditingController(text: 'N-Events Announcement');
  final TextEditingController _dispatchMessageController =
      TextEditingController();
  String? _selectedEventId;
  bool _isDispatching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiTokenController =
        TextEditingController(text: SenderEmailService.apiToken);
    _fromEmailController =
        TextEditingController(text: SenderEmailService.fromEmail);
    _fromNameController =
        TextEditingController(text: SenderEmailService.fromName);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiTokenController.dispose();
    _fromEmailController.dispose();
    _fromNameController.dispose();
    _testRecipientController.dispose();
    _dispatchToController.dispose();
    _dispatchSubjectController.dispose();
    _dispatchMessageController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    await SenderEmailService.updateConfig(
      apiToken: _apiTokenController.text,
      fromEmail: _fromEmailController.text,
      fromName: _fromNameController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Sender.net API configuration saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {});
  }

  Future<void> _resetDefaults() async {
    await SenderEmailService.resetToDefaults();
    _apiTokenController.text = SenderEmailService.apiToken;
    _fromEmailController.text = SenderEmailService.fromEmail;
    _fromNameController.text = SenderEmailService.fromName;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Defaults restored.'),
      ),
    );
    setState(() {});
  }

  Future<void> _runTestEmail() async {
    final targetEmail = _testRecipientController.text.trim();
    if (targetEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipient email.')),
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _lastTestResponse = null;
    });

    final response = await SenderEmailService.sendEmail(
      toEmail: targetEmail,
      toName: 'Test Recipient',
      subject: '🧪 N-Events Sender.net API Test Email',
      htmlContent: '''
        <div style="font-family: sans-serif; padding: 20px; background: #0f172a; color: #fff; border-radius: 12px;">
          <h2 style="color: #38bdf8;">N-Events Sender.net API Operational Test</h2>
          <p>This email confirms that your Sender.net API v2 integration is working correctly.</p>
          <hr style="border-color: #334155;">
          <p style="font-size: 12px; color: #94a3b8;">Sent via https://api.sender.net/v2/</p>
        </div>
      ''',
      textContent: 'N-Events Sender.net API Test Email',
      overrideToken: _apiTokenController.text,
      customFromEmail: _fromEmailController.text,
      customFromName: _fromNameController.text,
    );

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _lastTestResponse = response;
    });
  }

  Future<void> _sendDispatchEmail() async {
    final recipient = _dispatchToController.text.trim();
    final subject = _dispatchSubjectController.text.trim();
    final message = _dispatchMessageController.text.trim();

    if (recipient.isEmpty || subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill out all required dispatch fields.')),
      );
      return;
    }

    setState(() {
      _isDispatching = true;
    });

    final response = await SenderEmailService.sendAnnouncementEmail(
      recipientEmail: recipient,
      recipientName: recipient.split('@').first,
      subject: subject,
      announcementText: message,
    );

    if (!mounted) return;
    setState(() {
      _isDispatching = false;
    });

    final bool success = response['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '🚀 Email dispatched successfully!'
            : '❌ Dispatch failed: ${response['message']}'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateProvider = Provider.of<AppStateProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sender.net Email Center',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const Text(
              'API v2 (api.sender.net/v2/) Integration',
              style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          tabs: const [
            Tab(icon: Icon(Icons.key_rounded), text: 'API Config & Test'),
            Tab(icon: Icon(Icons.send_rounded), text: 'Email Dispatcher'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfigTab(isDark),
          _buildDispatcherTab(isDark, stateProvider),
        ],
      ),
    );
  }

  Widget _buildConfigTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // API Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sender.net API v2',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Endpoint: https://api.sender.net/v2/message/send\nBearer Token Authentication',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // API Configuration Form Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings_suggest_rounded,
                          color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'API Credentials',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sender.net API Bearer Token',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiTokenController,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.cyan.shade200 : Colors.blue.shade900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter Sender.net Bearer Token...',
                      filled: true,
                      fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Default Sender Email',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _fromEmailController,
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'support@n-events.tech',
                                filled: true,
                                fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sender Name',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _fromNameController,
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'N-Events Platform',
                                filled: true,
                                fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveConfig,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Save Settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _resetDefaults,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Reset Defaults'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // API Testing Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report_rounded,
                          color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Test Sender API Connection',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recipient Test Email',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _testRecipientController,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'user@example.com',
                      filled: true,
                      fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTesting ? null : _runTestEmail,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(_isTesting
                              ? 'Testing…'
                              : 'Send via Sender.net'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final target = _testRecipientController.text.trim();
                            if (target.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter recipient email.')),
                              );
                              return;
                            }
                            final launched = await SenderEmailService.launchNativeMailto(
                              toEmail: target,
                              subject: '🧪 N-Events Test Email',
                              body: 'Hi from N-Events!\n\nThis test message was launched via native mailto.',
                            );
                            if (!mounted) return;
                            if (!launched) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch email app.')),
                              );
                            }
                          },
                          icon: const Icon(Icons.mark_email_unread_rounded, size: 18),
                          label: const Text('Open Native Mail'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_lastTestResponse != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _lastTestResponse!['success'] == true
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _lastTestResponse!['success'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _lastTestResponse!['success'] == true
                                    ? Icons.check_circle_rounded
                                    : Icons.error_rounded,
                                color: _lastTestResponse!['success'] == true
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _lastTestResponse!['success'] == true
                                    ? 'API Request Successful'
                                    : 'API Response Result',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _lastTestResponse!['success'] == true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'HTTP ${_lastTestResponse!['statusCode'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _lastTestResponse!['message'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Raw Response:',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white54 : Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            const JsonEncoder.withIndent('  ')
                                .convert(_lastTestResponse!['data'] ?? _lastTestResponse!),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatcherTab(bool isDark, AppStateProvider stateProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign_rounded,
                          color: Color(0xFF8B5CF6), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Dispatch Custom Email Announcement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Optional Event Selector
                  Text(
                    'Link to Event (Optional)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedEventId,
                    decoration: InputDecoration(
                      hintText: 'Select event (Optional)',
                      filled: true,
                      fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: stateProvider.events.map((e) {
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text(e.title, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedEventId = val;
                        if (val != null) {
                          final event = stateProvider.events
                              .firstWhere((e) => e.id == val);
                          _dispatchSubjectController.text =
                              'Important Announcement: ${event.title}';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Recipient Email',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dispatchToController,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'recipient@gmail.com',
                      filled: true,
                      fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Email Subject',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dispatchSubjectController,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Announcement Subject',
                      filled: true,
                      fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Announcement Message (HTML / Text)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dispatchMessageController,
                    maxLines: 6,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText:
                          'Write announcement message here...\ne.g. Venue changed to Auditorium Block B, starting at 10 AM.',
                      filled: true,
                      fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isDispatching ? null : _sendDispatchEmail,
                          icon: _isDispatching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(_isDispatching
                              ? 'Dispatching…'
                              : 'Send via Sender.net'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final recipient = _dispatchToController.text.trim();
                            final subject = _dispatchSubjectController.text.trim();
                            final message = _dispatchMessageController.text.trim();

                            if (recipient.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter recipient email.')),
                              );
                              return;
                            }
                            final launched = await SenderEmailService.launchNativeMailto(
                              toEmail: recipient,
                              subject: subject.isNotEmpty ? subject : 'N-Events Notice',
                              body: message,
                            );
                            if (!mounted) return;
                            if (!launched) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open email app.')),
                              );
                            }
                          },
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Compose in Native Mail'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B5CF6),
                            side: const BorderSide(color: Color(0xFF8B5CF6)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
