import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_state_provider.dart';
import '../../models/banner_model.dart';
import '../../widgets/universal_image.dart';

class AdminBannerCustomizerScreen extends StatelessWidget {
  const AdminBannerCustomizerScreen({super.key});

  static const List<Map<String, String>> _bannerPresets = [
    {
      'title': 'Grand Tech Fest 2026',
      'url': 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200&auto=format&fit=crop',
    },
    {
      'title': 'Cultural Night Extravaganza',
      'url': 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200&auto=format&fit=crop',
    },
    {
      'title': 'Annual Sports Championship',
      'url': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=1200&auto=format&fit=crop',
    },
    {
      'title': 'AI & Robotics Workshop',
      'url': 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1200&auto=format&fit=crop',
    },
    {
      'title': 'Hackathon Challenge Live',
      'url': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=1200&auto=format&fit=crop',
    },
    {
      'title': 'Music Fest & DJ Concert',
      'url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1200&auto=format&fit=crop',
    },
  ];

  void _showBannerFormDialog(BuildContext context, {BannerModel? banner}) {
    final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleController = TextEditingController(text: banner?.title ?? '');
    final imageUrlController = TextEditingController(text: banner?.imageUrl ?? _bannerPresets[0]['url']!);
    String? selectedLinkedEventId = banner?.linkedEventId;
    bool showCustomUrl = false;

    if (selectedLinkedEventId != null &&
        !stateProvider.events.any((e) => e.id == selectedLinkedEventId)) {
      selectedLinkedEventId = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            const Icon(Icons.view_carousel_rounded, color: Color(0xFF2563EB), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                banner == null ? 'Add Home Banner Slide' : 'Edit Banner Details',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleController,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Banner Title / Headline *',
                        labelStyle: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B), fontSize: 12),
                        hintText: 'e.g. Annual Campus Fest is Live!',
                        prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF2563EB), size: 18),
                        filled: true,
                        fillColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Choose Banner Poster Image:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setDialogState(() => showCustomUrl = !showCustomUrl),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          child: Text(
                            showCustomUrl ? 'Hide Custom URL' : 'Custom Link',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Visual 1-Tap Banner Choices Gallery
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: _bannerPresets.length,
                      itemBuilder: (context, idx) {
                        final preset = _bannerPresets[idx];
                        final isSelected = imageUrlController.text.trim() == preset['url'];

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              imageUrlController.text = preset['url']!;
                              if (titleController.text.isEmpty) {
                                titleController.text = preset['title']!;
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.4), blurRadius: 6)]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  UniversalImage(pathOrUrl: preset['url']!, fit: BoxFit.cover),
                                  Container(color: Colors.black.withValues(alpha: 0.3)),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Text(
                                        preset['title']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 3,
                                      right: 3,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 10),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // Pick Banner from Gallery Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final picker = ImagePicker();
                            final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                            if (file != null) {
                              setDialogState(() {
                                imageUrlController.text = file.path;
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error picking banner image: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.photo_library_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Upload Banner from Device Gallery 📱',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                      ),
                    ),

                    if (showCustomUrl) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: imageUrlController,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Custom Banner Image URL',
                          labelStyle: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B), fontSize: 12),
                          prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF2563EB), size: 18),
                          filled: true,
                          fillColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        onChanged: (val) => setDialogState(() {}),
                      ),
                    ],

                    if (imageUrlController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              UniversalImage(
                                pathOrUrl: imageUrlController.text.trim(),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'LIVE SLIDE PREVIEW',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String?>(
                      initialValue: selectedLinkedEventId,
                      dropdownColor: isDark ? const Color(0xFF18181B) : Colors.white,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Link to Event (Optional)',
                        labelStyle: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B), fontSize: 12),
                        prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF2563EB), size: 18),
                        filled: true,
                        fillColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No link (Static Promotion)', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                        ),
                        ...stateProvider.events.map((e) => DropdownMenuItem<String?>(
                              value: e.id,
                              child: SizedBox(
                                width: 180,
                                child: Text(
                                  e.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                                ),
                              ),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedLinkedEventId = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final String imgUrl = imageUrlController.text.trim();

                if (banner == null) {
                  final newBanner = BannerModel(
                    id: const Uuid().v4(),
                    title: titleController.text.trim(),
                    imageUrl: imgUrl,
                    linkedEventId: selectedLinkedEventId,
                    displayOrder: stateProvider.banners.length,
                  );
                  stateProvider.addBanner(newBanner);
                } else {
                  final updatedBanner = banner.copyWith(
                    title: titleController.text.trim(),
                    imageUrl: imgUrl,
                    linkedEventId: selectedLinkedEventId,
                  );
                  stateProvider.updateBanner(updatedBanner);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(banner == null ? 'Banner slide added!' : 'Banner slide updated!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Banner', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Home Banner Customizer',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            Text(
              'Manage and reorder student homepage carousel slides',
              style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showBannerFormDialog(context),
              icon: const Icon(Icons.add_a_photo_rounded, size: 16, color: Colors.white),
              label: const Text('Add Banner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFEFF6FF),
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFDBEAFE))),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag and reorder slides using the right handle. Changes update instantly on the student app homepage carousel.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: stateProvider.banners.isEmpty
                ? _buildEmptyState(context)
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: stateProvider.banners.length,
                    onReorderItem: (oldIndex, newIndex) {
                      stateProvider.reorderBanners(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final banner = stateProvider.banners[index];
                      String linkLabel = 'Static Promo (No Event Link)';
                      if (banner.linkedEventId != null) {
                        final eventIndex = stateProvider.events.indexWhere((e) => e.id == banner.linkedEventId);
                        if (eventIndex != -1) {
                          linkLabel = 'Links to: ${stateProvider.events[eventIndex].title}';
                        } else {
                          linkLabel = 'Linked event missing';
                        }
                      }

                      return Card(
                        key: ValueKey(banner.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                        ),
                        color: isDark ? const Color(0xFF18181B) : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: UniversalImage(
                                pathOrUrl: banner.imageUrl,
                                width: 70,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(
                            banner.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Slide #${index + 1}',
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      linkLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: banner.linkedEventId != null
                                            ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8))
                                            : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
                                        fontWeight: banner.linkedEventId != null ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                  icon: Icon(Icons.edit_outlined, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), size: 20),
                                  onPressed: () => _showBannerFormDialog(context, banner: banner),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    _confirmDeleteBanner(context, banner.id, banner.title, stateProvider);
                                  },
                                ),
                                const Icon(Icons.drag_handle_rounded, color: Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBannerFormDialog(context),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Banner Slide', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmDeleteBanner(BuildContext context, String bannerId, String title, AppStateProvider stateProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark ? const BorderSide(color: Color(0xFF27272A)) : BorderSide.none,
        ),
        title: Text('Delete Banner Slide', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        content: Text('Are you sure you want to delete the banner slide "$title"?', style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              stateProvider.deleteBanner(bannerId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Banner slide "$title" deleted.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_carousel_outlined, size: 64, color: isDark ? const Color(0xFF27272A) : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Home Banner Slides',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Text(
            'Add featured banners to show on the student home page.',
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
