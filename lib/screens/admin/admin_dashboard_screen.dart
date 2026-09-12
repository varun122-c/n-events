import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../widgets/universal_image.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Calculate metrics
    final totalEvents = stateProvider.events.length;
    final totalRegistrations = stateProvider.registrations.length;
    final totalUsersCount = stateProvider.dbProfiles.isNotEmpty
        ? stateProvider.dbProfiles.length
        : (authProvider.registeredUsers.length + (authProvider.isLoggedIn ? 1 : 0));
    
    // Recent registrations feed
    final recentRegs = stateProvider.registrations.reversed.take(4).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Manage campus events & banners',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: Icon(
              stateProvider.themeMode == ThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : stateProvider.themeMode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.settings_suggest_rounded,
              color: stateProvider.themeMode == ThemeMode.dark
                  ? Colors.amber
                  : stateProvider.themeMode == ThemeMode.light
                      ? Colors.orange
                      : const Color(0xFF64748B),
            ),
            tooltip: 'Choose Theme Mode',
            onSelected: (ThemeMode mode) {
              stateProvider.setThemeMode(mode);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
              const PopupMenuItem<ThemeMode>(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Light Mode'),
                  ],
                ),
              ),
              const PopupMenuItem<ThemeMode>(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('Dark Mode'),
                  ],
                ),
              ),
              const PopupMenuItem<ThemeMode>(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    Icon(Icons.settings_suggest_rounded, color: Colors.blueGrey, size: 20),
                    SizedBox(width: 8),
                    Text('System Default (Auto)'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.cyan.shade100,
              child: Text(
                authProvider.studentName.isNotEmpty ? authProvider.studentName[0].toUpperCase() : 'A',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
              ),
            ),
            tooltip: 'Account (${authProvider.studentName})',
            onSelected: (val) {
              if (val == 'logout') {
                authProvider.logout();
                context.go('/auth');
              } else if (val == 'switch') {
                context.go('/auth?tab=signin');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authProvider.studentName.isNotEmpty ? authProvider.studentName : 'Admin Account',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    ),
                    Text(
                      authProvider.currentUser?.email ?? 'nevents026@gmail.com',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'switch',
                child: Row(
                  children: [
                    Icon(Icons.switch_account, size: 18, color: Colors.cyan),
                    SizedBox(width: 8),
                    Text('Switch Account', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Active Events',
                    value: totalEvents.toString(),
                    icon: Icons.event,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Registrations',
                    value: totalRegistrations.toString(),
                    icon: Icons.people_outline,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Users & Logins',
                    value: totalUsersCount.toString(),
                    icon: Icons.account_circle_outlined,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    label: 'Create Event',
                    icon: Icons.add_circle_outline,
                    color: Colors.blue.shade700,
                    onTap: () => context.push('/admin/event-form'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    label: 'Home Banners',
                    icon: Icons.view_carousel_outlined,
                    color: Colors.amber.shade700,
                    onTap: () => context.push('/admin/banners'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    label: 'Staff Management',
                    icon: Icons.manage_accounts_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: () => context.push('/admin/staff'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    label: 'User Directory',
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () => context.push('/admin/users'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    label: 'All Users & Logins',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF0284C7),
                    onTap: () => context.push('/admin/users'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    label: 'Exit Panel',
                    icon: Icons.exit_to_app_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      authProvider.logout();
                      context.go('/auth');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Events List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Event Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '$totalEvents events',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Events Management list
            if (stateProvider.events.isEmpty)
              _buildEmptyEventsView(context)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stateProvider.events.length,
                itemBuilder: (context, index) {
                  final event = stateProvider.events[index];
                  final regCount = stateProvider.registrations.where((r) => r.eventId == event.id).length;
                  return _buildAdminEventCard(context, event, regCount, stateProvider);
                },
              ),
            
            SizedBox(height: 24),

            // Recent Registrations Feed
            Text(
              'Recent Registrations Feed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 12),
            if (recentRegs.isEmpty)
              _buildEmptyFeed()
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentRegs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final reg = recentRegs[index];
                    final event = stateProvider.events.firstWhere((e) => e.id == reg.eventId,
                      orElse: () => Event(
                        id: '', title: 'Deleted Event', description: '', bannerUrl: '',
                        dateTime: DateTime.now(), venue: '', category: '', coordinatorName: '', coordinatorPhone: ''
                      )
                    );
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        reg.fullName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                      subtitle: Text(
                        'Registered for ${event.title} • ${reg.rollNumber}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
                      ),
                      trailing: Text(
                        DateFormat('h:mm a').format(reg.registrationDate),
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminEventCard(
    BuildContext context,
    Event event,
    int regCount,
    AppStateProvider stateProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventDate = DateFormat('MMM d, yyyy • h:mm a').format(event.dateTime);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: UniversalImage(
            pathOrUrl: event.bannerUrl,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              eventDate,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: event.dateTime.isBefore(DateTime.now())
                        ? (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0))
                        : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.dateTime.isBefore(DateTime.now()) ? 'COMPLETED' : 'UPCOMING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: event.dateTime.isBefore(DateTime.now())
                          ? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B))
                          : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$regCount Registered',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.category,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.people_outline, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3C72), size: 20),
                tooltip: 'Participants',
                onPressed: () => context.push('/admin/participants/${event.id}'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.edit_outlined, color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey, size: 20),
                tooltip: 'Edit',
                onPressed: () => context.push('/admin/event-form?id=${event.id}'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                tooltip: 'Delete',
                onPressed: () => _confirmDeleteEvent(context, event.id, event.title, stateProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, String eventId, String title, AppStateProvider stateProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete "$title"? This will also delete all associated registrations and clear this event from home banners.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              stateProvider.deleteEvent(eventId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Event "$title" has been deleted.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEventsView(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
          SizedBox(height: 12),
          Text(
            'No events available',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => context.push('/admin/event-form'),
            icon: Icon(Icons.add, size: 16),
            label: Text('Post First Event', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3C72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No registrations recorded yet',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }
}
