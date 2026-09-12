import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class StudentCoordinatorChatScreen extends StatefulWidget {
  final String eventId;
  final String studentRoll;

  const StudentCoordinatorChatScreen({
    super.key,
    required this.eventId,
    required this.studentRoll,
  });

  @override
  State<StudentCoordinatorChatScreen> createState() => _StudentCoordinatorChatScreenState();
}

class _StudentCoordinatorChatScreenState extends State<StudentCoordinatorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isCoordinatorTyping = false;

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

  void _sendMessage(AppStateProvider stateProvider, AuthProvider authProvider) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    stateProvider.sendChatMessage(
      widget.eventId,
      widget.studentRoll,
      authProvider.studentName.isNotEmpty ? authProvider.studentName : 'Student',
      'student',
      text,
    );

    _messageController.clear();
    _scrollToBottom();

    // Trigger visual typing feedback for coordinator auto-replies
    setState(() {
      _isCoordinatorTyping = true;
    });

    Timer(const Duration(milliseconds: 1300), () {
      if (mounted) {
        setState(() {
          _isCoordinatorTyping = false;
        });
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get event details
    final eventIndex = stateProvider.events.indexWhere((e) => e.id == widget.eventId);
    final eventTitle = eventIndex != -1 ? stateProvider.events[eventIndex].title : 'Event Support';
    final coordName = eventIndex != -1 ? stateProvider.events[eventIndex].coordinatorName : 'Coordinator';
    final coordPhone = eventIndex != -1 ? stateProvider.events[eventIndex].coordinatorPhone : '';

    // Get relevant messages
    final threadMessages = stateProvider.chatMessages
        .where((m) => m.eventId == widget.eventId && m.studentRoll == widget.studentRoll)
        .toList();
    
    // Sort by timestamp
    threadMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Schedule scroll to bottom and mark messages seen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stateProvider.markThreadAsSeen(widget.eventId, widget.studentRoll, 'student');
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Theme.of(context).appBarTheme.backgroundColor,
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
              context.go('/student');
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
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF2563EB), const Color(0xFF38BDF8)]
                      : [const Color(0xFF1E3C72), const Color(0xFF2563EB)],
                ),
              ),
              child: const Center(
                child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Coord. $coordName • Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (coordPhone.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.phone_outlined,
                size: 20,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
              ),
              tooltip: 'Call Coordinator',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Contact Coordinator: $coordPhone'),
                    backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFF1E293B),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Event Support Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFEFF6FF),
              border: Border(
                top: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFDBEAFE)),
                bottom: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFDBEAFE)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.headset_mic_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Direct chat with $coordName for queries & updates',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE0E7FF) : const Color(0xFF1E40AF),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'EVENT DESK',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat thread list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: threadMessages.length + (_isCoordinatorTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == threadMessages.length && _isCoordinatorTyping) {
                  return _buildTypingIndicator(coordName, isDark);
                }

                final msg = threadMessages[index];
                final isStudent = msg.senderRole == 'student';
                final timeStr = DateFormat('h:mm a').format(msg.timestamp);

                return Align(
                  key: ValueKey(msg.id),
                  alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isStudent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: isStudent
                              ? LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                                      : [const Color(0xFF1E3C72), const Color(0xFF2563EB)],
                                )
                              : null,
                          color: isStudent
                              ? null
                              : (isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9)),
                          border: isStudent
                              ? null
                              : (isDark ? Border.all(color: const Color(0xFF27272A)) : null),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isStudent ? 18 : 4),
                            bottomRight: Radius.circular(isStudent ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isStudent
                                  ? (isDark
                                      ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                                      : const Color(0xFF1E3C72).withValues(alpha: 0.15))
                                  : (isDark
                                      ? Colors.black.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.03)),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isStudent)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  coordName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: isStudent
                                    ? Colors.white
                                    : (isDark ? const Color(0xFFF4F4F5) : const Color(0xFF1E293B)),
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isStudent) ...[
                              const SizedBox(width: 5),
                              Icon(
                                Icons.done_rounded,
                                size: 14,
                                color: isDark ? Colors.white38 : Colors.grey,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Sent',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white38 : Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                );
              },
            ),
          ),

          // Quick Question Chips
          Container(
            height: 38,
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              children: [
                '📍 Where is the venue?',
                '⏰ What time does it start?',
                '🎟️ Is entry ticket required?',
                '📞 How to contact coordinator?',
              ].map((chipText) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      _messageController.text = chipText;
                      _sendMessage(stateProvider, authProvider);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          chipText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Message input bar with pitch black dark mode theme
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              border: isDark ? const Border(top: BorderSide(color: Color(0xFF27272A))) : null,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF09090B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask $coordName anything...',
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(stateProvider, authProvider),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2563EB), const Color(0xFF38BDF8)]
                            : [const Color(0xFF1E3C72), const Color(0xFF2563EB)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(stateProvider, authProvider),
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

  Widget _buildTypingIndicator(String coordName, bool isDark) {
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
              border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$coordName is typing',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation(
                      isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
