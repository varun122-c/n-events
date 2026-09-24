import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state_provider.dart';
import '../../models/event_model.dart';

class AdminCertificateCustomizerScreen extends StatefulWidget {
  const AdminCertificateCustomizerScreen({super.key});

  @override
  State<AdminCertificateCustomizerScreen> createState() =>
      _AdminCertificateCustomizerScreenState();
}

class _AdminCertificateCustomizerScreenState
    extends State<AdminCertificateCustomizerScreen> {
  String? _selectedEventId;
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _bodyTextController;
  late TextEditingController _sig1NameController;
  late TextEditingController _sig1RoleController;
  late TextEditingController _sig2NameController;
  late TextEditingController _sig2RoleController;
  late TextEditingController _canvaUrlController;

  String _selectedColorHex = '#FFD700';
  String _selectedBadgeStyle = 'Gold';
  bool _isSaving = false;

  final List<Map<String, String>> _themePalettes = [
    {'name': 'Gold', 'hex': '#FFD700'},
    {'name': 'Emerald', 'hex': '#059669'},
    {'name': 'Royal Blue', 'hex': '#2563EB'},
    {'name': 'Platinum', 'hex': '#94A3B8'},
    {'name': 'Crimson', 'hex': '#DC2626'},
  ];

  final List<String> _titlePresets = [
    'CERTIFICATE OF PARTICIPATION',
    'CERTIFICATE OF EXCELLENCE',
    'CERTIFICATE OF MERIT',
    'SPECIAL APPRECIATION AWARD',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _subtitleController = TextEditingController();
    _bodyTextController = TextEditingController();
    _sig1NameController = TextEditingController();
    _sig1RoleController = TextEditingController();
    _sig2NameController = TextEditingController();
    _sig2RoleController = TextEditingController();
    _canvaUrlController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppStateProvider>(context, listen: false);
      if (state.events.isNotEmpty) {
        _selectEvent(state.events.first.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _bodyTextController.dispose();
    _sig1NameController.dispose();
    _sig1RoleController.dispose();
    _sig2NameController.dispose();
    _sig2RoleController.dispose();
    _canvaUrlController.dispose();
    super.dispose();
  }

  void _selectEvent(String eventId) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final template = state.getCertificateTemplate(eventId);

    setState(() {
      _selectedEventId = eventId;
      _titleController.text = template.title;
      _subtitleController.text = template.subtitle;
      _bodyTextController.text = template.bodyText;
      _sig1NameController.text = template.signatoryName1;
      _sig1RoleController.text = template.signatoryRole1;
      _sig2NameController.text = template.signatoryName2;
      _sig2RoleController.text = template.signatoryRole2;
      _canvaUrlController.text = template.canvaUrl;
      _selectedColorHex = template.themeColorHex;
      _selectedBadgeStyle = template.badgeStyle;
    });
  }

  Color _getThemeColor(String hexStr) {
    try {
      final hex = hexStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFFFD700);
    }
  }

  Future<void> _saveTemplate() async {
    if (_selectedEventId == null || _selectedEventId!.isEmpty) return;
    setState(() => _isSaving = true);

    final state = Provider.of<AppStateProvider>(context, listen: false);
    final existing = state.getCertificateTemplate(_selectedEventId!);
    final updated = existing.copyWith(
      eventId: _selectedEventId,
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      bodyText: _bodyTextController.text.trim(),
      signatoryName1: _sig1NameController.text.trim(),
      signatoryRole1: _sig1RoleController.text.trim(),
      signatoryName2: _sig2NameController.text.trim(),
      signatoryRole2: _sig2RoleController.text.trim(),
      canvaUrl: _canvaUrlController.text.trim(),
      themeColorHex: _selectedColorHex,
      badgeStyle: _selectedBadgeStyle,
    );

    await state.saveCertificateTemplate(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Certificate Template Saved Successfully!'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  Future<void> _massPublishCertificates() async {
    if (_selectedEventId == null || _selectedEventId!.isEmpty) return;
    final state = Provider.of<AppStateProvider>(context, listen: false);

    await _saveTemplate();

    final count = await state.massPublishCertificates(_selectedEventId!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? '🏆 Published $count Certificates for participants!'
              : 'All participants already have published certificates!',
        ),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final events = stateProvider.events;
    final selectedThemeColor = _getThemeColor(_selectedColorHex);

    final selectedEvent = events.firstWhere(
      (e) => e.id == _selectedEventId,
      orElse: () => Event(
        id: '',
        title: 'Select an Event',
        description: '',
        bannerUrl: '',
        dateTime: DateTime.now(),
        venue: '',
        category: '',
        coordinatorName: '',
        coordinatorPhone: '',
      ),
    );

    final eventRegs = stateProvider.registrations
        .where((r) => r.eventId == _selectedEventId)
        .toList();
    final publishedCount = eventRegs.where((r) => r.isCertificatePublished).length;

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
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: selectedThemeColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'Certificate Customizer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveTemplate,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: events.isEmpty
          ? Center(
              child: Text(
                'No events created yet. Add an event to customize certificates.',
                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Selector Header Card
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF18181B) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Target Event',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedThemeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selectedThemeColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '$publishedCount / ${eventRegs.length} Published',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: selectedThemeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedEventId,
                            dropdownColor: isDark ? const Color(0xFF27272A) : Colors.white,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
                              prefixIcon: Icon(Icons.event_rounded, color: selectedThemeColor, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: events.map((e) {
                              return DropdownMenuItem(
                                value: e.id,
                                child: Text(e.title, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) _selectEvent(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LIVE CERTIFICATE PREVIEW CANVAS
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye_rounded, size: 18, color: selectedThemeColor),
                      const SizedBox(width: 6),
                      Text(
                        'Live Certificate Preview',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildCertificatePreviewCanvas(isDark, selectedEvent, selectedThemeColor),

                  const SizedBox(height: 24),

                  // TEMPLATE CUSTOMIZER FORM
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Customize Template Settings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Color Theme Selector
                  Text('Theme Color Accent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: _themePalettes.map((palette) {
                      final isSelected = _selectedColorHex == palette['hex'];
                      final color = _getThemeColor(palette['hex']!);
                      return ChoiceChip(
                        label: Text(palette['name']!),
                        selected: isSelected,
                        selectedColor: color.withValues(alpha: 0.25),
                        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? color : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        avatar: CircleAvatar(backgroundColor: color, radius: 6),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedColorHex = palette['hex']!;
                              _selectedBadgeStyle = palette['name']!;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Title Presets & Custom Title
                  Text('Certificate Main Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _titlePresets.map((preset) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(preset, style: const TextStyle(fontSize: 11)),
                            backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
                            onPressed: () {
                              setState(() => _titleController.text = preset);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration('Header Title', Icons.title_rounded, isDark),
                  ),

                  const SizedBox(height: 14),

                  // Subtitle & Body
                  TextField(
                    controller: _subtitleController,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration('Subtitle Header', Icons.subtitles_rounded, isDark),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _bodyTextController,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration('Body Description Text', Icons.description_rounded, isDark),
                  ),

                  const SizedBox(height: 20),

                  // Canva / Design URL Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Canva / Custom Design URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      if (_canvaUrlController.text.trim().isNotEmpty)
                        InkWell(
                          onTap: () async {
                            final uri = Uri.tryParse(_canvaUrlController.text.trim());
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C4CC).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00C4CC).withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF00C4CC)),
                                SizedBox(width: 4),
                                Text('Launch Canva', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00C4CC))),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _canvaUrlController,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration('e.g. https://www.canva.com/design/...', Icons.palette_rounded, isDark),
                  ),

                  const SizedBox(height: 20),

                  // Signatories
                  Text('Signatories Config', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sig1NameController,
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration('Signatory 1 Name', Icons.person_rounded, isDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _sig1RoleController,
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration('Signatory 1 Role', Icons.work_rounded, isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sig2NameController,
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration('Signatory 2 Name', Icons.person_outline_rounded, isDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _sig2RoleController,
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration('Signatory 2 Role', Icons.work_outline_rounded, isDark),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // MASS PUBLISH BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _massPublishCertificates,
                      icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                      label: Text(
                        'Publish Certificates for "${selectedEvent.title}"',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedThemeColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildCertificatePreviewCanvas(
      bool isDark, Event event, Color themeColor) {
    final issueDate = DateFormat('MMMM d, yyyy').format(event.dateTime);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFFAF6F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_rounded, color: themeColor, size: 56),
          const SizedBox(height: 8),
          Text(
            _titleController.text.isNotEmpty
                ? _titleController.text.toUpperCase()
                : 'CERTIFICATE OF PARTICIPATION',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitleController.text.isNotEmpty
                ? _subtitleController.text.toUpperCase()
                : 'PROUDLY PRESENTED TO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF8B5A2B),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'SAMPLE STUDENT NAME',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white : const Color(0xFF1E3C72),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: themeColor.withValues(alpha: 0.4), thickness: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            _bodyTextController.text.isNotEmpty
                ? _bodyTextController.text
                : 'for active and successful participation in the campus event',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.title.isNotEmpty ? event.title : 'Event Title Placeholder',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sig1NameController.text.isNotEmpty
                        ? _sig1NameController.text
                        : 'Dr. A. Sharma',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? themeColor : const Color(0xFF5C4033),
                    ),
                  ),
                  Text(
                    _sig1RoleController.text.isNotEmpty
                        ? _sig1RoleController.text
                        : 'Principal',
                    style: TextStyle(
                      fontSize: 8,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: $issueDate',
                    style: TextStyle(
                      fontSize: 8,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: themeColor, width: 1),
                    ),
                    child: QrImageView(
                      data: 'nEvents-Verify-Sample',
                      version: QrVersions.auto,
                      size: 50.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const Text('Credential ✅', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _sig2NameController.text.isNotEmpty
                        ? _sig2NameController.text
                        : 'Coordinator Name',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? themeColor : const Color(0xFF5C4033),
                    ),
                  ),
                  Text(
                    _sig2RoleController.text.isNotEmpty
                        ? _sig2RoleController.text
                        : 'Convener',
                    style: TextStyle(
                      fontSize: 8,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
