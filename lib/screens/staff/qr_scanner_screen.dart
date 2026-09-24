import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../models/registration_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  Event? _selectedEvent;
  bool _torchOn = false;
  bool _isProcessing = false;
  int _scannedCount = 0;
  Registration? _lastResult;
  bool _lastScanSuccess = false;
  late AnimationController _resultAnimCtrl;
  late Animation<double> _resultOpacity;

  @override
  void initState() {
    super.initState();
    _resultAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _resultOpacity = CurvedAnimation(parent: _resultAnimCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _resultAnimCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _selectedEvent == null) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final code = barcode.rawValue!.trim();

    final reg = stateProvider.verifyParticipantCode(
      participantCode: code,
      eventId: _selectedEvent!.id,
    );

    setState(() {
      _lastResult = reg;
      _lastScanSuccess = reg != null;
      if (reg != null) _scannedCount++;
    });

    _resultAnimCtrl.forward(from: 0);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        _resultAnimCtrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final stateProvider = Provider.of<AppStateProvider>(context);
    final assignedEvents = authProvider.role == 'admin'
        ? stateProvider.events
        : stateProvider.getAssignedEvents(authProvider.assignedEventIds);

    if (_selectedEvent == null && assignedEvents.isNotEmpty) {
      _selectedEvent = assignedEvents.first;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'QR Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(authProvider.homeRoute);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? Colors.amber : Colors.white60,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white60),
            onPressed: () => _scannerController.switchCamera(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'personal') {
                authProvider.setPersonalAccountMode(true);
                context.go('/student');
              } else if (val == 'dashboard') {
                authProvider.setPersonalAccountMode(false);
                context.go(authProvider.homeRoute);
              } else if (val == 'logout') {
                authProvider.logout();
                context.go('/auth');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'personal',
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, size: 18, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('Shift to Personal Account'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dashboard',
                child: Row(
                  children: [
                    Icon(Icons.dashboard_rounded, size: 18, color: Color(0xFF7C3AED)),
                    SizedBox(width: 8),
                    Text('Worker / Staff Dashboard'),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Event selector
          if (assignedEvents.isNotEmpty)
            Container(
              color: const Color(0xFF0D1117),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: DropdownButtonFormField<Event>(
                initialValue: _selectedEvent,
                hint: const Text('Select event to scan for…',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                dropdownColor: const Color(0xFF161B22),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  prefixIcon: const Icon(Icons.event_rounded, color: Color(0xFF2563EB), size: 18),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: assignedEvents
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.title, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (e) => setState(() {
                  _selectedEvent = e;
                  _scannedCount = 0;
                }),
              ),
            ),
          if (assignedEvents.isEmpty)
            Container(
              color: const Color(0xFF0D1117),
              padding: const EdgeInsets.all(20),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No events assigned. Contact admin to assign events.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Camera View
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera feed
                _selectedEvent != null
                    ? MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: Text(
                            'Select an event above\nto start scanning',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                          ),
                        ),
                      ),

                // Scan frame overlay
                if (_selectedEvent != null)
                  CustomPaint(
                    painter: _ScanFramePainter(),
                    child: const SizedBox.expand(),
                  ),

                // Result overlay
                if (_selectedEvent != null)
                  Positioned(
                    bottom: 100,
                    left: 24,
                    right: 24,
                    child: FadeTransition(
                      opacity: _resultOpacity,
                      child: _lastResult != null || _isProcessing
                          ? _buildResultCard()
                          : const SizedBox.shrink(),
                    ),
                  ),

                // Scan counter
                if (_selectedEvent != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '$_scannedCount verified',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Instruction text
                if (_selectedEvent != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded,
                              color: Color(0xFF2563EB), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            _selectedEvent!.title,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final success = _lastScanSuccess;
    final color = success ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = success ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final tCode = _lastResult != null
        ? _lastResult!.id.substring(0, _lastResult!.id.length < 10 ? _lastResult!.id.length : 10).toUpperCase()
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  success ? 'TICKET VERIFIED VALID ✓' : 'NOT REGISTERED ✗',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                if (success && _lastResult != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _lastResult!.fullName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Roll: ${_lastResult!.rollNumber} • Branch: ${_lastResult!.department}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Code: $tCode',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
                if (!success)
                  const Text(
                    'This code is not registered for the selected event.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the scan frame corners overlay
class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const frameSize = 220.0;
    const cornerLen = 28.0;

    final left = cx - frameSize / 2;
    final top = cy - frameSize / 2;
    final right = cx + frameSize / 2;
    final bottom = cy + frameSize / 2;

    // Dim overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    // Clear the scan window
    canvas.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      Paint()
        ..blendMode = BlendMode.clear
        ..color = Colors.transparent,
    );

    // Corner TL
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), paint);
    // Corner TR
    canvas.drawLine(Offset(right - cornerLen, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLen), paint);
    // Corner BL
    canvas.drawLine(Offset(left, bottom - cornerLen), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLen, bottom), paint);
    // Corner BR
    canvas.drawLine(Offset(right - cornerLen, bottom), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
