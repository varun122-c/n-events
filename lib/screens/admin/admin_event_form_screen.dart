import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_state_provider.dart';
import '../../models/event_model.dart';
import '../../widgets/universal_image.dart';

class AdminEventFormScreen extends StatefulWidget {
  final String? eventId;
  const AdminEventFormScreen({super.key, this.eventId});

  @override
  State<AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends State<AdminEventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _venueController;
  late TextEditingController _coordinatorNameController;
  late TextEditingController _coordinatorPhoneController;
  late TextEditingController _maxSeatsController;
  late TextEditingController _priceController;
  late TextEditingController _customBannerController;

  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  String _selectedCategory = 'Technical';
  String _selectedPosterUrl = 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&auto=format&fit=crop';
  bool _showCustomUrlField = false;

  List<SubEvent> _subEvents = [];

  final List<String> _categories = ['Technical', 'Cultural', 'Sports', 'Workshops'];

  final Map<String, List<Map<String, String>>> _posterGallery = {
    'Technical': [
      {'name': 'AI & Code Tech', 'url': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&auto=format&fit=crop'},
      {'name': 'Cyber & Hackathon', 'url': 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&auto=format&fit=crop'},
      {'name': 'Tech Workshop', 'url': 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&auto=format&fit=crop'},
    ],
    'Cultural': [
      {'name': 'Concert Stage', 'url': 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=800&auto=format&fit=crop'},
      {'name': 'Cultural Lights', 'url': 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop'},
      {'name': 'Dance & Music', 'url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&auto=format&fit=crop'},
    ],
    'Sports': [
      {'name': 'Stadium Arena', 'url': 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&auto=format&fit=crop'},
      {'name': 'Esports & Gaming', 'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800&auto=format&fit=crop'},
      {'name': 'Athletics Meet', 'url': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&auto=format&fit=crop'},
    ],
    'Workshops': [
      {'name': 'Keynote Hall', 'url': 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&auto=format&fit=crop'},
      {'name': 'Seminar Room', 'url': 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=800&auto=format&fit=crop'},
      {'name': 'Design Sprint', 'url': 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800&auto=format&fit=crop'},
    ],
  };

  final List<Map<String, String>> _subEventLogos = [
    {'name': 'Code Hackathon', 'category': 'Technical', 'url': 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&auto=format&fit=crop'},
    {'name': 'Robo Combat', 'category': 'Technical', 'url': 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800&auto=format&fit=crop'},
    {'name': 'Paper Presentation', 'category': 'Technical', 'url': 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800&auto=format&fit=crop'},
    {'name': 'Tech Quiz', 'category': 'Technical', 'url': 'https://images.unsplash.com/photo-1606326608606-aa0b62935f2b?w=800&auto=format&fit=crop'},
    {'name': 'Web Design', 'category': 'Technical', 'url': 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=800&auto=format&fit=crop'},
    {'name': 'Battle of Bands', 'category': 'Non-Technical', 'url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&auto=format&fit=crop'},
    {'name': 'Esports Arena', 'category': 'Non-Technical', 'url': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&auto=format&fit=crop'},
    {'name': 'Treasure Hunt', 'category': 'Non-Technical', 'url': 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=800&auto=format&fit=crop'},
    {'name': 'Reels & Photo', 'category': 'Non-Technical', 'url': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop'},
    {'name': 'Fashion Ramp', 'category': 'Non-Technical', 'url': 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&auto=format&fit=crop'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _venueController = TextEditingController();
    _coordinatorNameController = TextEditingController();
    _coordinatorPhoneController = TextEditingController();
    _maxSeatsController = TextEditingController(text: '100');
    _priceController = TextEditingController(text: '0');
    _customBannerController = TextEditingController();

    if (widget.eventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
        final eventIndex = stateProvider.events.indexWhere((e) => e.id == widget.eventId);
        if (eventIndex != -1) {
          final event = stateProvider.events[eventIndex];
          setState(() {
            _titleController.text = event.title;
            _descController.text = event.description;
            _selectedPosterUrl = event.bannerUrl;
            _customBannerController.text = event.bannerUrl;
            _venueController.text = event.venue;
            _coordinatorNameController.text = event.coordinatorName;
            _coordinatorPhoneController.text = event.coordinatorPhone;
            _maxSeatsController.text = event.maxSeats.toString();
            _priceController.text = event.price == 0 ? '0' : event.price.toStringAsFixed(0);
            _selectedDateTime = event.dateTime;
            _subEvents = List.from(event.subEvents);
            if (_categories.contains(event.category)) {
              _selectedCategory = event.category;
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _venueController.dispose();
    _coordinatorNameController.dispose();
    _coordinatorPhoneController.dispose();
    _maxSeatsController.dispose();
    _priceController.dispose();
    _customBannerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickMainImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _selectedPosterUrl = file.path;
          _customBannerController.text = file.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Poster selected from device gallery! ✓'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting gallery image: $e')),
        );
      }
    }
  }

  Future<void> _pickSubImageFromGallery(StateSetter setModalState, Function(String) onPicked) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setModalState(() {
          onPicked(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting sub-event image: $e')),
        );
      }
    }
  }

  void _openSubEventDialog([SubEvent? existingSubEvent, int? index]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCtrl = TextEditingController(text: existingSubEvent?.title ?? '');
    final priceCtrl = TextEditingController(text: existingSubEvent != null ? (existingSubEvent.price == 0 ? '0' : existingSubEvent.price.toStringAsFixed(0)) : '0');
    final detailsCtrl = TextEditingController(text: existingSubEvent?.details ?? '');
    final venueCtrl = TextEditingController(text: existingSubEvent?.venue ?? '');
    
    String subCategory = existingSubEvent?.category ?? 'Technical';
    String subImageUrl = existingSubEvent?.imageUrl.isNotEmpty == true 
        ? existingSubEvent!.imageUrl 
        : _subEventLogos.first['url']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          existingSubEvent == null ? Icons.add_box_rounded : Icons.edit_note_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          existingSubEvent == null ? 'Add Sub-Event' : 'Edit Sub-Event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sub Event Name
                    TextFormField(
                      controller: titleCtrl,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Sub-Event Name *',
                        hintText: 'e.g. Code Relay, Paper Presentation',
                        prefixIcon: const Icon(Icons.stars_rounded, color: Color(0xFF2563EB)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Toggle (Technical vs Non-Technical)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                subCategory = 'Technical';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: subCategory == 'Technical' 
                                    ? const Color(0xFF2563EB) 
                                    : (isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: subCategory == 'Technical' ? const Color(0xFF2563EB) : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.terminal_rounded, 
                                    size: 18, 
                                    color: subCategory == 'Technical' ? Colors.white : (isDark ? Colors.grey : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Technical',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: subCategory == 'Technical' ? Colors.white : (isDark ? Colors.grey : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                subCategory = 'Non-Technical';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: subCategory == 'Non-Technical' 
                                    ? const Color(0xFF8B5CF6) 
                                    : (isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: subCategory == 'Non-Technical' ? const Color(0xFF8B5CF6) : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.celebration_rounded, 
                                    size: 18, 
                                    color: subCategory == 'Non-Technical' ? Colors.white : (isDark ? Colors.grey : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Non-Technical',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: subCategory == 'Non-Technical' ? Colors.white : (isDark ? Colors.grey : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Price & Venue
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Price (₹) *',
                              hintText: '0 for Free',
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: venueCtrl,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Venue / Room',
                              hintText: 'e.g. Lab 302',
                              prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Sub-Event Image/Logo Picker Grid & Gallery Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sub-Event Image / Logo:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _pickSubImageFromGallery(setModalState, (path) {
                            subImageUrl = path;
                          }),
                          icon: const Icon(Icons.photo_library_rounded, size: 14, color: Color(0xFF2563EB)),
                          label: const Text('Pick Gallery Image', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _subEventLogos.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final logo = _subEventLogos[i];
                          final isSelected = subImageUrl == logo['url'];
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                subImageUrl = logo['url']!;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    UniversalImage(
                                      pathOrUrl: logo['url']!,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(color: Colors.black.withValues(alpha: 0.35)),
                                    Center(
                                      child: Text(
                                        logo['name']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Positioned(
                                        top: 3,
                                        right: 3,
                                        child: CircleAvatar(
                                          radius: 8,
                                          backgroundColor: Color(0xFF2563EB),
                                          child: Icon(Icons.check, size: 10, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Details & Rules
                    TextFormField(
                      controller: detailsCtrl,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Sub-Event Details / Rules',
                        hintText: 'e.g. 2 members per team, duration 45 mins...',
                        prefixIcon: const Icon(Icons.article_rounded, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter sub-event name')),
                                );
                                return;
                              }

                              final sub = SubEvent(
                                id: existingSubEvent?.id ?? const Uuid().v4(),
                                title: titleCtrl.text.trim(),
                                imageUrl: subImageUrl,
                                category: subCategory,
                                price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                                details: detailsCtrl.text.trim(),
                                venue: venueCtrl.text.trim(),
                              );

                              setState(() {
                                if (index != null && index >= 0 && index < _subEvents.length) {
                                  _subEvents[index] = sub;
                                } else {
                                  _subEvents.add(sub);
                                }
                              });

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              existingSubEvent == null ? 'Add Sub-Event' : 'Save Changes',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final stateProvider = Provider.of<AppStateProvider>(context, listen: false);

      String bannerUrl = _selectedPosterUrl;
      if (_showCustomUrlField && _customBannerController.text.trim().isNotEmpty) {
        bannerUrl = _customBannerController.text.trim();
      }

      final isEditMode = widget.eventId != null;
      final eventTitle = _titleController.text.trim();

      final event = Event(
        id: isEditMode ? widget.eventId! : const Uuid().v4(),
        title: eventTitle,
        description: _descController.text.trim(),
        bannerUrl: bannerUrl,
        dateTime: _selectedDateTime,
        venue: _venueController.text.trim(),
        category: _selectedCategory,
        coordinatorName: _coordinatorNameController.text.trim(),
        coordinatorPhone: _coordinatorPhoneController.text.trim(),
        maxSeats: int.tryParse(_maxSeatsController.text.trim()) ?? 100,
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        subEvents: _subEvents,
      );

      if (isEditMode) {
        stateProvider.updateEvent(event);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        // Add Event & Send Real-Time Push Notification to ALL Registered Users
        stateProvider.addEvent(event);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Event "$eventTitle" posted! Push notification sent to all students 📢'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/admin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.eventId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPosters = _posterGallery[_selectedCategory] ?? _posterGallery['Technical']!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        title: Row(
          children: [
            Icon(
              isEditMode ? Icons.edit_calendar_rounded : Icons.add_circle_outline_rounded,
              color: const Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEditMode ? 'Edit Campus Event' : 'Post New Campus Event',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Event Details Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                ),
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_note_rounded, color: Color(0xFF2563EB), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Main Event Overview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Event Name
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Event Name *',
                          hintText: 'e.g. Annual Tech Symposium 2026',
                          prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF2563EB)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter event title' : null,
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown & Main Price
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              dropdownColor: isDark ? const Color(0xFF27272A) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF8B5CF6)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCategory = val;
                                    _selectedPosterUrl = _posterGallery[val]!.first['url']!;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Price (₹)',
                                hintText: '0 for Free',
                                prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Event Description *',
                          hintText: 'Provide details about highlights, agenda, and guidelines...',
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF64748B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter event description' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Event Artwork & Poster Customization Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                ),
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.image_rounded, color: Color(0xFFEC4899), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Upload Main Event Poster / Logo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showCustomUrlField = !_showCustomUrlField;
                              });
                            },
                            icon: Icon(
                              _showCustomUrlField ? Icons.apps_rounded : Icons.link_rounded,
                              size: 16,
                            ),
                            label: Text(_showCustomUrlField ? 'Presets' : 'Custom URL'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Live Selected Image Preview
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              UniversalImage(
                                pathOrUrl: _showCustomUrlField && _customBannerController.text.trim().isNotEmpty
                                    ? _customBannerController.text.trim()
                                    : _selectedPosterUrl,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Active Main Poster',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Pick from Device Gallery Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pickMainImageFromGallery,
                          icon: const Icon(Icons.photo_library_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Upload Poster from Gallery 📱',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC4899),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_showCustomUrlField)
                        TextFormField(
                          controller: _customBannerController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Custom Poster / Logo URL',
                            hintText: 'https://images.unsplash.com/...',
                            prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFFEC4899)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (_) => setState(() {}),
                        )
                      else ...[
                        Text(
                          '1-Tap Poster Preset Choice ($_selectedCategory):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: currentPosters.length,
                          itemBuilder: (context, index) {
                            final poster = currentPosters[index];
                            final isSelected = _selectedPosterUrl == poster['url'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPosterUrl = poster['url']!;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      UniversalImage(
                                        pathOrUrl: poster['url']!,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        color: Colors.black.withValues(alpha: 0.3),
                                      ),
                                      Center(
                                        child: Text(
                                          poster['name']!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sub-Events Dynamic Section Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                ),
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_tree_rounded, color: Color(0xFF8B5CF6), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Sub-Events (${_subEvents.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openSubEventDialog(),
                            icon: const Icon(Icons.add, size: 16, color: Colors.white),
                            label: const Text('Add Sub-Event', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_subEvents.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.style_outlined, color: isDark ? Colors.grey : const Color(0xFF94A3B8), size: 32),
                              const SizedBox(height: 6),
                              Text(
                                'No Sub-Events added yet',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                'Click "+ Add Sub-Event" to create Technical or Non-Technical competitions',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF71717A) : const Color(0xFF94A3B8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _subEvents.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final sub = _subEvents[idx];
                            final isTech = sub.category == 'Technical';
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isTech 
                                      ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                                      : const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: UniversalImage(
                                      pathOrUrl: sub.imageUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                sub.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isTech ? const Color(0xFF2563EB) : const Color(0xFF8B5CF6),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                sub.category.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              sub.isFree ? 'FREE ENTRY' : '₹${sub.price.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: sub.isFree ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                              ),
                                            ),
                                            if (sub.venue.isNotEmpty) ...[
                                              const SizedBox(width: 10),
                                              Icon(Icons.location_on, size: 12, color: isDark ? Colors.grey : const Color(0xFF64748B)),
                                              const SizedBox(width: 2),
                                              Text(
                                                sub.venue,
                                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : const Color(0xFF64748B)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                                    onPressed: () => _openSubEventDialog(sub, idx),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                    onPressed: () {
                                      setState(() {
                                        _subEvents.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Date, Venue & Capacity Details Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                ),
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pin_drop_rounded, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Schedule & Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date & Time Picker Tile
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Event Date & Time',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('EEE, MMM dd, yyyy • hh:mm a').format(_selectedDateTime),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.edit_calendar_rounded, size: 18, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Venue & Max Seats
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _venueController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Venue / Auditorium *',
                                hintText: 'e.g. Main Auditorium',
                                prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Enter venue' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _maxSeatsController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Max Seats',
                                prefixIcon: const Icon(Icons.people_rounded, color: Color(0xFF8B5CF6)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Enter seats' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Coordinator Info Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                ),
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_pin_rounded, color: Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Event Coordinator Contact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _coordinatorNameController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Coordinator Name *',
                          hintText: 'e.g. Prof. R. Sharma',
                          prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFFF59E0B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter coordinator name' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _coordinatorPhoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Coordinator Phone Number *',
                          hintText: 'e.g. +91 9876543210',
                          prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF10B981)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter phone number' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saveEvent,
                  icon: Icon(
                    isEditMode ? Icons.save_rounded : Icons.send_rounded,
                    color: Colors.white,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isEditMode ? 'Update Event Changes' : 'Post Event & Broadcast Push Notification 📢',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 4,
                    shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
