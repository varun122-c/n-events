import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class TechProviderScreen extends StatelessWidget {
  const TechProviderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final stateProvider = Provider.of<AppStateProvider>(context);

    final assignedEvents = stateProvider.getAssignedEvents(authProvider.assignedEventIds);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tech Provider',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text('${assignedEvents.length} event(s) assigned',
                style: const TextStyle(fontSize: 11, color: Color(0xFFD97706))),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFD97706).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.build_rounded, color: Color(0xFFD97706), size: 20),
        ),
        actions: [
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
      body: assignedEvents.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.build_circle_rounded, size: 56, color: Color(0xFF374151)),
                  SizedBox(height: 12),
                  Text(
                    'No events assigned.\nContact admin to assign events.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignedEvents.length,
              itemBuilder: (_, i) => _buildTechCard(context, assignedEvents[i], isDark),
            ),
    );
  }

  Widget _buildTechCard(BuildContext context, Event event, bool isDark) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(event.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFD97706).withValues(alpha: 0.2), width: 1.2),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_rounded, color: Color(0xFFD97706), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    Text(event.category,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFD97706))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time_rounded, dateStr, isDark),
          const SizedBox(height: 4),
          _infoRow(Icons.location_on_rounded, event.venue, isDark),
          const SizedBox(height: 4),
          _infoRow(Icons.person_rounded, 'Coordinator: ${event.coordinatorName}', isDark),
          const SizedBox(height: 4),
          _infoRow(Icons.phone_rounded, event.coordinatorPhone, isDark),
          const SizedBox(height: 12),
          // Tech notes section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ensure all AV/technical equipment is tested 1 hour before event.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ),
      ],
    );
  }
}
