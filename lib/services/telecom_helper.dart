import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelecomOperator {
  final String name;
  final String networkType;
  final Color primaryColor;
  final Color badgeColor;
  final IconData icon;
  final String realPhoneNumber;
  final bool isHardwareSim;

  const TelecomOperator({
    required this.name,
    required this.networkType,
    required this.primaryColor,
    required this.badgeColor,
    required this.icon,
    this.realPhoneNumber = '',
    this.isHardwareSim = false,
  });
}

class TelecomHelper {
  static const MethodChannel _simChannel = MethodChannel('com.nvents.app/sim');

  /// Query real physical hardware SIM card(s) inserted into the device hardware tray
  static Future<List<TelecomOperator>> getHardwareSimCards() async {
    try {
      final List<dynamic>? rawList =
          await _simChannel.invokeMethod('getDeviceSimInfo');
      if (rawList == null || rawList.isEmpty) return [];

      List<TelecomOperator> operators = [];
      for (var item in rawList) {
        if (item is Map) {
          final carrierName = item['carrierName']?.toString() ?? '';
          final displayName = item['displayName']?.toString() ?? '';
          final phone = item['phoneNumber']?.toString() ?? '';

          final text = carrierName.isNotEmpty ? carrierName : displayName;
          if (text.isNotEmpty) {
            final op = parseCarrierText(text, phone: phone, isHardware: true);
            operators.add(op);
          }
        }
      }
      return operators;
    } catch (e) {
      debugPrint('getHardwareSimCards methodChannel error: $e');
      return [];
    }
  }

  /// Parse text returned from Android TelephonyManager / SubscriptionManager
  static TelecomOperator parseCarrierText(
    String carrierText, {
    String phone = '',
    bool isHardware = true,
  }) {
    final lower = carrierText.toLowerCase();

    if (lower.contains('jio') || lower.contains('reliance')) {
      return TelecomOperator(
        name: 'Jio True 5G (Physical SIM)',
        networkType: 'Hardware SIM Tray 1 (Jio 5G)',
        primaryColor: const Color(0xFF0057FF),
        badgeColor: const Color(0xFF0A2540),
        icon: Icons.sim_card_rounded,
        realPhoneNumber: phone,
        isHardwareSim: isHardware,
      );
    } else if (lower.contains('airtel') || lower.contains('bharti')) {
      return TelecomOperator(
        name: 'Airtel 5G Plus (Physical SIM)',
        networkType: 'Hardware SIM Tray (Airtel 5G)',
        primaryColor: const Color(0xFFE40000),
        badgeColor: const Color(0xFF7F1D1D),
        icon: Icons.sim_card_rounded,
        realPhoneNumber: phone,
        isHardwareSim: isHardware,
      );
    } else if (lower.contains('vi') ||
        lower.contains('vodafone') ||
        lower.contains('idea')) {
      return TelecomOperator(
        name: 'Vi (Vodafone Idea SIM)',
        networkType: 'Hardware SIM Tray (Vi 4G/5G)',
        primaryColor: const Color(0xFF8B5CF6),
        badgeColor: const Color(0xFF4C1D95),
        icon: Icons.sim_card_rounded,
        realPhoneNumber: phone,
        isHardwareSim: isHardware,
      );
    } else if (lower.contains('bsnl')) {
      return TelecomOperator(
        name: 'BSNL Mobile (Physical SIM)',
        networkType: 'Hardware SIM Tray (BSNL)',
        primaryColor: const Color(0xFFFF6B00),
        badgeColor: const Color(0xFF1E3A8A),
        icon: Icons.sim_card_rounded,
        realPhoneNumber: phone,
        isHardwareSim: isHardware,
      );
    }

    return TelecomOperator(
      name: carrierText.isNotEmpty ? carrierText : 'Physical SIM Card',
      networkType: 'Hardware SIM Card Inserted',
      primaryColor: const Color(0xFF2563EB),
      badgeColor: const Color(0xFF1E3A8A),
      icon: Icons.sim_card_rounded,
      realPhoneNumber: phone,
      isHardwareSim: isHardware,
    );
  }

