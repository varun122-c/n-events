import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/staff_assignment_model.dart';
import '../../models/user_model.dart';
import '../../config/departments.dart';

class AdminStaffManagementScreen extends StatefulWidget {
  const AdminStaffManagementScreen({super.key});

  @override
  State<AdminStaffManagementScreen> createState() =>
      _AdminStaffManagementScreenState();
}

class _AdminStaffManagementScreenState
    extends State<AdminStaffManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _roleColors = {
    'organizer': Color(0xFF7C3AED),
    'coordinator': Color(0xFF2563EB),
    'tech_provider': Color(0xFFD97706),
    'scanner': Color(0xFF059669),
  };

  static const _roleIcons = {
    'organizer': Icons.folder_special_rounded,
    'coordinator': Icons.assignment_ind_rounded,
    'tech_provider': Icons.build_rounded,
    'scanner': Icons.qr_code_scanner_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateProvider = Provider.of<AppStateProvider>(context);
    final assignments = stateProvider.staffAssignments;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Staff Management',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              '${assignments.length} active staff member${assignments.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Assign New Staff Role',
            onPressed: () => _showAssignRoleSheet(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'All (${assignments.length})'),
            Tab(text: 'Organizers (${stateProvider.getStaffByRole('organizer').length})'),
            Tab(text: 'Coordinators (${stateProvider.getStaffByRole('coordinator').length})'),
            Tab(text: 'Tech (${stateProvider.getStaffByRole('tech_provider').length})'),
            Tab(text: 'Scanners (${stateProvider.getStaffByRole('scanner').length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search staff by name or email…',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
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
                fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStaffList(context, assignments, isDark),
                _buildStaffList(context, stateProvider.getStaffByRole('organizer'), isDark),
                _buildStaffList(context, stateProvider.getStaffByRole('coordinator'), isDark),
                _buildStaffList(context, stateProvider.getStaffByRole('tech_provider'), isDark),
                _buildStaffList(context, stateProvider.getStaffByRole('scanner'), isDark),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignRoleSheet(context),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Assign Role', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildStaffList(
      BuildContext context, List<StaffAssignment> list, bool isDark) {
    final filtered = _searchQuery.isEmpty
        ? list
        : list
            .where((s) =>
                s.userName.toLowerCase().contains(_searchQuery) ||
                s.userEmail.toLowerCase().contains(_searchQuery) ||
                s.userRollNumber.toLowerCase().contains(_searchQuery))
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off_rounded,
                size: 56, color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No staff match your search' : 'No staff assigned yet',
              style: TextStyle(
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8),
                  fontSize: 14),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showAssignRoleSheet(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Assign a role'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildStaffCard(context, filtered[index], isDark),
    );
  }

  Widget _buildStaffCard(BuildContext context, StaffAssignment s, bool isDark) {
    final color = _roleColors[s.subRole] ?? const Color(0xFF64748B);
    final icon = _roleIcons[s.subRole] ?? Icons.person_rounded;
    final stateProvider = Provider.of<AppStateProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.userName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                SubRoles.label(s.subRole),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(s.userEmail,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            if (s.userRollNumber.isNotEmpty)
              Text('Roll: ${s.userRollNumber}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            if (s.assignedDepartment.isNotEmpty)
              Text('Dept: ${s.assignedDepartment}',
                  style: TextStyle(fontSize: 11, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            if (s.assignedEventIds.isNotEmpty)
              Text('${s.assignedEventIds.length} event(s) assigned',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Assignment')),
            PopupMenuItem(
              value: 'revoke',
              child: Text('Revoke Role',
                  style: const TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
          onSelected: (action) async {
            if (action == 'revoke') {
              final confirm = await _confirmRevoke(context, s.userName);
              if (confirm == true) {
                await stateProvider.revokeStaffRole(s.userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${s.userName}\'s role revoked'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            } else if (action == 'edit') {
              _showAssignRoleSheet(context, existing: s);
            }
          },
        ),
      ),
    );
  }

  Future<bool?> _confirmRevoke(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Role?'),
        content: Text('Remove staff role from $name? They will be treated as a regular student.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  // ─── ASSIGN ROLE BOTTOM SHEET ──────────────────────────────────────────────

  void _showAssignRoleSheet(BuildContext context, {StaffAssignment? existing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final allUsers = authProvider.registeredUsers;

    UserModel? selectedUser = existing != null
        ? allUsers.cast<UserModel?>().firstWhere(
            (u) => u?.id == existing.userId,
            orElse: () => null)
        : null;
    String selectedRole = existing?.subRole ?? SubRoles.organizer;
    String selectedDept = existing?.assignedDepartment ?? '';
    List<String> selectedEventIds = List.from(existing?.assignedEventIds ?? []);
    final userSearchCtrl = TextEditingController();
    String userQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final filteredUsers = userQuery.isEmpty
                ? allUsers
                    .where((u) => u.role != 'admin')
                    .toList()
                : allUsers
                    .where((u) =>
                        u.role != 'admin' &&
                        (u.name.toLowerCase().contains(userQuery) ||
                            u.email.toLowerCase().contains(userQuery) ||
                            u.rollNumber.toLowerCase().contains(userQuery)))
                    .toList();

            return Container(
              height: MediaQuery.of(sheetCtx).size.height * 0.88,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Text(
                          existing != null ? 'Edit Assignment' : 'Assign Staff Role',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step 1: Select User
                          _sectionLabel('1. Select User', isDark),
                          const SizedBox(height: 8),
                          TextField(
                            controller: userSearchCtrl,
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13),
                            onChanged: (v) => setSheet(() => userQuery = v.toLowerCase()),
                            decoration: _sheetInputDecoration('Search by name, email, or roll…', isDark),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
                            ),
                            child: filteredUsers.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No registered users found.',
                                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: filteredUsers.length,
                                    itemBuilder: (_, i) {
                                      final u = filteredUsers[i];
                                      final isSelected = selectedUser?.id == u.id;
                                      return ListTile(
                                        dense: true,
                                        selected: isSelected,
                                        selectedTileColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                        onTap: () => setSheet(() => selectedUser = u),
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isSelected
                                              ? const Color(0xFF2563EB)
                                              : (isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
                                          child: Text(
                                            u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        title: Text(u.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            )),
                                        subtitle: Text(u.email,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                        trailing: isSelected
                                            ? const Icon(Icons.check_circle_rounded,
                                                color: Color(0xFF2563EB), size: 18)
                                            : null,
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 20),

                          // Step 2: Select Sub-Role
                          _sectionLabel('2. Select Role', isDark),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              SubRoles.organizer,
                              SubRoles.coordinator,
                              SubRoles.techProvider,
                              SubRoles.scanner,
                            ].map((role) {
                              final isSelected = selectedRole == role;
                              final color = _roleColors[role]!;
                              final icon = _roleIcons[role]!;
                              return GestureDetector(
                                onTap: () => setSheet(() => selectedRole = role),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color : color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? color : color.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, size: 16, color: isSelected ? Colors.white : color),
                                      const SizedBox(width: 6),
                                      Text(
                                        SubRoles.label(role),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? Colors.white : color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Step 3: Role-Specific Config
                          if (selectedRole == SubRoles.organizer) ...[
                            _sectionLabel('3. Assigned Department', isDark),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedDept.isEmpty ? null : selectedDept,
                              hint: const Text('Select department…',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13),
                              dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                              items: AitsDepartments.allDepartments
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (v) => setSheet(() => selectedDept = v ?? ''),
                            ),
                          ],

                          if (selectedRole == SubRoles.coordinator ||
                              selectedRole == SubRoles.scanner ||
                              selectedRole == SubRoles.techProvider) ...[
                            _sectionLabel('3. Assign Events', isDark),
                            const SizedBox(height: 8),
                            ...stateProvider.events.map((event) {
                              final isAssigned = selectedEventIds.contains(event.id);
                              return CheckboxListTile(
                                dense: true,
                                value: isAssigned,
                                activeColor: const Color(0xFF2563EB),
                                title: Text(event.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    )),
                                subtitle: Text(event.category,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                onChanged: (v) {
                                  setSheet(() {
                                    if (v == true) {
                                      selectedEventIds.add(event.id);
                                    } else {
                                      selectedEventIds.remove(event.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ],
                          const SizedBox(height: 24),

                          // Confirm Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: selectedUser == null
                                  ? null
                                  : () async {
                                      await stateProvider.grantStaffRole(
                                        user: selectedUser!,
                                        subRole: selectedRole,
                                        assignedDepartment: selectedDept,
                                        assignedEventIds: selectedEventIds,
                                        grantedByAdminId: authProvider.currentUser?.id ?? '',
                                      );
                                      await authProvider.updateStaffRole(
                                        userId: selectedUser!.id,
                                        subRole: selectedRole,
                                        assignedDepartment: selectedDept,
                                        assignedEventIds: selectedEventIds,
                                      );
                                      if (sheetCtx.mounted) {
                                        Navigator.pop(sheetCtx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${selectedUser!.name} assigned as ${SubRoles.label(selectedRole)}',
                                            ),
                                            backgroundColor: const Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: Text(
                                existing != null ? 'Update Assignment' : 'Confirm & Assign Role',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        letterSpacing: 0.6,
      ),
    );
  }

  InputDecoration _sheetInputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF6B7280)),
      filled: true,
      fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    );
  }
}
