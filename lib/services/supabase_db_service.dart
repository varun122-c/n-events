import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import '../models/banner_model.dart';
import '../models/notification_model.dart';
import '../models/chat_message_model.dart';
import '../models/staff_assignment_model.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import 'supabase_service.dart';

/// Central service for all Supabase database operations.
/// Uses Supabase as primary source; callers should handle null returns
/// by falling back to local cache when Supabase is unavailable.
class SupabaseDbService {
  static SupabaseClient? get _client => SupabaseService.client;

  static bool get _isReady =>
      SupabaseService.isInitialized && _client != null;

  // ─── PROFILES ────────────────────────────────────────────────────────────

  /// Upsert a user's profile into the `profiles` table.
  static Future<void> upsertProfile(UserModel user) async {
    if (!_isReady) return;
    try {
      await _client!.from('profiles').upsert({
        'id': user.id,
        'name': user.name,
        'roll_number': user.rollNumber,
        'department': user.department,
        'college': user.college,
        'year': user.year,
        'phone': user.phone,
        'dob': user.dob,
        'gender': user.gender,
        'role': user.role,
        'sub_role': user.subRole,
        'avatar_index': user.avatarIndex,
        'custom_avatar_url': user.customAvatarUrl,
        'participant_code': user.displayParticipantCode,
        'assigned_department': user.assignedDepartment,
        'assigned_event_ids': user.assignedEventIds,
      });
    } catch (e) {
      debugPrint('SupabaseDbService.upsertProfile error: $e');
    }
  }
  /// Delete a user profile and staff assignment from Supabase DB.
  static Future<void> deleteProfile(String userId) async {
    if (!_isReady) return;
    try {
      await _client!.from('profiles').delete().eq('id', userId);
      await _client!.from('staff_assignments').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('SupabaseDbService.deleteProfile error: $e');
    }
  }

  /// Fetch a user profile by their auth UUID.
  static Future<UserModel?> fetchProfile(String userId) async {
    if (!_isReady) return null;
    try {
      final data = await _client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return _profileFromMap(data, userId);
    } catch (e) {
      debugPrint('SupabaseDbService.fetchProfile error: $e');
      return null;
    }
  }

  /// Fetch all profiles (admin use).
  static Future<List<UserModel>> fetchAllProfiles() async {
    if (!_isReady) return [];
    try {
      final data = await _client!.from('profiles').select();
      return (data as List<dynamic>)
          .map((m) => _profileFromMap(m as Map<String, dynamic>, m['id'] ?? ''))
          .toList();
    } catch (e) {
      debugPrint('SupabaseDbService.fetchAllProfiles error: $e');
      return [];
    }
  }

