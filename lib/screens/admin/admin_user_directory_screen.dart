import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../models/user_model.dart';
import '../../models/staff_assignment_model.dart';

class AdminUserDirectoryScreen extends StatefulWidget {
  const AdminUserDirectoryScreen({super.key});

  @override
  State<AdminUserDirectoryScreen> createState() => _AdminUserDirectoryScreenState();
}

class _AdminUserDirectoryScreenState extends State<AdminUserDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _copyCredentials(BuildContext context, UserModel user) {
    final text = 'Name: ${user.name}\nEmail: ${user.email}\nPassword: •••••••• (Protected / Hashed)\nRoll/ID: ${user.rollNumber}\nTicket Code: ${user.displayParticipantCode}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy_all_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Copied login & user details for ${user.name}'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showUserDetailsBottomSheet(BuildContext context, UserModel user, String subRole, bool isDark, AppStateProvider stateProvider, AuthProvider authProvider) {
    final userRegs = stateProvider.registrations.where((r) => r.rollNumber.toUpperCase() == user.rollNumber.toUpperCase() || r.fullName.toLowerCase() == user.name.toLowerCase()).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // User Title & Avatar
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: user.role == 'admin'
                          ? const Color(0xFF7C3AED)
                          : subRole.isNotEmpty
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF10B981),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name.isNotEmpty ? user.name : 'Registered User',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Account Credentials Block
                Text(
                  'LOGIN & CREDENTIALS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Login Email', user.email, Icons.email_outlined, isDark),
                      const SizedBox(height: 10),
                      _detailRow('Password Security', '•••••••• (Protected / Hashed)', Icons.lock_outline_rounded, isDark),
                      const SizedBox(height: 10),
                      _detailRow('10-Digit Code', user.displayParticipantCode, Icons.qr_code_2_rounded, isDark, isHighlight: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Student Profile Info Block
                Text(
                  'PROFILE & ACADEMIC DETAILS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Roll / ID No', user.rollNumber.isNotEmpty ? user.rollNumber : 'N/A', Icons.badge_outlined, isDark),
                      const SizedBox(height: 10),
                      _detailRow('Department', user.department, Icons.school_outlined, isDark),
                      const SizedBox(height: 10),
                      _detailRow('College', user.college, Icons.account_balance_outlined, isDark),
                      const SizedBox(height: 10),
                      _detailRow('Year of Study', user.year, Icons.calendar_today_outlined, isDark),
                      const SizedBox(height: 10),
                      _detailRow('Phone', user.phone.isNotEmpty ? user.phone : 'Not provided', Icons.phone_outlined, isDark),
                      const SizedBox(height: 10),
                      _detailRow('Gender / DOB', '${user.gender} • ${user.dob.isNotEmpty ? user.dob : "N/A"}', Icons.person_outline_rounded, isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Registrations Summary
                Text(
                  'EVENT REGISTRATIONS (${userRegs.length})',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                if (userRegs.isEmpty)
                  Text('No event registrations yet.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)))
                else
                  Column(
                    children: userRegs.map((r) {
                      final event = stateProvider.events.cast().firstWhere((e) => e.id == r.eventId, orElse: () => null);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                        title: Text(event?.title ?? r.eventId, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                        subtitle: Text('Status: ${r.status}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                // Approve as Coordinator / Staff Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showApproveRoleModal(context, user, stateProvider, authProvider);
                    },
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: Text(
                      subRole.isNotEmpty
                          ? 'Manage Staff Role (${SubRoles.label(subRole)})'
                          : 'Approve as Coordinator / Staff',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: subRole.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Copy Info Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _copyCredentials(context, user);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy All Credentials & Info', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Delete User Account Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteUser(context, user, stateProvider, authProvider);
                    },
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text('Delete User Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, UserModel user, AppStateProvider stateProvider, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User Account'),
        content: Text('Are you sure you want to delete account "${user.name}" (${user.email})? This action will remove the user profile from Supabase database and revoke all staff privileges.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await stateProvider.deleteUserAccount(user.id);
              await authProvider.deleteUserAccount(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User account "${user.name}" deleted successfully.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showApproveRoleModal(BuildContext context, UserModel user, AppStateProvider stateProvider, AuthProvider authProvider) {
    String selectedRole = user.subRole.isNotEmpty ? user.subRole : SubRoles.coordinator;
    String selectedDept = user.assignedDepartment.isNotEmpty ? user.assignedDepartment : user.department;
    List<String> selectedEventIds = List<String>.from(user.assignedEventIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Approve Staff Privilege for ${user.name}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assign staff role & sync to database profile',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Text('Select Staff Role:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SubRoles.all.map((role) {
                        final isSelected = selectedRole == role;
                        return ChoiceChip(
                          label: Text(SubRoles.label(role)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 12),
                          onSelected: (val) {
                            if (val) setSheet(() => selectedRole = role);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.verified_user_rounded, size: 18),
                        label: Text('Confirm & Approve as ${SubRoles.label(selectedRole)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await stateProvider.grantStaffRole(
                            user: user,
                            subRole: selectedRole,
                            assignedDepartment: selectedDept,
                            assignedEventIds: selectedEventIds,
                            grantedByAdminId: authProvider.currentUser?.id ?? '',
                          );
                          await authProvider.updateStaffRole(
                            userId: user.id,
                            subRole: selectedRole,
                            assignedDepartment: selectedDept,
                            assignedEventIds: selectedEventIds,
                          );
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 Approved ${user.name} as ${SubRoles.label(selectedRole)}! Data synced to database.'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value, IconData icon, bool isDark, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isHighlight ? const Color(0xFF10B981) : const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text('$label:', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isHighlight
                  ? const Color(0xFF10B981)
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final stateProvider = Provider.of<AppStateProvider>(context);

    final Map<String, UserModel> usersMap = {};
    if (authProvider.currentUser != null) {
      usersMap[authProvider.currentUser!.id] = authProvider.currentUser!;
    }
    for (final u in authProvider.registeredUsers) {
      usersMap[u.id] = u;
    }
    for (final u in stateProvider.dbProfiles) {
      usersMap[u.id] = u;
    }
    final allUsers = usersMap.values.toList();

    final students = allUsers.where((u) => u.role != 'admin' && u.subRole.isEmpty).toList();
    final staff = allUsers.where((u) => u.subRole.isNotEmpty || stateProvider.staffAssignments.any((s) => s.userId == u.id)).toList();
    final admins = allUsers.where((u) => u.role == 'admin').toList();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Registered Users & Login Details',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              '${allUsers.length} Total Registered Account${allUsers.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'All Accounts (${allUsers.length})'),
            Tab(text: 'Students (${students.length})'),
            Tab(text: 'Staff (${staff.length})'),
            Tab(text: 'Admins (${admins.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            color: isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by Name, Email, Roll No, Dept or Phone…',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Users List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserListView(allUsers, isDark, stateProvider),
                _buildUserListView(students, isDark, stateProvider),
                _buildUserListView(staff, isDark, stateProvider),
                _buildUserListView(admins, isDark, stateProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListView(List<UserModel> users, bool isDark, AppStateProvider stateProvider) {
    final filtered = users.where((u) {
      if (_searchQuery.isEmpty) return true;
      return u.name.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery) ||
          u.rollNumber.toLowerCase().contains(_searchQuery) ||
          u.department.toLowerCase().contains(_searchQuery) ||
          u.phone.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 64, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'No user accounts found matching your search',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = filtered[index];

        final assignment = stateProvider.staffAssignments.cast<StaffAssignment?>().firstWhere(
          (s) => s?.userId == user.id,
          orElse: () => null,
        );

        final effectiveSubRole = user.subRole.isNotEmpty ? user.subRole : (assignment?.subRole ?? '');

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: isDark ? 0 : 1,
          color: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showUserDetailsBottomSheet(context, user, effectiveSubRole, isDark, stateProvider, authProvider),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Avatar, Name, Badges, Action
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: user.role == 'admin'
                            ? const Color(0xFF7C3AED)
                            : effectiveSubRole.isNotEmpty
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF10B981),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name.isNotEmpty ? user.name : 'Registered User',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildRoleBadge(user.role, effectiveSubRole),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.rollNumber.isNotEmpty ? 'ID / Roll: ${user.rollNumber}' : 'Role: ${user.role.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_all_rounded, color: Color(0xFF64748B), size: 20),
                            tooltip: 'Copy Login Info',
                            onPressed: () => _copyCredentials(context, user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            tooltip: 'Delete User Account',
                            onPressed: () => _confirmDeleteUser(context, user, stateProvider, authProvider),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

                  // Credentials Box (Email & Password & Ticket Code)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Email Row
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 16, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 8),
                            const Text('Email / Login:', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                user.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Password Hash Row
                        const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                            SizedBox(width: 8),
                            Text('Password Hash:', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '•••••••••••• (Secured Hash)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Details Chips (10-digit ticket code, Department, Year, Phone)
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Code: ${user.displayParticipantCode}',
                        isDark: isDark,
                        isAccent: true,
                      ),
                      if (user.department.isNotEmpty)
                        _buildInfoChip(
                          icon: Icons.school_outlined,
                          label: user.department,
                          isDark: isDark,
                        ),
                      if (user.year.isNotEmpty)
                        _buildInfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: user.year,
                          isDark: isDark,
                        ),
                      if (user.phone.isNotEmpty)
                        _buildInfoChip(
                          icon: Icons.phone_outlined,
                          label: user.phone,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role, String subRole) {
    String text = 'STUDENT';
    Color bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
    Color textColor = const Color(0xFF059669);

    if (role == 'admin') {
      text = 'ADMIN';
      bgColor = const Color(0xFF7C3AED).withValues(alpha: 0.15);
      textColor = const Color(0xFF7C3AED);
    } else if (subRole.isNotEmpty) {
      text = subRole.toUpperCase().replaceAll('_', ' ');
      bgColor = const Color(0xFF2563EB).withValues(alpha: 0.15);
      textColor = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required bool isDark, bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAccent
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isAccent ? const Color(0xFF10B981) : const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isAccent ? FontWeight.bold : FontWeight.w500,
                color: isAccent
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
