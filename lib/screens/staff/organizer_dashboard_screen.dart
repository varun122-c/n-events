import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class OrganizerDashboardScreen extends StatelessWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final stateProvider = Provider.of<AppStateProvider>(context);

    // Filter to only this organizer's assigned department events
    final dept = authProvider.assignedDepartment;
    final myEvents = stateProvider.events
        .where((e) =>
            dept.isEmpty ||
            e.category.toLowerCase().contains(dept.toLowerCase()) ||
            e.title.toLowerCase().contains(dept.toLowerCase()))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final totalRegs = stateProvider.registrations
        .where((r) => myEvents.any((e) => e.id == r.eventId))
        .length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organizer Dashboard',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
            if (dept.isNotEmpty)
              Text(dept,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7C3AED)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder_special_rounded, color: Color(0xFF7C3AED), size: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF7C3AED)),
            tooltip: 'Create Event',
            onPressed: () => context.go('/admin/event-form'),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF64748B)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'logout') {
                authProvider.logout();
                context.go('/auth');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _statPill('Events', '${myEvents.length}', const Color(0xFF7C3AED), isDark),
                const SizedBox(width: 12),
                _statPill('Registrations', '$totalRegs', const Color(0xFF2563EB), isDark),
              ],
            ),
          ),
          const Divider(height: 1),
          // Events List
          Expanded(
            child: myEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 56,
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          dept.isEmpty
                              ? 'No department assigned.\nContact admin.'
                              : 'No events for your department yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/admin/event-form'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          label: const Text('Create Event',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: myEvents.length,
                    itemBuilder: (_, i) => _buildEventCard(context, myEvents[i], stateProvider, isDark),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/event-form'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Event', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _statPill(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEventCard(
      BuildContext context, Event event, AppStateProvider stateProvider, bool isDark) {
    final regCount =
        stateProvider.registrations.where((r) => r.eventId == event.id).length;
    final dateStr = DateFormat('dd MMM, hh:mm a').format(event.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(event.title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(dateStr,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text('${event.venue} • ${event.category}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$regCount',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
            const Text('registered',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
        onTap: () => context.go('/admin/participants/${event.id}'),
      ),
    );
  }
}