  static UserModel _profileFromMap(Map<String, dynamic> m, String userId) {
    final eventIdsRaw = m['assigned_event_ids'];
    List<String> eventIds = [];
    if (eventIdsRaw is List) {
      eventIds = List<String>.from(eventIdsRaw);
    }
    return UserModel(
      id: userId,
      name: m['name'] ?? '',
      email: '',  // email comes from auth.users, not profiles
      password: '',
      role: m['role'] ?? 'student',
      subRole: m['sub_role'] ?? '',
      rollNumber: m['roll_number'] ?? '',
      department: m['department'] ?? 'Computer Science and Engineering (CSE)',
      college: m['college'] ?? 'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
      year: m['year'] ?? '1st Year',
      phone: m['phone'] ?? '',
      dob: m['dob'] ?? '',
      gender: m['gender'] ?? 'Male',
      avatarIndex: m['avatar_index'] ?? 0,
      customAvatarUrl: m['custom_avatar_url'] ?? '',
      participantCode: m['participant_code'] ?? '',
      assignedDepartment: m['assigned_department'] ?? '',
      assignedEventIds: eventIds,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ─── EVENTS ──────────────────────────────────────────────────────────────

  /// Fetch all events from Supabase, ordered by date.
  static Future<List<Event>> fetchEvents() async {
    if (!_isReady) return [];
    try {
      final data = await _client!
          .from('events')
          .select()
          .order('date_time', ascending: true);
      return (data as List<dynamic>)
          .map((m) => _eventFromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseDbService.fetchEvents error: $e');
      return [];
    }
  }

  /// Insert a new event.
  static Future<void> insertEvent(Event event) async {
    if (!_isReady) return;
    try {
      await _client!.from('events').insert(_eventToMap(event));
    } catch (e) {
      debugPrint('SupabaseDbService.insertEvent error: $e');
    }
  }

  /// Update an existing event.
  static Future<void> updateEvent(Event event) async {
    if (!_isReady) return;
    try {
      await _client!
          .from('events')
          .update(_eventToMap(event))
          .eq('id', event.id);
    } catch (e) {
      debugPrint('SupabaseDbService.updateEvent error: $e');
    }
  }

  /// Delete an event by ID.
  static Future<void> deleteEvent(String id) async {
    if (!_isReady) return;
    try {
      await _client!.from('events').delete().eq('id', id);
    } catch (e) {
      debugPrint('SupabaseDbService.deleteEvent error: $e');
    }
  }

  static Map<String, dynamic> _eventToMap(Event e) => {
    'id': e.id,
    'title': e.title,
    'description': e.description,
    'banner_url': e.bannerUrl,
    'date_time': e.dateTime.toIso8601String(),
    'venue': e.venue,
    'category': e.category,
    'coordinator_name': e.coordinatorName,
    'coordinator_phone': e.coordinatorPhone,
    'max_seats': e.maxSeats,
    'reviews': e.reviews.map((r) => r.toJson()).toList(),
  };

  static Event _eventFromMap(Map<String, dynamic> m) {
    final reviewsRaw = m['reviews'];
    List<Review> reviews = [];
    if (reviewsRaw is List) {
      reviews = reviewsRaw
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    return Event(
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String? ?? '',
      bannerUrl: m['banner_url'] as String? ?? '',
      dateTime: DateTime.parse(m['date_time'] as String),
      venue: m['venue'] as String? ?? '',
      category: m['category'] as String? ?? 'Technical',
      coordinatorName: m['coordinator_name'] as String? ?? '',
      coordinatorPhone: m['coordinator_phone'] as String? ?? '',
      maxSeats: m['max_seats'] as int? ?? 100,
      reviews: reviews,
    );
  }

  // ─── REGISTRATIONS ───────────────────────────────────────────────────────

  /// Fetch all registrations (admin/staff use).
  static Future<List<Registration>> fetchAllRegistrations() async {
    if (!_isReady) return [];
    try {
      final data = await _client!
          .from('registrations')
          .select()
          .order('registration_date', ascending: false);
      return (data as List<dynamic>)
          .map((m) => _registrationFromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseDbService.fetchAllRegistrations error: $e');
      return [];
    }
  }

  /// Fetch registrations for a specific user.
  static Future<List<Registration>> fetchUserRegistrations(String userId) async {
    if (!_isReady) return [];
    try {
      final data = await _client!
          .from('registrations')
          .select()
          .eq('user_id', userId)
          .order('registration_date', ascending: false);
      return (data as List<dynamic>)
          .map((m) => _registrationFromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseDbService.fetchUserRegistrations error: $e');
      return [];
    }
  }

  static bool _isValidUuid(String str) {
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(str);
  }

  /// Insert a new registration. Returns true on success.
  static Future<bool> insertRegistration(
    Registration reg, {
    String? userId,
  }) async {
    if (!_isReady) return false;
    try {
      final rawUser = userId ?? reg.userId ?? _client!.auth.currentUser?.id;
      final effectiveUserId = (rawUser != null && rawUser.isNotEmpty && _isValidUuid(rawUser))
          ? rawUser
          : _client!.auth.currentUser?.id;

      await _client!.from('registrations').insert({
        'id': reg.id,
        'event_id': reg.eventId,
        'user_id': effectiveUserId,
        'full_name': reg.fullName,
        'roll_number': reg.rollNumber,
        'department': reg.department,
        'college': reg.college,
        'year_of_study': reg.yearOfStudy,
        'phone_number': reg.phoneNumber,
        'registration_date': reg.registrationDate.toIso8601String(),
        'status': reg.status,
        'verified_by': reg.verifiedBy,
        'verified_at': reg.verifiedAt?.toIso8601String(),
        'is_certificate_published': reg.isCertificatePublished,
      });
      return true;
    } catch (e) {
      debugPrint('SupabaseDbService.insertRegistration error: $e');
      return false;
    }
  }

  /// Update registration status and verification/certificate flags.
  static Future<void> updateRegistrationDetails(Registration reg) async {
    if (!_isReady) return;
    try {
      await _client!
          .from('registrations')
          .update({
            'status': reg.status,
            'verified_by': reg.verifiedBy,
            'verified_at': reg.verifiedAt?.toIso8601String(),
            'is_certificate_published': reg.isCertificatePublished,
          })
          .eq('id', reg.id);
    } catch (e) {
      debugPrint('SupabaseDbService.updateRegistrationDetails error: $e');
    }
  }

  static Future<void> updateRegistrationStatus(
    String regId,
    String newStatus,
  ) async {
    if (!_isReady) return;
    try {
      await _client!
          .from('registrations')
          .update({'status': newStatus})
          .eq('id', regId);
    } catch (e) {
      debugPrint('SupabaseDbService.updateRegistrationStatus error: $e');
    }
  }

  static Registration _registrationFromMap(Map<String, dynamic> m) =>
      Registration(
        id: m['id'] as String,
        eventId: m['event_id'] as String,
        userId: m['user_id'] as String?,
        fullName: m['full_name'] as String,
        rollNumber: m['roll_number'] as String,
        department: m['department'] as String? ?? '',
        college: m['college'] as String? ??
            'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
        yearOfStudy: m['year_of_study'] as String? ?? '',
        phoneNumber: m['phone_number'] as String? ?? '',
        registrationDate:
            DateTime.parse(m['registration_date'] as String),
        status: m['status'] as String? ?? 'Registered',
        verifiedBy: m['verified_by'] as String?,
        verifiedAt: m['verified_at'] != null ? DateTime.tryParse(m['verified_at'] as String) : null,
        isCertificatePublished: m['is_certificate_published'] as bool? ?? false,
      );

  // ─── BANNERS ─────────────────────────────────────────────────────────────

  static Future<List<BannerModel>> fetchBanners() async {
    if (!_isReady) return [];
    try {
      final data = await _client!
          .from('banners')
          .select()
          .order('display_order', ascending: true);
      return (data as List<dynamic>)
          .map((m) => _bannerFromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseDbService.fetchBanners error: $e');
      return [];
    }
  }

  static Future<void> insertBanner(BannerModel b) async {
    if (!_isReady) return;
    try {
      await _client!.from('banners').insert(_bannerToMap(b));
    } catch (e) {
      debugPrint('SupabaseDbService.insertBanner error: $e');
    }
  }

  static Future<void> updateBanner(BannerModel b) async {
    if (!_isReady) return;
    try {
      await _client!.from('banners').update(_bannerToMap(b)).eq('id', b.id);
    } catch (e) {
      debugPrint('SupabaseDbService.updateBanner error: $e');
    }
  }

  static Future<void> deleteBanner(String id) async {
    if (!_isReady) return;
    try {
      await _client!.from('banners').delete().eq('id', id);
    } catch (e) {
      debugPrint('SupabaseDbService.deleteBanner error: $e');
    }
  }

  static Map<String, dynamic> _bannerToMap(BannerModel b) => {
    'id': b.id,
    'title': b.title,
    'image_url': b.imageUrl,
    'linked_event_id': (b.linkedEventId != null && b.linkedEventId!.isNotEmpty) ? b.linkedEventId : null,
    'display_order': b.displayOrder,
  };

  static BannerModel _bannerFromMap(Map<String, dynamic> m) => BannerModel(
        id: m['id'] as String,
        title: m['title'] as String,
        imageUrl: m['image_url'] as String,
        linkedEventId: m['linked_event_id'] as String?,
        displayOrder: m['display_order'] as int? ?? 0,
      );

  // ─── STAFF ASSIGNMENTS ───────────────────────────────────────────────────

  static Future<List<StaffAssignment>> fetchStaffAssignments() async {
    if (!_isReady) return [];
    try {
      final data = await _client!.from('staff_assignments').select();
      return (data as List<dynamic>)
          .map((m) => _staffFromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseDbService.fetchStaffAssignments error: $e');
      return [];
    }
  }

  static Future<void> upsertStaffAssignment(StaffAssignment s) async {
    if (!_isReady) return;
    try {
      await _client!.from('staff_assignments').upsert({
        'id': s.id,
        'user_id': s.userId,
        'user_name': s.userName,
        'user_email': s.userEmail,
        'user_roll_number': s.userRollNumber,
        'user_department': s.userDepartment,
        'sub_role': s.subRole,
        'assigned_department': s.assignedDepartment,
        'assigned_event_ids': s.assignedEventIds,
        'granted_by_admin_id': s.grantedByAdminId.isNotEmpty ? s.grantedByAdminId : null,
        'granted_at': s.grantedAt.toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('SupabaseDbService.upsertStaffAssignment error: $e');
    }
  }

  static Future<void> deleteStaffAssignment(String userId) async {
    if (!_isReady) return;
    try {
      await _client!.from('staff_assignments').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('SupabaseDbService.deleteStaffAssignment error: $e');
    }
  }

  static StaffAssignment _staffFromMap(Map<String, dynamic> m) {
    final eventIdsRaw = m['assigned_event_ids'];
    List<String> eventIds = [];
    if (eventIdsRaw is List) {
      eventIds = List<String>.from(eventIdsRaw);
    }
    return StaffAssignment(
      id: m['id'] ?? '',
      userId: m['user_id'] ?? '',
      userName: m['user_name'] ?? '',
      userEmail: m['user_email'] ?? '',
      userRollNumber: m['user_roll_number'] ?? '',
      userDepartment: m['user_department'] ?? '',
      subRole: m['sub_role'] ?? '',
      assignedDepartment: m['assigned_department'] ?? '',
      assignedEventIds: eventIds,
      grantedAt: m['granted_at'] != null
          ? DateTime.tryParse(m['granted_at']) ?? DateTime.now()
          : DateTime.now(),
      grantedByAdminId: m['granted_by_admin_id'] ?? '',
    );
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────────

  /// Fetch notifications for a specific user (includes broadcasts where user_id is null).
  static Future<List<NotificationModel>> fetchNotifications(String userId) async {
    if (!_isReady) return [];
    try {
      // We need to get rows where user_id matches OR user_id is null (broadcast)
      final data = await _client!
          .from('notifications')
          .select()
          .or('user_id.eq.$userId,user_id.is.null')
          .order('created_at', ascending: false)
          .limit(100);
      return (data as List<dynamic>)
          .map((m) => _notificationFromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseDbService.fetchNotifications error: $e');
      return [];
    }
  }

  /// Insert a broadcast notification (user_id = null means all users see it).
  static Future<void> insertNotification(
    NotificationModel n, {
    String? userId,  // null = broadcast
  }) async {
    if (!_isReady) return;
    try {
      final sanitizedLinkedEventId = (n.linkedEventId != null && n.linkedEventId!.isNotEmpty) ? n.linkedEventId : null;
      await _client!.from('notifications').insert({
        'id': n.id,
        'user_id': userId,
        'title': n.title,
        'message': n.message,
        'is_read': n.isRead,
        'linked_event_id': sanitizedLinkedEventId,
        'created_at': n.timestamp.toIso8601String(),
      });
    } catch (e) {
      debugPrint('SupabaseDbService.insertNotification error: $e');
    }
  }

  static Future<void> markNotificationRead(String id) async {
    if (!_isReady) return;
    try {
      await _client!
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('SupabaseDbService.markNotificationRead error: $e');
    }
  }

  static Future<void> markAllNotificationsRead(String userId) async {
    if (!_isReady) return;
    try {
      await _client!
          .from('notifications')
          .update({'is_read': true})
          .or('user_id.eq.$userId,user_id.is.null');
    } catch (e) {
      debugPrint('SupabaseDbService.markAllNotificationsRead error: $e');
    }
  }

  static Future<void> clearAllNotifications(String userId) async {
    if (!_isReady) return;
    try {
      await _client!
          .from('notifications')
          .delete()
          .or('user_id.eq.$userId,user_id.is.null');
    } catch (e) {
      debugPrint('SupabaseDbService.clearAllNotifications error: $e');
    }
  }

  static NotificationModel _notificationFromMap(Map<String, dynamic> m) =>
      NotificationModel(
        id: m['id'] as String,
        title: m['title'] as String,
        message: m['message'] as String,
        timestamp: DateTime.parse(m['created_at'] as String),
        isRead: m['is_read'] as bool? ?? false,
        linkedEventId: m['linked_event_id'] as String?,
      );

  // ─── CHAT MESSAGES ───────────────────────────────────────────────────────

  /// Fetch chat messages for a specific event + student roll.
  static Future<List<ChatMessageModel>> fetchChatMessages({
    required String eventId,
    String? studentRoll,  // null = fetch all for the event (coordinator view)
  }) async {
    if (!_isReady) return [];
    try {
      var query = _client!
          .from('chat_messages')
          .select()
          .eq('event_id', eventId);
      if (studentRoll != null) {
        query = query.eq('student_roll', studentRoll);
      }
      final data = await query.order('created_at', ascending: true);
      return (data as List<dynamic>)
          .map((m) => _chatFromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseDbService.fetchChatMessages error: $e');
      return [];
    }
  }

  /// Fetch all chat messages across all events and students for real-time sync.
  static Future<List<ChatMessageModel>> fetchAllChatMessages() async {
    if (!_isReady) return [];
    try {
      final data = await _client!
          .from('chat_messages')
          .select()
          .order('created_at', ascending: true);
      return (data as List<dynamic>)
          .map((m) => _chatFromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseDbService.fetchAllChatMessages error: $e');
      return [];
    }
  }

  static Future<void> insertChatMessage(ChatMessageModel msg) async {
    if (!_isReady) return;
    try {
      await _client!.from('chat_messages').insert({
        'id': msg.id,
        'event_id': msg.eventId,
        'student_roll': msg.studentRoll,
        'student_name': msg.studentName,
        'sender_role': msg.senderRole,
        'text': msg.text,
        'created_at': msg.timestamp.toIso8601String(),
        'is_read': msg.isRead,
        'status': msg.status,
      });
    } catch (e) {
      debugPrint('SupabaseDbService.insertChatMessage error: $e');
    }
  }

  static Future<void> updateThreadReadStatus({
    required String eventId,
    required String studentRoll,
    required String readerRole,
  }) async {
    if (!_isReady) return;
    try {
      final senderToMatch = readerRole == 'coordinator' ? 'student' : 'coordinator';
      await _client!.from('chat_messages').update({
        'is_read': true,
        'status': 'seen',
      }).eq('event_id', eventId).eq('student_roll', studentRoll).eq('sender_role', senderToMatch);
    } catch (e) {
      debugPrint('SupabaseDbService.updateThreadReadStatus error: $e');
    }
  }

  static ChatMessageModel _chatFromMap(Map<String, dynamic> m) =>
      ChatMessageModel(
        id: m['id'] as String,
        eventId: m['event_id'] as String,
        studentRoll: m['student_roll'] as String,
        studentName: m['student_name'] as String,
        senderRole: m['sender_role'] as String,
        text: m['text'] as String,
        timestamp: DateTime.parse(m['created_at'] as String),
        isRead: m['is_read'] as bool? ?? false,
        status: m['status'] as String? ?? 'sent',
      );

  // ─── REALTIME SUBSCRIPTIONS ──────────────────────────────────────────────

  /// Subscribe to events table changes.
  static RealtimeChannel subscribeToEvents({
    required void Function(List<Event> events) onData,
  }) {
    return _client!
        .channel('public:events')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) async {
            final events = await fetchEvents();
            onData(events);
          },
        )
        .subscribe();
  }

  /// Subscribe to registrations table changes.
  static RealtimeChannel subscribeToRegistrations({
    required void Function(List<Registration> registrations) onData,
  }) {
    return _client!
        .channel('public:registrations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'registrations',
          callback: (payload) async {
            final regs = await fetchAllRegistrations();
            onData(regs);
          },
        )
        .subscribe();
  }

  /// Subscribe to notifications for a specific user.
  static RealtimeChannel subscribeToNotifications({
    required String userId,
    required void Function(List<NotificationModel> notifications) onData,
  }) {
    return _client!
        .channel('public:notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) async {
            final notifs = await fetchNotifications(userId);
            onData(notifs);
          },
        )
        .subscribe();
  }

  /// Subscribe to chat messages for a specific event.
  static RealtimeChannel subscribeToChatMessages({
    required String eventId,
    String? studentRoll,
    required void Function(List<ChatMessageModel> messages) onData,
  }) {
    return _client!
        .channel('public:chat_messages:$eventId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'event_id',
            value: eventId,
          ),
          callback: (payload) async {
            final msgs = await fetchChatMessages(
              eventId: eventId,
              studentRoll: studentRoll,
            );
            onData(msgs);
          },
        )
        .subscribe();
  }

  /// Subscribe to ALL chat messages across all events and students for real-time updates.
  static RealtimeChannel subscribeToAllChatMessages({
    required void Function(List<ChatMessageModel> messages) onData,
  }) {
    return _client!
        .channel('public:chat_messages_all')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) async {
            final msgs = await fetchAllChatMessages();
            onData(msgs);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from a realtime channel.
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    if (!_isReady) return;
    await _client!.removeChannel(channel);
  }
}
