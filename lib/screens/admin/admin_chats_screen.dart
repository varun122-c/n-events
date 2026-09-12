import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_message_model.dart';

class ChatThread {
  final String eventId;
  final String studentRoll;
  final String studentName;
  final ChatMessageModel lastMessage;
  final int unreadCount;

  ChatThread({
    required this.eventId,
    required this.studentRoll,
    required this.studentName,
    required this.lastMessage,
    this.unreadCount = 0,
  });
}

class AdminChatsScreen extends StatefulWidget {
  const AdminChatsScreen({super.key});

  @override
  State<AdminChatsScreen> createState() => _AdminChatsScreenState();
}

class _AdminChatsScreenState extends State<AdminChatsScreen> {
  String? _selectedEventId;
  String? _selectedStudentRoll;
  String? _selectedStudentName;
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  String _searchQuery = '';
  bool _isFullScreenMode = true; // Full-page chat mode enabled by default

  @override
  void dispose() {
    _replyController.dispose();
    _searchController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendReply(AppStateProvider stateProvider) {
    final text = _replyController.text.trim();
    if (text.isEmpty || _selectedEventId == null || _selectedStudentRoll == null) return;

    stateProvider.sendChatMessage(
      _selectedEventId!,
      _selectedStudentRoll!,
      _selectedStudentName ?? 'Student',
      'coordinator',
      text,
    );

    _replyController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);

    // Group chat messages by eventId and studentRoll to find unique threads
    final Map<String, List<ChatMessageModel>> threadGroups = {};

    for (final msg in stateProvider.chatMessages) {
      final key = '${msg.eventId}_${msg.studentRoll}';
      threadGroups.putIfAbsent(key, () => []).add(msg);
    }

    final List<ChatThread> threads = [];
    threadGroups.forEach((key, msgs) {
      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final last = msgs.last;
      final unread = msgs.where((m) => m.senderRole == 'student' && !m.isRead).length;

      threads.add(ChatThread(
        eventId: last.eventId,
        studentRoll: last.studentRoll,
        studentName: last.studentName,
        lastMessage: last,
        unreadCount: unread,
      ));
    });

    threads.sort((a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp));

    // Filter threads by search query
    final filteredThreads = threads.where((t) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final eventIdx = stateProvider.events.indexWhere((e) => e.id == t.eventId);
      final eventTitle = eventIdx != -1 ? stateProvider.events[eventIdx].title.toLowerCase() : '';
      return t.studentName.toLowerCase().contains(q) ||
          t.studentRoll.toLowerCase().contains(q) ||
          eventTitle.contains(q);
    }).toList();

