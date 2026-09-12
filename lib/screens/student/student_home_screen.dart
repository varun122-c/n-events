import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../models/banner_model.dart';
import '../../widgets/universal_image.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final PageController _pageController = PageController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSearchFocused = false;
  bool _useBigPosterMode = false;

  final List<String> _categories = ['All', 'Technical', 'Cultural', 'Sports', 'Workshops'];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
      if (stateProvider.banners.isNotEmpty) {
        int nextIndex = _currentBannerIndex + 1;
        if (nextIndex >= stateProvider.banners.length) {
          nextIndex = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter and sort events (soonest upcoming events first)
    final filteredEvents = stateProvider.events.where((event) {
      final matchesSearch = event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.venue.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' || event.category == _selectedCategory;
      
      // Filter to only show future events on explore page
      final isFuture = event.dateTime.isAfter(DateTime.now().subtract(const Duration(hours: 24)));

      return matchesSearch && matchesCategory && isFuture;
    }).toList();

    // Sort by soonest time remaining (upcoming events starting soonest come first)
    filteredEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hello, ${authProvider.studentName.isNotEmpty ? authProvider.studentName : "Student"} 👋',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Discover campus events',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (authProvider.subRole.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF10B981)),
              tooltip: 'Go to Coordinator / Staff Portal',
              onPressed: () => context.go(authProvider.homeRoute),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
                tooltip: 'Notifications',
                onPressed: () => _showNotificationsBottomSheet(context, stateProvider),
              ),
              if (stateProvider.unreadNotificationsCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      stateProvider.unreadNotificationsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
            tooltip: 'Logout',
            onPressed: () {
              authProvider.logout();
              context.go('/auth');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Dynamic Banner Slider (Carousel)
            if (stateProvider.banners.isNotEmpty) ...[
              _buildBannerSlider(stateProvider.banners, isDark),
              const SizedBox(height: 16),
            ],

            // Animated Focus Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isSearchFocused || _searchQuery.isNotEmpty
                        ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                        : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                    width: _isSearchFocused || _searchQuery.isNotEmpty ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isSearchFocused || _searchQuery.isNotEmpty
                          ? (isDark
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                              : const Color(0xFF2563EB).withValues(alpha: 0.25))
                          : (isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04)),
                      blurRadius: _isSearchFocused || _searchQuery.isNotEmpty ? 16 : 10,
                      spreadRadius: _isSearchFocused || _searchQuery.isNotEmpty ? 2 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search hackathons, concerts, matches...',
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isSearchFocused ? Icons.search_outlined : Icons.search_rounded,
                        key: ValueKey(_isSearchFocused),
                        color: _isSearchFocused || _searchQuery.isNotEmpty
                            ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                            : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF94A3B8)),
                        size: 22,
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty || _isSearchFocused
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),

            // Live Search Banner Indicator when focused or typing
            if (_isSearchFocused || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E1B4B), const Color(0xFF311B92)]
                          : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.5) : const Color(0xFF93C5FD),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Showing upcoming events closing soonest (Big Poster Ads)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFE0E7FF) : const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF6366F1) : const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE AD MODE',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Category Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Categories',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildCategoryRow(isDark),

            const SizedBox(height: 20),

            // Event List Header & Mode Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isSearchFocused || _searchQuery.isNotEmpty ? 'Closing Soon (Ad Posters)' : 'Upcoming Events',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${filteredEvents.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  // Toggle button between Card view and Big Poster Ad view
                  InkWell(
                    onTap: () {
                      setState(() {
                        _useBigPosterMode = !_useBigPosterMode;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _useBigPosterMode || _isSearchFocused
                            ? (isDark ? const Color(0xFF2563EB).withValues(alpha: 0.2) : const Color(0xFFEFF6FF))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _useBigPosterMode || _isSearchFocused
                              ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _useBigPosterMode || _isSearchFocused ? Icons.view_carousel_rounded : Icons.view_agenda_outlined,
                            size: 16,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _useBigPosterMode || _isSearchFocused ? 'Ad Mode' : 'Standard',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Events List with Entrance Animation & Scale Effects
            if (filteredEvents.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  final showBigPoster = _useBigPosterMode || _isSearchFocused || _searchQuery.isNotEmpty;

                  return AnimatedEventCard(
                    key: ValueKey(event.id),
                    index: index,
                    onTap: () => context.push('/student/event/${event.id}'),
                    child: showBigPoster
                        ? _buildBigPosterAdCard(event, isDark, onTap: () => context.push('/student/event/${event.id}'))
                        : _buildEventCard(event, isDark),
                  );
                },
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Provider.of<AppStateProvider>(context, listen: false).setStudentTabIndex(2);
        },
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
        ),
        icon: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Image.asset('assets/images/n_ai_logo.jpg', fit: BoxFit.cover),
          ),
        ),
        label: Text(
          'N.ai',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSlider(List<BannerModel> banners, bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return GestureDetector(
                onTap: () {
                  if (banner.linkedEventId != null) {
                    context.push('/student/event/${banner.linkedEventId}');
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark ? Border.all(color: const Color(0xFF27272A), width: 1.5) : null,
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: UniversalImage(
                            pathOrUrl: banner.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark 
                                    ? [Colors.black.withValues(alpha: 0.88), Colors.black.withValues(alpha: 0.25), Colors.transparent]
                                    : [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                banner.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (banner.linkedEventId != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app_rounded, color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Tap to Register Now',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) {
              final isSelected = _currentBannerIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 22 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isSelected 
                      ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)) 
                      : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              selectedColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected 
                      ? Colors.transparent 
                      : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTimeLeftBadge(DateTime eventTime) {
    final now = DateTime.now();
    final diff = eventTime.difference(now);
    if (diff.isNegative) {
      return '⌛ LIVE NOW';
    } else if (diff.inHours < 1) {
      final mins = diff.inMinutes;
      return '⚡ STARTS IN $mins MINS!';
    } else if (diff.inHours < 24) {
      final hrs = diff.inHours;
      final mins = diff.inMinutes % 60;
      return '⚡ STARTS IN $hrs H $mins M!';
    } else if (diff.inDays < 7) {
      final days = diff.inDays;
      return '🔥 $days DAY${days > 1 ? 'S' : ''} LEFT!';
    } else {
      final weeks = (diff.inDays / 7).floor();
      return '📅 IN $weeks WEEK${weeks > 1 ? 'S' : ''}';
    }
  }

  Widget _buildBigPosterAdCard(Event event, bool isDark, {required VoidCallback onTap}) {
    final formattedDate = DateFormat('EEE, MMM d • h:mm a').format(event.dateTime);
    final timeLeftBadge = _getTimeLeftBadge(event.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Poster Header Banner with Gradient Overlay
            Stack(
              children: [
                Hero(
                  tag: 'event-poster-img-${event.id}',
                  child: UniversalImage(
                    pathOrUrl: event.bannerUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.9),
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                // Top Left: Dynamic Urgent Countdown Badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          timeLeftBadge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Top Right: Category & Ad Tag
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'AD • ${event.category.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Overlay Title & Date
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 8),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF38BDF8), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Poster Body Content & Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.reviews.isNotEmpty) ...[
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          (event.reviews.fold<double>(0, (prev, r) => prev + r.rating) / event.reviews.length).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF475569),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  // CTA & Entry Pass Row
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ENTRY PASS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'FREE ENTRY',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.flash_on_rounded, size: 14, color: Colors.white),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('EXPLORE POSTER ➔', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          backgroundColor: const Color(0xFF2563EB),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event, bool isDark) {
    final formattedDate = DateFormat('EEE, MMM d • h:mm a').format(event.dateTime);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'event-img-${event.id}',
                  child: UniversalImage(
                    pathOrUrl: event.bannerUrl,
                    height: 145,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
                    ),
                    child: Text(
                      event.category,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3C72),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.reviews.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${(event.reviews.fold<double>(0, (prev, r) => prev + r.rating) / event.reviews.length).toStringAsFixed(1)} (${event.reviews.length})',
                          style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
          SizedBox(height: 12),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try adjusting your search query or category filters.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, AppStateProvider stateProvider) {
    // Mark all as read when opening
    stateProvider.markAllNotificationsAsRead();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<AppStateProvider>(
          builder: (context, provider, child) {
            final notifs = provider.notifications;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Alerts & Feed',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                      if (notifs.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            provider.clearAllNotifications();
                          },
                          child: Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        )
                    ],
                  ),
                  SizedBox(height: 12),
                  if (notifs.isEmpty)
                    Container(
                      height: 180,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No notifications recorded yet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: ListView.separated(
                        itemCount: notifs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final n = notifs[index];
                          final timeStr = DateFormat('MMM d • h:mm a').format(n.timestamp);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(n.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(n.message, style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                SizedBox(height: 4),
                                Text(timeStr, style: TextStyle(fontSize: 9, color: Colors.blueGrey)),
                              ],
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                              ),
                            ),
                            onTap: n.linkedEventId != null ? () {
                              Navigator.pop(context); // Close bottom sheet
                              context.push('/student/event/${n.linkedEventId}');
                            } : null,
                          );
                        },
                      ),
                    )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AnimatedEventCard extends StatefulWidget {
  final Widget child;
  final int index;
  final VoidCallback onTap;

  const AnimatedEventCard({
    super.key,
    required this.child,
    required this.index,
    required this.onTap,
  });

  @override
  State<AnimatedEventCard> createState() => _AnimatedEventCardState();
}

class _AnimatedEventCardState extends State<AnimatedEventCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (widget.index * 60).clamp(0, 450)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final currentScale = _isPressed
            ? 0.96
            : (_isHovered ? 1.02 : 1.0);

        return Transform.translate(
          offset: Offset(0, (1 - value) * 28),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.diagonal3Values(currentScale, currentScale, 1.0),
                  transformAlignment: Alignment.center,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