  /// Detect Indian SIM Operator based on mobile prefix (when typing)
  static TelecomOperator? detectOperator(String phoneNumber) {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;

    String num = clean;
    if (num.startsWith('91') && num.length == 12) {
      num = num.substring(2);
    }
    if (num.length < 3) return null;

    final prefix3 = num.substring(0, 3);
    final firstChar = num[0];

    // Jio: Starts with 6, 700-705, 79, 800, 801, 808, 810, 812, 829, 836, 843, 852, 870, 882, 887, 888, 892, 901, 910, 920, 930-939
    if (firstChar == '6' ||
        ['700', '701', '702', '703', '704', '705', '790', '797', '798', '799', '800', '801', '808', '810', '812', '829', '836', '843', '852', '870', '882', '887', '888', '892', '901', '910', '920'].contains(prefix3) ||
        (int.tryParse(prefix3) != null && int.parse(prefix3) >= 930 && int.parse(prefix3) <= 939)) {
      return const TelecomOperator(
        name: 'Jio True 5G',
        networkType: 'Jio 5G / VoLTE',
        primaryColor: Color(0xFF0057FF),
        badgeColor: Color(0xFF0A2540),
        icon: Icons.cell_tower_rounded,
      );
    }

    // Airtel: 701, 708, 730-739, 740-749, 750-756, 760-769, 770-779, 780-789, 805, 813, 814, 844, 858, 860, 880, 898, 900, 914, 960-979, 980-981, 983, 989, 990-999
    if (['701', '708', '805', '813', '814', '844', '858', '860', '880', '898', '900', '914', '980', '981', '983', '989'].contains(prefix3) ||
        (int.tryParse(prefix3) != null &&
            ((int.parse(prefix3) >= 730 && int.parse(prefix3) <= 789) ||
             (int.parse(prefix3) >= 960 && int.parse(prefix3) <= 979) ||
             (int.parse(prefix3) >= 990 && int.parse(prefix3) <= 999)))) {
      return const TelecomOperator(
        name: 'Airtel 5G Plus',
        networkType: 'Airtel 5G / VoLTE',
        primaryColor: Color(0xFFE40000),
        badgeColor: Color(0xFF7F1D1D),
        icon: Icons.cell_tower_rounded,
      );
    }

    // Vi (Vodafone Idea): 702, 704, 720-729, 787, 808, 810, 822, 840, 848, 869, 886, 888, 902, 909, 916, 950-959, 966, 971, 982, 984, 988
    if (['702', '704', '787', '808', '810', '822', '840', '848', '869', '886', '888', '902', '909', '916', '966', '971', '982', '984', '988'].contains(prefix3) ||
        (int.tryParse(prefix3) != null &&
            ((int.parse(prefix3) >= 720 && int.parse(prefix3) <= 729) ||
             (int.parse(prefix3) >= 950 && int.parse(prefix3) <= 959)))) {
      return const TelecomOperator(
        name: 'Vi (Vodafone Idea)',
        networkType: 'Vi GIGAnet 4G / 5G',
        primaryColor: Color(0xFF8B5CF6),
        badgeColor: Color(0xFF4C1D95),
        icon: Icons.signal_cellular_alt_rounded,
      );
    }

    // BSNL: 758, 890, 940-949
    if (['758', '890'].contains(prefix3) ||
        (int.tryParse(prefix3) != null && int.parse(prefix3) >= 940 && int.parse(prefix3) <= 949)) {
      return const TelecomOperator(
        name: 'BSNL Mobile',
        networkType: 'BSNL 4G VoLTE',
        primaryColor: Color(0xFFFF6B00),
        badgeColor: Color(0xFF1E3A8A),
        icon: Icons.signal_cellular_alt_rounded,
      );
    }

    // Fallback Mobile Operator for 6, 7, 8, 9
    if (['6', '7', '8', '9'].contains(firstChar)) {
      return const TelecomOperator(
        name: 'Cellular SIM',
        networkType: '4G / 5G Network',
        primaryColor: Color(0xFF2563EB),
        badgeColor: Color(0xFF1E3A8A),
        icon: Icons.sim_card_rounded,
      );
    }

    return null;
  }
}
