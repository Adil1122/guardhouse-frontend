import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class WorkerQrScanScreen extends StatefulWidget {
  const WorkerQrScanScreen({super.key});

  @override
  State<WorkerQrScanScreen> createState() => _WorkerQrScanScreenState();
}

class _WorkerQrScanScreenState extends State<WorkerQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _codeController = TextEditingController();
  bool _processing = false;
  bool _torchOn = false;
  bool _showManual = false;

  @override
  void dispose() {
    _controller.dispose();
    _codeController.dispose();
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
      await _saveCheckin(qrValue);
    } else {
      setState(() => _processing = false);
      await _controller.start();
    }
  }

  Future<void> _saveCheckin(String qrValue) async {
    final vm = context.read<WorkerViewModel>();
    final ok = await vm.submitCheckin(
      location: qrValue,
      notes: 'QR checkpoint scan',
      type: 'qr_scan',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Checkpoint "$qrValue" logged successfully' : 'Failed to save scan – try again',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) Navigator.of(context).pop();
    if (!ok) {
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
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
              rightLabel: 'Log Checkpoint',
              onLeftTap: () => Navigator.of(ctx).pop(false),
              onRightTap: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitManualCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _processing = true);
    await _saveCheckin(code);
    _codeController.clear();
    setState(() {
      _processing = false;
      _showManual = false;
    });
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
          IconButton(
            onPressed: () => setState(() => _showManual = !_showManual),
            icon: Icon(
              _showManual ? Icons.qr_code_scanner : Icons.keyboard,
              color: Colors.white,
            ),
            tooltip: _showManual ? 'Use camera' : 'Enter code manually',
          ),
        ],
      ),
      body: _showManual ? _buildManualEntry() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
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
          child: const WorkerStatusBanner(
            title: 'Point camera at a checkpoint QR code',
            subtitle: 'Tap the keyboard icon above to enter a code manually.',
            icon: Icons.info_outline,
            variant: WorkerStatusVariant.info,
          ),
        ),
        if (_processing)
          Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkerStatusBanner(
            title: 'Enter Checkpoint Code',
            subtitle: 'Type the code printed on the checkpoint label.',
            icon: Icons.info_outline,
            variant: WorkerStatusVariant.info,
          ),
          SizedBox(height: 20.h),
          WorkerPanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkpoint Code',
                  style: AppTypography.body().copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textprimaryDark,
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. CP-001',
                    hintStyle: AppTypography.body().copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.tag,
                      size: 20.sp,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                  ),
                  style: AppTypography.body().copyWith(fontSize: 14.sp),
                  onSubmitted: (_) => _submitManualCode(),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: WorkerActionButton(
                    label: _processing ? 'Saving…' : 'Log Checkpoint',
                    icon: Icons.check_circle_outline,
                    onTap: _processing ? null : _submitManualCode,
                  ),
                ),
              ],
            ),
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
            top: top
                ? BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
            bottom: !top
                ? BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
            left: left
                ? BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
            right: !left
                ? BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
