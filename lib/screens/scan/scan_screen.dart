import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Scan modes available in the capture screen.
enum ScanMode { card, qr, nfc }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  ScanMode _mode = ScanMode.card;
  bool _flashOn = false;
  bool _isCapturing = false;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  MobileScannerController? _qrController;
  final ImagePicker _imagePicker = ImagePicker();

  // ----------------------------------------------------------
  // Lifecycle
  // ----------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _disposeQrController();
    super.dispose();
  }

  // ----------------------------------------------------------
  // QR controller helpers
  // ----------------------------------------------------------

  void _initQrController() {
    _disposeQrController();
    try {
      _qrController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: _flashOn,
      );
    } catch (_) {
      // Camera unavailable (simulator / permissions denied).
      _qrController = null;
    }
  }

  void _disposeQrController() {
    try {
      _qrController?.dispose();
    } catch (_) {
      // Ignore disposal errors.
    }
    _qrController = null;
  }

  // ----------------------------------------------------------
  // Mode switching
  // ----------------------------------------------------------

  void _switchMode(ScanMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _flashOn = false;
    });
    if (mode == ScanMode.qr) {
      _initQrController();
    } else {
      _disposeQrController();
    }
  }

  // ----------------------------------------------------------
  // Flash toggle
  // ----------------------------------------------------------

  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    if (_mode == ScanMode.qr) {
      try {
        _qrController?.toggleTorch();
      } catch (_) {}
    }
  }

  // ----------------------------------------------------------
  // Capture actions
  // ----------------------------------------------------------

  Future<void> _onCapture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    switch (_mode) {
      case ScanMode.card:
        await _captureCard();
        break;
      case ScanMode.qr:
        // QR detection happens automatically via the scanner callback.
        // Pressing capture in QR mode acts as a manual fallback (same as card).
        await _captureCard();
        break;
      case ScanMode.nfc:
        // NFC reading would be triggered separately; treat capture as card scan.
        await _captureCard();
        break;
    }
  }

  Future<void> _captureCard() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (!mounted) return;

      if (photo != null) {
        _showDetectionToast();
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.push('/review');
      }
    } catch (_) {
      // Camera unavailable / permission denied. Show toast and navigate anyway
      // so the reviewer screen can be reached during development.
      if (!mounted) return;
      _showDetectionToast();
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.push('/review');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_isCapturing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    setState(() => _isCapturing = true);
    _showDetectionToast();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isCapturing = false);
        context.push('/review');
      }
    });
  }

  void _showDetectionToast() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                AppStrings.cardDetected,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          duration: const Duration(milliseconds: 900),
        ),
      );
  }

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview (QR mode only)
          if (_mode == ScanMode.qr && _qrController != null)
            MobileScanner(
              controller: _qrController!,
              onDetect: _onQrDetected,
              errorBuilder: (context, error, child) {
                return const Center(
                  child: Text(
                    'Camera non disponible',
                    style: TextStyle(color: AppColors.white),
                  ),
                );
              },
            ),

          // Dark overlay for non-QR modes
          if (_mode != ScanMode.qr)
            Container(color: Colors.black),

          // Top bar
          _buildTopBar(context),

          // Viewport + scan line
          Center(child: _buildViewport()),

          // Hint text
          Positioned(
            bottom: 240,
            left: 0,
            right: 0,
            child: Text(
              AppStrings.scanHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white.withOpacity(0.7),
              ),
            ),
          ),

          // Mode selector
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: _buildModeSelector(),
          ),

          // Capture button
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Center(child: _buildCaptureButton()),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Top bar
  // ----------------------------------------------------------

  Widget _buildTopBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back
          _CircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
          ),
          // Title
          Text(
            AppStrings.scanTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          // Flash toggle
          _CircleButton(
            icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            active: _flashOn,
            onTap: _toggleFlash,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Scan viewport with corner brackets + animated line
  // ----------------------------------------------------------

  Widget _buildViewport() {
    const double viewportSize = 280;

    return SizedBox(
      width: viewportSize,
      height: viewportSize,
      child: AnimatedBuilder(
        animation: _scanLineAnimation,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 4 corner brackets
              ..._buildCornerBrackets(viewportSize),

              // Animated scan line
              Positioned(
                top: _scanLineAnimation.value * (viewportSize - 4),
                left: 20,
                right: 20,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0),
                        AppColors.accent,
                        AppColors.accent.withOpacity(0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCornerBrackets(double size) {
    const double bracketLength = 32;
    const double bracketThickness = 3;

    Widget bracket({
      required double top,
      required double left,
      required double right,
      required double bottom,
      required bool flipH,
      required bool flipV,
    }) {
      return Positioned(
        top: top == -1 ? null : top,
        left: left == -1 ? null : left,
        right: right == -1 ? null : right,
        bottom: bottom == -1 ? null : bottom,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
          child: SizedBox(
            width: bracketLength,
            height: bracketLength,
            child: CustomPaint(
              painter: _CornerBracketPainter(
                color: AppColors.accent,
                strokeWidth: bracketThickness,
                radius: 6,
              ),
            ),
          ),
        ),
      );
    }

    return [
      // Top-left
      bracket(top: 0, left: 0, right: -1, bottom: -1, flipH: false, flipV: false),
      // Top-right
      bracket(top: 0, left: -1, right: 0, bottom: -1, flipH: true, flipV: false),
      // Bottom-left
      bracket(top: -1, left: 0, right: -1, bottom: 0, flipH: false, flipV: true),
      // Bottom-right
      bracket(top: -1, left: -1, right: 0, bottom: 0, flipH: true, flipV: true),
    ];
  }

  // ----------------------------------------------------------
  // Mode selector (Carte / QR Code / NFC)
  // ----------------------------------------------------------

  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeButton(
          label: AppStrings.scanCard,
          icon: Icons.credit_card_rounded,
          active: _mode == ScanMode.card,
          onTap: () => _switchMode(ScanMode.card),
        ),
        const SizedBox(width: 12),
        _ModeButton(
          label: AppStrings.scanQR,
          icon: Icons.qr_code_scanner_rounded,
          active: _mode == ScanMode.qr,
          onTap: () => _switchMode(ScanMode.qr),
        ),
        const SizedBox(width: 12),
        _ModeButton(
          label: AppStrings.scanNFC,
          icon: Icons.nfc_rounded,
          active: _mode == ScanMode.nfc,
          onTap: () => _switchMode(ScanMode.nfc),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Capture button
  // ----------------------------------------------------------

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _onCapture,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isCapturing ? 0.5 : 1.0,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 4),
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Supporting widgets
// ===========================================================================

/// Translucent circle button used in the top bar.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withOpacity(0.25)
              : AppColors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: active ? AppColors.accent : AppColors.white,
          size: 22,
        ),
      ),
    );
  }
}

/// A mode selector button (Carte / QR Code / NFC).
class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? AppColors.accentGradient : null,
          color: active ? null : AppColors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: active
              ? null
              : Border.all(
                  color: AppColors.white.withOpacity(0.15),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? AppColors.white
                  : AppColors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? AppColors.white
                    : AppColors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Corner bracket painter
// ===========================================================================

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, radius)
      ..arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
      )
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}

