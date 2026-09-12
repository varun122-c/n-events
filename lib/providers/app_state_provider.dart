import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import '../models/banner_model.dart';
import '../models/review_model.dart';
import '../models/notification_model.dart';
import '../models/chat_message_model.dart';
import '../models/staff_assignment_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/supabase_db_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppStateProvider extends ChangeNotifier {
  // ─── SharedPrefs cache keys ──────────────────────────────────────────────
  static const String _keyEvents = 'app_events';
  static const String _keyRegistrations = 'app_registrations';
  static const String _keyBanners = 'app_banners';
  static const String _keyNotifications = 'app_notifications';
  static const String _keyChatMessages = 'app_chat_messages';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyStaffAssignments = 'app_staff_assignments';
  // Bump this version string whenever mock data must be cleared from the cache
  static const String _cacheVersion = 'v2_no_mock';
  static const String _keyCacheVersion = 'app_cache_version';


  final _uuid = const Uuid();

  List<Event> _events = [];
  List<Registration> _registrations = [];
  List<BannerModel> _banners = [];
  List<NotificationModel> _notifications = [];
  List<ChatMessageModel> _chatMessages = [];
  List<StaffAssignment> _staffAssignments = [];
  List<UserModel> _dbProfiles = [];
  List<UserModel> get dbProfiles => List.unmodifiable(_dbProfiles);

  bool _isSimulationActive = false;
  Timer? _simulationTimer;
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  int _studentTabIndex = 0;
  int get studentTabIndex => _studentTabIndex;

  // ─── Realtime subscriptions ──────────────────────────────────────────────
  RealtimeChannel? _eventsChannel;
  RealtimeChannel? _registrationsChannel;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _chatChannel;

  void setStudentTabIndex(int index) {
    if (_studentTabIndex != index) {
      _studentTabIndex = index;
      notifyListeners();
    }
  }

  List<Event> get events => _events;
  List<Registration> get registrations => _registrations;
  List<BannerModel> get banners => _banners;
  List<NotificationModel> get notifications => _notifications;
  List<ChatMessageModel> get chatMessages => _chatMessages;
  List<StaffAssignment> get staffAssignments =>
      List.unmodifiable(_staffAssignments);
  bool get isSimulationActive => _isSimulationActive;

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  AppStateProvider() {
    _initData();
  }

  // ─── INITIALISATION ──────────────────────────────────────────────────────

  Future<void> _initData() async {
    // 1. Load local cache first so UI is immediately responsive
    await _loadFromLocalCache();

    // 2. Then fetch fresh data from Supabase and update
    await _fetchFromSupabase();

    // 3. Subscribe to realtime changes
    _subscribeRealtime();

    // 4. Initialize Local Notifications plugin
    await _initLocalNotifications();

    // Load theme preference
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_keyThemeMode) ?? 'system';
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> _loadFromLocalCache() async {
    final prefs = await SharedPreferences.getInstance();

    // ── One-time cache migration: clear old mock data ─────────────────────
    if (prefs.getString(_keyCacheVersion) != _cacheVersion) {
      await prefs.remove(_keyEvents);
      await prefs.remove(_keyRegistrations);
      await prefs.remove(_keyBanners);
      await prefs.setString(_keyCacheVersion, _cacheVersion);
    }

    if (prefs.containsKey(_keyEvents)) {
      try {
        final decoded = jsonDecode(prefs.getString(_keyEvents)!) as List<dynamic>;
        _events = decoded.map((i) => Event.fromJson(i)).toList();
      } catch (_) {}
    }
    // No mock fallback — start empty, Supabase will populate

    if (prefs.containsKey(_keyRegistrations)) {
      try {
        final decoded =
            jsonDecode(prefs.getString(_keyRegistrations)!) as List<dynamic>;
        _registrations = decoded.map((i) => Registration.fromJson(i)).toList();
      } catch (_) {}
    }

    if (prefs.containsKey(_keyBanners)) {
      try {
        final decoded =
            jsonDecode(prefs.getString(_keyBanners)!) as List<dynamic>;
        _banners = decoded.map((i) => BannerModel.fromJson(i)).toList();
      } catch (_) {}
    }

    if (prefs.containsKey(_keyNotifications)) {
      try {
        final decoded =
            jsonDecode(prefs.getString(_keyNotifications)!) as List<dynamic>;
        _notifications =
            decoded.map((i) => NotificationModel.fromJson(i)).toList();
      } catch (_) {}
    }

    if (prefs.containsKey(_keyChatMessages)) {
      try {
        final decoded =
            jsonDecode(prefs.getString(_keyChatMessages)!) as List<dynamic>;
        _chatMessages =
            decoded.map((i) => ChatMessageModel.fromJson(i)).toList();
      } catch (_) {
        _chatMessages = [];
      }
    }

    if (prefs.containsKey(_keyStaffAssignments)) {
      try {
        final decoded =
            jsonDecode(prefs.getString(_keyStaffAssignments)!) as List<dynamic>;
        _staffAssignments = decoded
            .map((i) =>
                StaffAssignment.fromMap(i as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    _banners.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    notifyListeners();
  }

  Future<void> _fetchFromSupabase() async {
    if (!SupabaseService.isInitialized) return;

    try {
      // Fetch events from Supabase server
      final sbEvents = await SupabaseDbService.fetchEvents();
      _events = sbEvents;
      await _saveEvents();
    } catch (e) {
      debugPrint('Supabase fetch events error: $e');
    }

    try {
      // Fetch registrations from Supabase server
      final sbRegs = await SupabaseDbService.fetchAllRegistrations();
      _registrations = sbRegs;
      await _saveRegistrations();
    } catch (e) {
      debugPrint('Supabase fetch registrations error: $e');
    }

    try {
      // Fetch banners from Supabase server
      final sbBanners = await SupabaseDbService.fetchBanners();
      _banners = sbBanners;
      await _saveBanners();
    } catch (e) {
      debugPrint('Supabase fetch banners error: $e');
    }

    try {
      // Fetch staff assignments from Supabase server
      final sbStaff = await SupabaseDbService.fetchStaffAssignments();
      _staffAssignments = sbStaff;
      await _saveStaffAssignments();
    } catch (e) {
      debugPrint('Supabase fetch staff assignments error: $e');
    }

    try {
      // Fetch user profiles from Supabase server database
      final profiles = await SupabaseDbService.fetchAllProfiles();
      _dbProfiles = profiles;
    } catch (e) {
      debugPrint('Supabase fetch profiles error: $e');
    }

    // Fetch notifications for current user from Supabase server
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      try {
        final sbNotifs =
            await SupabaseDbService.fetchNotifications(currentUser.id);
        _notifications = sbNotifs;
        await _saveNotifications();
      } catch (e) {
        debugPrint('Supabase fetch notifications error: $e');
      }
    }

    try {
      final sbChats = await SupabaseDbService.fetchAllChatMessages();
      _chatMessages = sbChats;
      await _saveChatMessages();
    } catch (e) {
      debugPrint('Supabase fetch chat messages error: $e');
    }

    _banners.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    notifyListeners();
  }

  void _subscribeRealtime() {
    if (!SupabaseService.isInitialized) return;

    // Subscribe to events table
    _eventsChannel = SupabaseDbService.subscribeToEvents(
      onData: (events) {
        _events = events;
        _saveEvents();
        notifyListeners();
      },
    );

    // Subscribe to registrations table
    _registrationsChannel = SupabaseDbService.subscribeToRegistrations(
      onData: (regs) {
        _registrations = regs;
        _saveRegistrations();
        notifyListeners();
      },
    );

    // Subscribe to all chat messages table for real-time status
    _chatChannel = SupabaseDbService.subscribeToAllChatMessages(
      onData: (msgs) {
        _chatMessages = msgs;
        _saveChatMessages();
        notifyListeners();
      },
    );

    // Subscribe to notifications for current user
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      _notificationsChannel = SupabaseDbService.subscribeToNotifications(
        userId: currentUser.id,
        onData: (notifs) {
          _notifications = notifs;
          _saveNotifications();
          notifyListeners();
        },
      );
    }
  }

  /// Refresh all data from Supabase (can be called manually on pull-to-refresh).
  Future<void> refreshFromSupabase() async {
    await _fetchFromSupabase();
  }

  // ─── SAVE METHODS (local cache) ──────────────────────────────────────────

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyEvents, jsonEncode(_events.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveRegistrations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyRegistrations,
        jsonEncode(_registrations.map((r) => r.toJson()).toList()));
  }

  Future<void> _saveBanners() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyBanners, jsonEncode(_banners.map((b) => b.toJson()).toList()));
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyNotifications,
        jsonEncode(_notifications.map((n) => n.toJson()).toList()));
  }

  Future<void> _saveChatMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyChatMessages,
        jsonEncode(_chatMessages.map((c) => c.toJson()).toList()));
  }

  Future<void> _saveStaffAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyStaffAssignments,
        jsonEncode(_staffAssignments.map((s) => s.toMap()).toList()));
  }

  // ─── EVENT CRUD ──────────────────────────────────────────────────────────

  Future<void> addEvent(Event event) async {
    _events.add(event);
    await _saveEvents();

    // Write to Supabase
    await SupabaseDbService.insertEvent(event);

    // Auto-add to Home Page Banners Carousel!
    final autoBanner = BannerModel(
      id: _uuid.v4(),
      title: event.title,
      imageUrl: event.bannerUrl,
      linkedEventId: event.id,
      displayOrder: _banners.length,
    );
    await addBanner(autoBanner);

    await addNotification(
      '📢 New Campus Event Posted!',
      '"${event.title}" is now open for registrations. Check event details & book your pass.',
      linkedEventId: event.id,
    );

    notifyListeners();
  }

  Future<void> updateEvent(Event updatedEvent) async {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      await _saveEvents();
      // Write to Supabase
      await SupabaseDbService.updateEvent(updatedEvent);
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    _registrations.removeWhere((r) => r.eventId == id);
    _chatMessages.removeWhere((c) => c.eventId == id);
    for (int i = 0; i < _banners.length; i++) {
      if (_banners[i].linkedEventId == id) {
        _banners[i] = _banners[i].copyWith(linkedEventId: null);
      }
    }
    _notifications.removeWhere((n) => n.linkedEventId == id);

    await _saveEvents();
    await _saveRegistrations();
    await _saveBanners();
    await _saveNotifications();
    await _saveChatMessages();

    // Delete from Supabase (cascade handles registrations/chat)
    await SupabaseDbService.deleteEvent(id);

    notifyListeners();
  }

  // ─── REGISTRATION ACTIONS ────────────────────────────────────────────────

  Future<bool> registerForEvent({
    required String eventId,
    required String fullName,
    required String rollNumber,
    required String department,
    String college =
        'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
    required String yearOfStudy,
    required String phoneNumber,
    String? userId,
  }) async {
    // Check if already registered locally
    final alreadyRegistered = _registrations.any(
      (r) =>
          r.eventId == eventId &&
          r.rollNumber.toLowerCase() == rollNumber.toLowerCase(),
    );

    if (alreadyRegistered) return false;

    final newReg = Registration(
      id: _uuid.v4(),
      eventId: eventId,
      fullName: fullName,
      rollNumber: rollNumber,
      department: department,
      college: college,
      yearOfStudy: yearOfStudy,
      phoneNumber: phoneNumber,
      registrationDate: DateTime.now(),
      status: 'Registered',
    );

    _registrations.add(newReg);
    await _saveRegistrations();

    // Write to Supabase
    final currentUserId = userId ?? SupabaseService.currentUser?.id;
    await SupabaseDbService.insertRegistration(newReg, userId: currentUserId);

    // Trigger notification
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex != -1) {
      final ticketCode = (currentUserId != null && currentUserId.isNotEmpty)
          ? UserModel.generate10DigitParticipantCode(currentUserId)
          : UserModel.generate10DigitParticipantCode(rollNumber);
      await addNotification(
        '🎉 Booking Confirmed!',
        'Successfully registered for "${_events[eventIndex].title}". Your 10-digit ticket pass code is $ticketCode.',
        linkedEventId: eventId,
        userId: currentUserId,
      );
    }

    notifyListeners();
    return true;
  }

  Future<void> updateRegistrationStatus(
    String regId,
    String newStatus, {
    String? verifiedBy,
    bool? isCertificatePublished,
  }) async {
    final index = _registrations.indexWhere((r) => r.id == regId);
    if (index != -1) {
      final oldReg = _registrations[index];
      final isCheckingIn = newStatus == 'Checked In' || newStatus == 'Attended';
      final updatedReg = oldReg.copyWith(
        status: newStatus,
        verifiedBy: isCheckingIn ? (verifiedBy ?? oldReg.verifiedBy ?? 'Campus Coordinator') : oldReg.verifiedBy,
        verifiedAt: isCheckingIn ? (oldReg.verifiedAt ?? DateTime.now()) : oldReg.verifiedAt,
        isCertificatePublished: isCertificatePublished ?? oldReg.isCertificatePublished,
      );
      _registrations[index] = updatedReg;
      await _saveRegistrations();

      // Update in Supabase
      await SupabaseDbService.updateRegistrationDetails(updatedReg);

      final eventIndex = _events.indexWhere((e) => e.id == oldReg.eventId);
      if (eventIndex != -1) {
        final eventTitle = _events[eventIndex].title;
        if (isCheckingIn) {
          await addNotification(
            'Attendance Certified!',
            'Your attendance for "$eventTitle" has been verified by ${updatedReg.verifiedBy}. Access your digital pass now!',
            linkedEventId: oldReg.eventId,
          );
        } else if (newStatus == 'Cancelled') {
          await addNotification(
            'Registration Cancelled',
            'Registration for "$eventTitle" has been cancelled.',
            linkedEventId: oldReg.eventId,
          );
        }
      }
      notifyListeners();
    }
  }

  Future<void> publishCertificate(String regId) async {
    final index = _registrations.indexWhere((r) => r.id == regId);
    if (index != -1) {
      final oldReg = _registrations[index];
      final updatedReg = oldReg.copyWith(
        status: 'Attended',
        isCertificatePublished: true,
      );
      _registrations[index] = updatedReg;
      await _saveRegistrations();

      // Update in Supabase
      await SupabaseDbService.updateRegistrationDetails(updatedReg);

      final eventIndex = _events.indexWhere((e) => e.id == oldReg.eventId);
      if (eventIndex != -1) {
        final eventTitle = _events[eventIndex].title;
        await addNotification(
          '🎉 Certificate Published!',
          'Your official digital certificate for "$eventTitle" has been published by Admin and is now downloadable in your Certificates tab!',
          linkedEventId: oldReg.eventId,
        );
      }
      notifyListeners();
    }
  }

  // ─── REVIEWS & RATINGS ───────────────────────────────────────────────────

  Future<void> addReview(
    String eventId,
    String studentName,
    double rating,
    String comment,
  ) async {
    final review = Review(
      id: _uuid.v4(),
      eventId: eventId,
      studentName: studentName,
      rating: rating,
      comment: comment,
      date: DateTime.now(),
    );

    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex != -1) {
      final List<Review> updatedReviews =
          List.from(_events[eventIndex].reviews)..add(review);
      _events[eventIndex] =
          _events[eventIndex].copyWith(reviews: updatedReviews);
      await _saveEvents();
      // Update reviews in Supabase (stored as JSONB on the event row)
      await SupabaseDbService.updateEvent(_events[eventIndex]);
      notifyListeners();
    }
  }

  // ─── COORDINATOR CHATS ───────────────────────────────────────────────────

  Future<void> sendChatMessage(
    String eventId,
    String studentRoll,
    String studentName,
    String senderRole,
    String text,
  ) async {
    final msg = ChatMessageModel(
      id: _uuid.v4(),
      eventId: eventId,
      studentRoll: studentRoll,
      studentName: studentName,
      senderRole: senderRole,
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
      status: 'seen',
    );

    _chatMessages.add(msg);
    await _saveChatMessages();

    // Write to Supabase
    await SupabaseDbService.insertChatMessage(msg);

    notifyListeners();

    // Dispatch notification if coordinator sends a message
    if (senderRole == 'coordinator') {
      final eventIdx = _events.indexWhere((e) => e.id == eventId);
      final eventTitle =
          eventIdx != -1 ? _events[eventIdx].title : 'Event Support';
      await addNotification(
        'Message from Coordinator',
        '$eventTitle: $text',
        linkedEventId: eventId,
      );
    }

    // Trigger auto reply if student sent the message
    if (senderRole == 'student') {
      _triggerCoordinatorAutoReply(
          eventId, studentRoll, studentName, text);
    }
  }

  void markThreadAsSeen(String eventId, String studentRoll, String readerRole) {
    bool updated = false;
    for (int i = 0; i < _chatMessages.length; i++) {
      final msg = _chatMessages[i];
      if (msg.eventId == eventId && msg.studentRoll == studentRoll) {
        if (readerRole == 'coordinator' && msg.senderRole == 'student' && !msg.isRead) {
          _chatMessages[i] = msg.copyWith(isRead: true, status: 'seen');
          updated = true;
        } else if (readerRole == 'student' && msg.senderRole == 'coordinator' && !msg.isRead) {
          _chatMessages[i] = msg.copyWith(isRead: true, status: 'seen');
          updated = true;
        }
      }
    }
    if (updated) {
      _saveChatMessages();
      SupabaseDbService.updateThreadReadStatus(
        eventId: eventId,
        studentRoll: studentRoll,
        readerRole: readerRole,
      );
      notifyListeners();
    }
  }

  void _triggerCoordinatorAutoReply(
    String eventId,
    String studentRoll,
    String studentName,
    String studentText,
  ) {
    Timer(const Duration(milliseconds: 1500), () {
      final cleanText = studentText.toLowerCase();
      String replyText =
          'Hello! Thanks for reaching out. Let me look into this and get back to you shortly.';

      if (cleanText.contains('where') ||
          cleanText.contains('venue') ||
          cleanText.contains('location')) {
        replyText =
            'Hi! The event is hosted at the venue listed on the details screen. Let me know if you have trouble finding it.';
      } else if (cleanText.contains('time') ||
          cleanText.contains('when') ||
          cleanText.contains('start')) {
        replyText =
            'Hello! Check the event page for the exact start time. Please make sure to check in 15 minutes early.';
      } else if (cleanText.contains('cert') ||
          cleanText.contains('certificate')) {
        replyText =
            'Hi! Your digital certificate will be generated automatically once we mark your attendance at the venue.';
      } else if (cleanText.contains('team') ||
          cleanText.contains('group') ||
          cleanText.contains('members')) {
        replyText =
            'Hi! Yes, team members are welcome. Ensure everyone registers using their individual roll numbers.';
      }

      sendChatMessage(
          eventId, studentRoll, studentName, 'coordinator', replyText);
    });
  }

  /// Fetch chat messages from Supabase for a specific event + student.
  Future<void> loadChatMessages({
    required String eventId,
    String? studentRoll,
  }) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final msgs = await SupabaseDbService.fetchChatMessages(
        eventId: eventId,
        studentRoll: studentRoll,
      );
      // Merge with local (avoid duplicates by id)
      final existingIds = _chatMessages.map((m) => m.id).toSet();
      for (final m in msgs) {
        if (!existingIds.contains(m.id)) {
          _chatMessages.add(m);
        }
      }
      _chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await _saveChatMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('loadChatMessages error: $e');
    }
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────────

  Future<void> addNotification(
    String title,
    String message, {
    String? linkedEventId,
    String? userId,  // null = broadcast
  }) async {
    final notif = NotificationModel(
      id: _uuid.v4(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      linkedEventId: linkedEventId,
    );
    _notifications.insert(0, notif);
    await _saveNotifications();

    // Write to Supabase
    await SupabaseDbService.insertNotification(notif, userId: userId);

    notifyListeners();

    await _showSystemNotification(title, message);
  }

  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      // Update Supabase
      await SupabaseDbService.markNotificationRead(id);
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _saveNotifications();

    // Update Supabase
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      await SupabaseDbService.markAllNotificationsRead(currentUser.id);
    }

    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();

    // Delete from Supabase
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      await SupabaseDbService.clearAllNotifications(currentUser.id);
    }

    notifyListeners();
  }

  // ─── LOCAL SYSTEM NOTIFICATIONS ──────────────────────────────────────────

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> _showSystemNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'n_vents_notifications',
      'Campus Event Registrations',
      channelDescription:
          'Notifications for campus registration updates and coordinator chats',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    try {
      await _localNotificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch.hashCode,
        title: title,
        body: message,
        notificationDetails: platformDetails,
      );
    } catch (e) {
      debugPrint('Local notifications info: $e');
    }
  }

  // ─── REAL-TIME DATA SIMULATOR ────────────────────────────────────────────

  void toggleSimulation(bool value) {
    _isSimulationActive = false;
    _stopSimulation();
    notifyListeners();
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  @override
  void dispose() {
    _stopSimulation();
    // Unsubscribe realtime channels
    if (_eventsChannel != null) {
      SupabaseDbService.unsubscribe(_eventsChannel!);
    }
    if (_registrationsChannel != null) {
      SupabaseDbService.unsubscribe(_registrationsChannel!);
    }
    if (_notificationsChannel != null) {
      SupabaseDbService.unsubscribe(_notificationsChannel!);
    }
    if (_chatChannel != null) {
      SupabaseDbService.unsubscribe(_chatChannel!);
    }
    super.dispose();
  }

  // ─── BANNER CRUD & REORDER ───────────────────────────────────────────────

  Future<void> addBanner(BannerModel banner) async {
    _banners.add(banner);
    _banners.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    await _saveBanners();
    await SupabaseDbService.insertBanner(banner);
    notifyListeners();
  }

  Future<void> updateBanner(BannerModel updatedBanner) async {
    final index = _banners.indexWhere((b) => b.id == updatedBanner.id);
    if (index != -1) {
      _banners[index] = updatedBanner;
      await _saveBanners();
      await SupabaseDbService.updateBanner(updatedBanner);
      notifyListeners();
    }
  }

  Future<void> deleteBanner(String id) async {
    _banners.removeWhere((b) => b.id == id);
    for (int i = 0; i < _banners.length; i++) {
      _banners[i] = _banners[i].copyWith(displayOrder: i);
    }
    await _saveBanners();
    await SupabaseDbService.deleteBanner(id);
    notifyListeners();
  }

  Future<void> reorderBanners(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final BannerModel item = _banners.removeAt(oldIndex);
    _banners.insert(newIndex, item);
    for (int i = 0; i < _banners.length; i++) {
      _banners[i] = _banners[i].copyWith(displayOrder: i);
    }
    await _saveBanners();
    // Update all banners in Supabase
    for (final b in _banners) {
      await SupabaseDbService.updateBanner(b);
    }
    notifyListeners();
  }

  // ─── THEME MODE ──────────────────────────────────────────────────────────

  Future<void> toggleThemeMode() async {
    if (_themeMode == ThemeMode.light || _themeMode == ThemeMode.system) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await prefs.setString(_keyThemeMode, modeStr);
    notifyListeners();
  }

  // ─── STAFF ASSIGNMENT CRUD ───────────────────────────────────────────────

  /// Grant a staff sub-role to a registered user.
  Future<void> grantStaffRole({
    required UserModel user,
    required String subRole,
    String assignedDepartment = '',
    List<String> assignedEventIds = const [],
    String grantedByAdminId = '',
  }) async {
    _staffAssignments.removeWhere((s) => s.userId == user.id);

    final assignment = StaffAssignment(
      id: _uuid.v4(),
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
      userRollNumber: user.rollNumber,
      userDepartment: user.department,
      subRole: subRole,
      assignedDepartment: assignedDepartment,
      assignedEventIds: assignedEventIds,
      grantedByAdminId: grantedByAdminId,
    );
    _staffAssignments.add(assignment);
    await _saveStaffAssignments();
    // Write to Supabase
    await SupabaseDbService.upsertStaffAssignment(assignment);

    // Sync subRole directly to user's profile table on Supabase server
    final updatedUser = user.copyWith(
      subRole: subRole,
      assignedDepartment: assignedDepartment,
      assignedEventIds: assignedEventIds,
    );
    await SupabaseDbService.upsertProfile(updatedUser);

    final pIdx = _dbProfiles.indexWhere((p) => p.id == user.id);
    if (pIdx != -1) {
      _dbProfiles[pIdx] = updatedUser;
    } else {
      _dbProfiles.add(updatedUser);
    }

    final subRoleLabel = SubRoles.label(subRole);
    await addNotification(
      '🎉 Staff Role Granted: $subRoleLabel',
      'Congratulations ${user.name}! You have been appointed as $subRoleLabel. Access your coordinator tools now.',
    );

    notifyListeners();
  }

  /// Delete a user account profile & staff assignment from database and local state.
  Future<void> deleteUserAccount(String userId) async {
    _dbProfiles.removeWhere((p) => p.id == userId);
    _staffAssignments.removeWhere((s) => s.userId == userId);
    await _saveStaffAssignments();
    await SupabaseDbService.deleteProfile(userId);
    notifyListeners();
  }

  /// Update an existing staff assignment.
  Future<void> updateStaffAssignment({
    required String userId,
    String? subRole,
    String? assignedDepartment,
    List<String>? assignedEventIds,
  }) async {
    final idx = _staffAssignments.indexWhere((s) => s.userId == userId);
    if (idx == -1) return;
    _staffAssignments[idx] = _staffAssignments[idx].copyWith(
      subRole: subRole,
      assignedDepartment: assignedDepartment,
      assignedEventIds: assignedEventIds,
    );
    await _saveStaffAssignments();
    await SupabaseDbService.upsertStaffAssignment(_staffAssignments[idx]);
    notifyListeners();
  }

  /// Revoke a user's staff role.
  Future<void> revokeStaffRole(String userId) async {
    _staffAssignments.removeWhere((s) => s.userId == userId);
    await _saveStaffAssignments();
    await SupabaseDbService.deleteStaffAssignment(userId);
    notifyListeners();
  }

  List<StaffAssignment> getStaffByRole(String subRole) {
    return _staffAssignments.where((s) => s.subRole == subRole).toList();
  }

  StaffAssignment? getAssignmentForUser(String userId) {
    try {
      return _staffAssignments.firstWhere((s) => s.userId == userId);
    } catch (_) {
      return null;
    }
  }

  List<Event> getAssignedEvents(List<String> assignedEventIds) {
    return _events.where((e) => assignedEventIds.contains(e.id)).toList();
  }

  Registration? verifyParticipantCode({
    required String participantCode,
    String? eventId,
    List<String>? assignedEventIds,
  }) {
    try {
      final clean = participantCode.trim().toLowerCase();
      return _registrations.firstWhere(
        (r) {
          if (eventId != null && eventId.isNotEmpty && r.eventId != eventId) {
            return false;
          }
          if (assignedEventIds != null && assignedEventIds.isNotEmpty && !assignedEventIds.contains(r.eventId)) {
            return false;
          }
          final ticketCode = r.id.substring(0, r.id.length < 10 ? r.id.length : 10).toLowerCase();
          final user10Digit = UserModel.generate10DigitParticipantCode(r.rollNumber).toLowerCase();
          return r.rollNumber.toLowerCase() == clean ||
              r.id.toLowerCase() == clean ||
              ticketCode == clean ||
              user10Digit == clean;
        },
      );
    } catch (_) {
      return null;
    }
  }
}
