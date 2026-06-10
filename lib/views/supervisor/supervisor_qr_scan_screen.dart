import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/supervisor_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class SupervisorQrScanScreen extends StatefulWidget {
  const SupervisorQrScanScreen({super.key});

  @override
  State<SupervisorQrScanScreen> createState() => _SupervisorQrScanScreenState();
}

class _SupervisorQrScanScreenState extends State<SupervisorQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    final qrValue = barcode!.rawValue!;
    if (!mounted) return;

    final confirmed = await _showConfirmSheet(qrValue);
    if (!mounted) return;

    if (confirmed == true) {
      final vm = context.read<SupervisorViewModel>();
      final siteId = vm.assignedSites.isNotEmpty
          ? vm.assignedSites.first['id']?.toString() ?? ''
          : '';

      final ok = await vm.saveQrScan(qrCode: qrValue, siteId: siteId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'QR scan saved successfully' : 'Failed to save scan'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
      Navigator.of(context).pop();
    } else {
      setState(() => _processing = false);
      await _controller.start();
    }
  }

  Future<bool?> _showConfirmSheet(String qrValue) {
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48.sp,
              height: 48.sp,
              decoration: BoxDecoration(
                color: AppColors.successBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.qr_code_scanner,
                  size: 26.sp, color: AppColors.successText),
            ),
            SizedBox(height: 12.h),
            Text(
              'QR Code Detected',
              style: AppTypography.title().copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.neutralIconBackground,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                qrValue,
                textAlign: TextAlign.center,
                style: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                  color: AppColors.textprimaryDark,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 16.h),
            WorkerBottomDualAction(
              leftLabel: 'Re-scan',
              rightLabel: 'Save Scan',
              onLeftTap: () => Navigator.of(ctx).pop(false),
              onRightTap: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan QR',
          style: AppTypography.title().copyWith(
            fontSize: 17.sp,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          _ScanOverlay(),
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const WorkerStatusBanner(
                  title: 'Point camera at a QR code',
                  subtitle: 'The scan will be saved with your user ID and site.',
                  icon: Icons.info_outline,
                  variant: WorkerStatusVariant.info,
                ),
              ],
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240.w,
        height: 240.w,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Stack(
          children: [
            _Corner(top: true, left: true),
            _Corner(top: true, left: false),
            _Corner(top: false, left: true),
            _Corner(top: false, left: false),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});
  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 24.w,
        height: 24.w,
        decoration: BoxDecoration(
          border: Border(
            top: top ? BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
            bottom: !top ? BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
            left: left ? BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
            right: !left ? BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
