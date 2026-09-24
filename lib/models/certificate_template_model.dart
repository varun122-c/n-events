import 'dart:convert';
import 'package:flutter/material.dart';

class CertificateTemplate {
  final String id;
  final String eventId;
  final String title; // e.g. "CERTIFICATE OF PARTICIPATION" or "CERTIFICATE OF EXCELLENCE"
  final String subtitle; // e.g. "PROUDLY PRESENTED TO"
  final String bodyText; // e.g. "for active and successful participation in the campus event"
  final String signatoryName1; // e.g. "Dr. A. Sharma"
  final String signatoryRole1; // e.g. "Principal"
  final String signatoryName2; // e.g. "Prof. R. Kumar"
  final String signatoryRole2; // e.g. "Event Coordinator"
  final String themeColorHex; // e.g. "#FFD700" (Gold), "#059669" (Emerald), "#2563EB" (Royal Blue), "#94A3B8" (Platinum), "#DC2626" (Crimson)
  final String badgeStyle; // "Gold", "Platinum", "Emerald", "Royal", "Crimson"
  final String canvaUrl; // Canva Design Template URL or Custom Background Image URL
  final DateTime updatedAt;

  CertificateTemplate({
    required this.id,
    required this.eventId,
    this.title = 'CERTIFICATE OF PARTICIPATION',
    this.subtitle = 'PROUDLY PRESENTED TO',
    this.bodyText = 'for active and successful participation in the campus event',
    this.signatoryName1 = 'Dr. A. Sharma',
    this.signatoryRole1 = 'Principal / Patron',
    this.signatoryName2 = 'Event Coordinator',
    this.signatoryRole2 = 'Convener',
    this.themeColorHex = '#FFD700',
    this.badgeStyle = 'Gold',
    this.canvaUrl = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Color get themeColor {
    try {
      final hex = themeColorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFFFD700);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'subtitle': subtitle,
      'bodyText': bodyText,
      'signatoryName1': signatoryName1,
      'signatoryRole1': signatoryRole1,
      'signatoryName2': signatoryName2,
      'signatoryRole2': signatoryRole2,
      'themeColorHex': themeColorHex,
      'badgeStyle': badgeStyle,
      'canvaUrl': canvaUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CertificateTemplate.fromMap(Map<String, dynamic> map) {
    return CertificateTemplate(
      id: map['id'] as String? ?? '',
      eventId: map['eventId'] as String? ?? map['event_id'] as String? ?? '',
      title: map['title'] as String? ?? 'CERTIFICATE OF PARTICIPATION',
      subtitle: map['subtitle'] as String? ?? 'PROUDLY PRESENTED TO',
      bodyText: map['bodyText'] as String? ?? map['body_text'] as String? ?? 'for active and successful participation in the campus event',
      signatoryName1: map['signatoryName1'] as String? ?? map['signatory_name1'] as String? ?? 'Dr. A. Sharma',
      signatoryRole1: map['signatoryRole1'] as String? ?? map['signatory_role1'] as String? ?? 'Principal / Patron',
      signatoryName2: map['signatoryName2'] as String? ?? map['signatory_role2'] as String? ?? 'Event Coordinator',
      signatoryRole2: map['signatoryRole2'] as String? ?? map['signatory_role2'] as String? ?? 'Convener',
      themeColorHex: map['themeColorHex'] as String? ?? map['theme_color_hex'] as String? ?? '#FFD700',
      badgeStyle: map['badgeStyle'] as String? ?? map['badge_style'] as String? ?? 'Gold',
      canvaUrl: map['canvaUrl'] as String? ?? map['canva_url'] as String? ?? map['design_url'] as String? ?? '',
      updatedAt: map['updatedAt'] != null || map['updated_at'] != null
          ? DateTime.tryParse(map['updatedAt']?.toString() ?? map['updated_at']?.toString() ?? '') ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CertificateTemplate.fromJson(String source) =>
      CertificateTemplate.fromMap(json.decode(source) as Map<String, dynamic>);

  CertificateTemplate copyWith({
    String? id,
    String? eventId,
    String? title,
    String? subtitle,
    String? bodyText,
    String? signatoryName1,
    String? signatoryRole1,
    String? signatoryName2,
    String? signatoryRole2,
    String? themeColorHex,
    String? badgeStyle,
    String? canvaUrl,
    DateTime? updatedAt,
  }) {
    return CertificateTemplate(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      bodyText: bodyText ?? this.bodyText,
      signatoryName1: signatoryName1 ?? this.signatoryName1,
      signatoryRole1: signatoryRole1 ?? this.signatoryRole1,
      signatoryName2: signatoryName2 ?? this.signatoryName2,
      signatoryRole2: signatoryRole2 ?? this.signatoryRole2,
      themeColorHex: themeColorHex ?? this.themeColorHex,
      badgeStyle: badgeStyle ?? this.badgeStyle,
      canvaUrl: canvaUrl ?? this.canvaUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
