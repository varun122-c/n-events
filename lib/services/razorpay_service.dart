import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Razorpay Test Credentials
const String kRazorpayKeyId = 'rzp_test_TfxwweKy5Ryffj';

/// Centralised service for Razorpay payment flows.
///
/// Usage:
///   1. Call [init] once (e.g. in initState).
///   2. Call [launchPayment] to open the checkout.
///   3. Call [dispose] in the widget's dispose() method.
class RazorpayService {
  static Razorpay? _razorpay;

  static void Function(PaymentSuccessResponse)? onSuccess;
  static void Function(PaymentFailureResponse)? onFailure;
  static void Function(ExternalWalletResponse)? onWallet;

  /// Initialise Razorpay and attach event listeners.
  static void init({
    required void Function(PaymentSuccessResponse) onPaymentSuccess,
    required void Function(PaymentFailureResponse) onPaymentFailure,
    void Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    onSuccess = onPaymentSuccess;
    onFailure = onPaymentFailure;
    onWallet = onExternalWallet;

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
  }

  /// Open the Razorpay checkout sheet.
  /// [amountInRupees] is converted to paise internally.
  static void launchPayment({
    required double amountInRupees,
    required String eventTitle,
    required String studentName,
    required String email,
    required String phone,
    String? description,
  }) {
    if (_razorpay == null) {
      debugPrint('RazorpayService: call init() before launchPayment()');
      return;
    }

    final int amountPaise = (amountInRupees * 100).round();

    final options = <String, dynamic>{
      'key': kRazorpayKeyId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'N Events — Campus Portal',
      'description': description ?? eventTitle,
      'prefill': {
        'name': studentName,
        'email': email.isNotEmpty ? email : 'student@aits.edu.in',
        'contact': phone.isNotEmpty ? phone : '',
      },
      'theme': {'color': '#1E3C72'},
      'modal': {'confirm_close': true, 'animation': true},
      'notes': {'event': eventTitle, 'student': studentName},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('RazorpayService.launchPayment error: $e');
    }
  }

  /// Release Razorpay resources. Call in widget dispose().
  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    onSuccess = null;
    onFailure = null;
    onWallet = null;
  }

  static void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('Razorpay SUCCESS: paymentId=${response.paymentId}');
    onSuccess?.call(response);
  }

  static void _handleFailure(PaymentFailureResponse response) {
    debugPrint('Razorpay FAILURE: code=${response.code}, msg=${response.message}');
    onFailure?.call(response);
  }

  static void _handleWallet(ExternalWalletResponse response) {
    debugPrint('Razorpay EXTERNAL WALLET: ${response.walletName}');
    onWallet?.call(response);
  }
}