    final bool hasSelectedThread = _selectedEventId != null && _selectedStudentRoll != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final useFullScreenForChat = _isFullScreenMode || screenWidth < 768;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          tooltip: 'Back',
          onPressed: () {
            if (hasSelectedThread && useFullScreenForChat) {
              setState(() {
                _selectedEventId = null;
                _selectedStudentRoll = null;
                _selectedStudentName = null;
              });
            } else if (context.canPop()) {
              context.pop();
            } else {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (auth.currentUser?.role == 'coordinator') {
                context.go('/staff/coordinator');
              } else {
                context.go('/admin');
              }
            }
          },
        ),
        title: Text(
          hasSelectedThread && useFullScreenForChat
              ? 'Chat with ${_selectedStudentName ?? "Student"}'
              : 'Student Inquiries & Live Messaging',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (hasSelectedThread)
            IconButton(
              icon: Icon(
                _isFullScreenMode ? Icons.splitscreen_rounded : Icons.fullscreen_rounded,
                color: const Color(0xFF2563EB),
              ),
              tooltip: _isFullScreenMode ? 'Switch to Split View' : 'Switch to Full Page Chat View',
              onPressed: () {
                setState(() {
                  _isFullScreenMode = !_isFullScreenMode;
                });
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: useFullScreenForChat && hasSelectedThread
          // FULL PAGE CHAT VIEW MODE
          ? _buildFullPageChatView(context, stateProvider, isDark)
          // SPLIT VIEW OR THREAD LIST VIEW MODE
          : Row(
              children: [
                // 1. Threads Sidebar (Full Width if no thread selected or screen is single column)
                Expanded(
                  flex: hasSelectedThread ? 2 : 5,
                  child: Column(
                    children: [
                      // Search Field in Sidebar
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: isDark ? const Color(0xFF121212) : Colors.white,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v.trim()),
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Search student name, roll number, or event title…',
                            hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF2563EB)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: filteredThreads.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.speaker_notes_off_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No active student inquiries found.',
                                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredThreads.length,
                                separatorBuilder: (context, idx) => Divider(height: 1, color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9)),
                                itemBuilder: (context, idx) {
                                  final t = filteredThreads[idx];
                                  final eventIdx = stateProvider.events.indexWhere((e) => e.id == t.eventId);
                                  final eventTitle = eventIdx != -1 ? stateProvider.events[eventIdx].title : 'Campus Event';
                                  final isSelected = _selectedEventId == t.eventId && _selectedStudentRoll == t.studentRoll;
                                  final dateStr = DateFormat('MMM d, h:mm a').format(t.lastMessage.timestamp);

                                  return ListTile(
                                    key: ValueKey('${t.eventId}_${t.studentRoll}'),
                                    tileColor: isSelected
                                        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                                        : (isDark ? const Color(0xFF121212) : Colors.white),
                                    selected: isSelected,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t.studentName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (t.unreadCount > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${t.unreadCount} NEW',
                                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 3),
                                        Text(
                                          '$eventTitle • Roll: ${t.studentRoll}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.lastMessage.text,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3C72))
                                                : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569)),
                                            fontWeight: t.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(dateStr, style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
                                      ],
                                    ),
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected
                                          ? const Color(0xFF2563EB)
                                          : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                                      child: Text(
                                        t.studentName.isNotEmpty ? t.studentName[0].toUpperCase() : 'S',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedEventId = t.eventId;
                                        _selectedStudentRoll = t.studentRoll;
                                        _selectedStudentName = t.studentName;
                                      });
                                      stateProvider.markThreadAsSeen(t.eventId, t.studentRoll, 'coordinator');
                                      _scrollToBottom();
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // Divider between sidebar and chat details
                if (hasSelectedThread && !useFullScreenForChat)
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // 2. Split-View Chat Details Pane
                if (hasSelectedThread && !useFullScreenForChat)
                  Expanded(
                    flex: 3,
                    child: _buildChatPane(context, stateProvider, isDark, isFullScreen: false),
                  ),
              ],
            ),
    );
  }

  /// Builds Full Page Chat View occupying 100% of screen height and width
  Widget _buildFullPageChatView(BuildContext context, AppStateProvider stateProvider, bool isDark) {
    return Column(
      children: [
        // Top navigation bar for full page chat
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedEventId = null;
                    _selectedStudentRoll = null;
                    _selectedStudentName = null;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Inquiries', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                radius: 18,
                child: Text(
                  _selectedStudentName?.substring(0, 1).toUpperCase() ?? 'S',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedStudentName ?? 'Student',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text('Live Sync', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Builder(builder: (context) {
                      final eventIdx = stateProvider.events.indexWhere((e) => e.id == _selectedEventId);
                      final eventTitle = eventIdx != -1 ? stateProvider.events[eventIdx].title : 'Campus Event';
                      return Text(
                        '$eventTitle • Roll: $_selectedStudentRoll',
                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Expanded Chat Pane
        Expanded(
          child: _buildChatPane(context, stateProvider, isDark, isFullScreen: true),
        ),
      ],
    );
  }

  /// Builds Chat message list and reply input area
  Widget _buildChatPane(BuildContext context, AppStateProvider stateProvider, bool isDark, {required bool isFullScreen}) {
    final eventIdx = stateProvider.events.indexWhere((e) => e.id == _selectedEventId);
    final eventTitle = eventIdx != -1 ? stateProvider.events[eventIdx].title : 'Event Support';

    final activeMessages = stateProvider.chatMessages
        .where((m) => m.eventId == _selectedEventId && m.studentRoll == _selectedStudentRoll)
        .toList();
    activeMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Mark thread messages as seen by coordinator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedEventId != null && _selectedStudentRoll != null) {
        stateProvider.markThreadAsSeen(_selectedEventId!, _selectedStudentRoll!, 'coordinator');
        _scrollToBottom();
      }
    });

    return Container(
      color: isDark ? Colors.black : Colors.white,
      child: Column(
        children: [
          if (!isFullScreen)
            // Header for Split View
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72),
                    radius: 18,
                    child: Text(
                      _selectedStudentName?.substring(0, 1).toUpperCase() ?? 'S',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedStudentName ?? 'Student',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                        Text(
                          '$eventTitle • Roll: $_selectedStudentRoll',
                          style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                    onPressed: () {
                      setState(() {
                        _selectedEventId = null;
                        _selectedStudentRoll = null;
                        _selectedStudentName = null;
                      });
                    },
                  )
                ],
              ),
            ),

          // Message bubble list
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: activeMessages.length,
                itemBuilder: (context, index) {
                  final msg = activeMessages[index];
                  final isCoord = msg.senderRole == 'coordinator';
                  final timeStr = DateFormat('h:mm a').format(msg.timestamp);

                  return Align(
                    alignment: isCoord ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isCoord ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: isFullScreen
                                ? MediaQuery.of(context).size.width * 0.7
                                : MediaQuery.of(context).size.width * 0.45,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isCoord
                                ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72))
                                : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isCoord ? 12 : 4),
                              bottomRight: Radius.circular(isCoord ? 4 : 12),
                            ),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: isCoord
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(timeStr, style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                              if (isCoord) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.done_rounded,
                                  size: 14,
                                  color: isDark ? Colors.white38 : Colors.grey,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Sent',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white38 : Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Quick Response Action Chips for Coordinators
          Container(
            height: 40,
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              children: [
                '✅ Registration Verified',
                '⏳ Please reach venue 15m before event',
                '🪪 Keep college ID ready',
                '📲 Entry ticket is in your mobile app',
              ].map((chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    _replyController.text = chip;
                    _sendReply(stateProvider);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),

          // Reply input toolbar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _replyController,
                      style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Type your reply to student…',
                        hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8), fontSize: 12.5),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendReply(stateProvider),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _sendReply(stateProvider),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
