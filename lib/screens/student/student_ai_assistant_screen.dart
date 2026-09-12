import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/gemini_service.dart';
import '../../models/event_model.dart';
import '../../widgets/universal_image.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? linkedEventId;
  final String? shortcutAction;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.linkedEventId,
    this.shortcutAction,
  });
}

class StudentAiAssistantScreen extends StatefulWidget {
  const StudentAiAssistantScreen({super.key});

  @override
  State<StudentAiAssistantScreen> createState() => _StudentAiAssistantScreenState();
}

class _StudentAiAssistantScreenState extends State<StudentAiAssistantScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _suggestions = [
    'Recommend technical hackathons',
    'How do I earn certificates?',
    'Any sports events coming up?',
    'Show live music sessions',
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text: "Hi! I'm N.ai, your AI Campus Assistant. Ask me anything about campus events, registrations, or digital certificates!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _testApiKey() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing Gemini API key connection...'),
        duration: Duration(seconds: 1),
      ),
    );

    final result = await GeminiService.testConnection();
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gemini API is ONLINE! Active Model: ${result['model']}'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API Status Error: ${result['message']}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessageText = text.trim();

    setState(() {
      _messages.add(
        ChatMessage(
          text: userMessageText,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final stateProvider = Provider.of<AppStateProvider>(context, listen: false);

    // Call Gemini AI API with full app context
    final geminiResponse = await GeminiService.generateResponse(
      userPrompt: userMessageText,
      authProvider: authProvider,
      stateProvider: stateProvider,
    );

    if (!mounted) return;

    if (geminiResponse != null && geminiResponse.trim().isNotEmpty) {
      final lowerResponse = geminiResponse.toLowerCase();
      String? matchedEventId;
      for (final event in stateProvider.events) {
        if (lowerResponse.contains(event.title.toLowerCase())) {
          matchedEventId = event.id;
          break;
        }
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: geminiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            linkedEventId: matchedEventId,
          ),
        );
        _isTyping = false;
      });
    } else {
      final fallbackResponse = _generateAiResponse(userMessageText);
      setState(() {
        _messages.add(fallbackResponse);
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  ChatMessage _generateAiResponse(String query) {
    final cleanQuery = query.toLowerCase();
    final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final now = DateTime.now();

    // Helper to find events
    Event findEventByKeyword(String kw) {
      return stateProvider.events.firstWhere(
        (e) => e.title.toLowerCase().contains(kw) || e.description.toLowerCase().contains(kw),
        orElse: () => Event(
          id: '', title: '', description: '', bannerUrl: '', 
          dateTime: now, venue: '', category: '', coordinatorName: '', coordinatorPhone: ''
        ),
      );
    }

    // 1. Technical / Hackathon
    if (cleanQuery.contains('tech') || cleanQuery.contains('hackathon') || cleanQuery.contains('code') || cleanQuery.contains('coding')) {
      final match = findEventByKeyword('hackathon');
      final robotics = findEventByKeyword('robotics');
      
      if (match.id.isNotEmpty) {
        return ChatMessage(
          text: "I found the \"${match.title}\"! It's a 24-hour hackathon scheduled at ${match.venue}. Tap the recommendation card below to view details and register:",
          isUser: false,
          timestamp: DateTime.now(),
          linkedEventId: match.id,
        );
      } else if (robotics.id.isNotEmpty) {
        return ChatMessage(
          text: "I found the \"${robotics.title}\"! It's a hands-on workshop led by expert engineers. Tap below to check it out:",
          isUser: false,
          timestamp: DateTime.now(),
          linkedEventId: robotics.id,
        );
      }
    }

    // 2. Music / Cultural
    if (cleanQuery.contains('music') || cleanQuery.contains('acoustic') || cleanQuery.contains('band') || cleanQuery.contains('song') || cleanQuery.contains('cultural')) {
      final match = findEventByKeyword('music');
      if (match.id.isNotEmpty) {
        return ChatMessage(
          text: "Relax and enjoy live performances at \"${match.title}\"! It's hosted at the ${match.venue}. Here's the details card:",
          isUser: false,
          timestamp: DateTime.now(),
          linkedEventId: match.id,
        );
      }
    }

    // 3. Sports
    if (cleanQuery.contains('sport') || cleanQuery.contains('cricket') || cleanQuery.contains('match') || cleanQuery.contains('game') || cleanQuery.contains('play')) {
      final match = findEventByKeyword('cricket');
      if (match.id.isNotEmpty) {
        return ChatMessage(
          text: "Cheer for your team in the \"${match.title}\"! It starts on ${DateFormat('MMMM d').format(match.dateTime)} at ${match.venue}. Tap below to register:",
          isUser: false,
          timestamp: DateTime.now(),
          linkedEventId: match.id,
        );
      }
    }

    // 4. Workshops
    if (cleanQuery.contains('workshop') || cleanQuery.contains('design') || cleanQuery.contains('ux') || cleanQuery.contains('ui')) {
      final masterclass = findEventByKeyword('masterclass');
      final robotics = findEventByKeyword('robotics');
      
      if (robotics.id.isNotEmpty && cleanQuery.contains('robot')) {
        return ChatMessage(
          text: "Here is the \"${robotics.title}\". Learn robot architecture and neural networks hands-on. Tap below:",
          isUser: false,
          timestamp: DateTime.now(),
          linkedEventId: robotics.id,
        );
      } else if (masterclass.id.isNotEmpty) {
        return ChatMessage(
          text: "I highly recommend the \"${masterclass.title}\" to learn professional design layouts in Figma. Tap below:",
          isUser: false,
          timestamp: DateTime.now(),
          linkedEventId: masterclass.id,
        );
      }
    }

    // 5. Certificates
    if (cleanQuery.contains('certificate') || cleanQuery.contains('earn') || cleanQuery.contains('download')) {
      return ChatMessage(
        text: "You earn digital certificates automatically once the event coordinator marks your attendance as 'Attended'. You can view and download all your earned certificates under the 'Certificates' tab.",
        isUser: false,
        timestamp: DateTime.now(),
        shortcutAction: 'certificates',
      );
    }

    // 6. Profile
    if (cleanQuery.contains('profile') || cleanQuery.contains('roll') || cleanQuery.contains('id') || cleanQuery.contains('change')) {
      return ChatMessage(
        text: "You can configure your student details under the 'Profile' tab. Saving your profile autofills the event registration forms for you!",
        isUser: false,
        timestamp: DateTime.now(),
        shortcutAction: 'profile',
      );
    }

    // Default Fallback
    return ChatMessage(
      text: "I couldn't find a direct match. However, I can help you search for technical hackathons, cultural sessions, sports championships, or direct you to your certificates feed. Try typing 'hackathon' or 'certificates'!",
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Provider.of<AppStateProvider>(context, listen: false).setStudentTabIndex(0);
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD97706),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Image.asset(
                  'assets/images/n_ai_logo.jpg',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'N.ai',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.fiber_manual_record_rounded, size: 8, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'AI Online (Gemini Powered)',
                      style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 22),
            tooltip: 'Test AI API Key Status',
            onPressed: _testApiKey,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggestions row
          if (_messages.length == 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    key: ValueKey(index),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(_suggestions[index]),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                      backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
                      side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _sendMessage(_suggestions[index]),
                    ),
                  );
                },
              ),
            ),
          ],

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(isDark);
                }
                
                final msg = _messages[index];
                return _buildMessageBubble(msg, stateProvider, isDark);
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask Aura about hackathons, events, certificates...',
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72),
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, AppStateProvider stateProvider, bool isDark) {
    final Alignment align = msg.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final Color bgColor = msg.isUser
        ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72))
        : (isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9));
    final Color textColor = msg.isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B));
    final timeStr = DateFormat('h:mm a').format(msg.timestamp);

    return Align(
      alignment: align,
      child: Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : 18),
              ),
              border: msg.isUser
                  ? null
                  : Border.all(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                    ),
            ),
            child: _buildFormattedText(msg.text, textColor, isDark),
          ),
          
          // Render Clickable recommendations card
          if (msg.linkedEventId != null) ...[
            _buildLinkedEventCard(msg.linkedEventId!, stateProvider, isDark),
          ],

          // Render tab redirect action button
          if (msg.shortcutAction != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Navigating to ${msg.shortcutAction!.toUpperCase()} section...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text('Open ${msg.shortcutAction}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              timeStr,
              style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, Color baseColor, bool isDark) {
    if (text.isEmpty) return const SizedBox.shrink();

    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Detect bullet points
      final isBullet = line.startsWith('* ') || line.startsWith('- ') || line.startsWith('• ') || RegExp(r'^\d+[\.\)]\s+').hasMatch(line);
      if (isBullet) {
        line = line.replaceFirst(RegExp(r'^([\*\-\•]|\d+[\.\)])\s*'), '');
      }

      // Detect headers
      final isHeader = line.startsWith('#') || (line.startsWith('**') && line.endsWith('**')) || (line.endsWith(':') && line.length < 60 && !line.contains('http'));
      if (isHeader) {
        line = line.replaceAll(RegExp(r'[#\*]'), '').trim();
      }

      // Clean remaining raw markdown asterisks or backslashes
      final cleanText = line.replaceAll('**', '').replaceAll('*', '').replaceAll('\\', '').trim();

      if (cleanText.isEmpty) continue;

      if (isHeader) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              cleanText,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3C72),
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      } else if (isBullet) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 3, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 8),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    cleanText,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: baseColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              cleanText,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: baseColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _buildLinkedEventCard(String eventId, AppStateProvider stateProvider, bool isDark) {
    final eventIndex = stateProvider.events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return const SizedBox.shrink();
    final event = stateProvider.events[eventIndex];
    final dateStr = DateFormat('EEE, MMM d').format(event.dateTime);

    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: UniversalImage(
              pathOrUrl: event.bannerUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr • ${event.venue}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/student/event/${event.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('View Event Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Image.asset(
                    'assets/images/n_ai_logo.jpg',
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'N.ai is thinking & analyzing...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 10),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
