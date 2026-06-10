import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/supervisor_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class SupervisorCheckinScreen extends StatefulWidget {
  const SupervisorCheckinScreen({super.key});

  @override
  State<SupervisorCheckinScreen> createState() =>
      _SupervisorCheckinScreenState();
}

class _SupervisorCheckinScreenState extends State<SupervisorCheckinScreen> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedType = 'Regular Visit';
  String? _selectedSiteId;
  bool _submitting = false;

  static const List<String> _checkinTypes = [
    'Regular Visit',
    'Audit',
    'Welfare Check',
    'Incident Response',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<SupervisorViewModel>();
    final sites = vm.assignedSites;
    final siteId = _selectedSiteId ?? (sites.isNotEmpty ? sites.first['id']?.toString() : null);

    if (siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No site selected')),
      );
      return;
    }

    setState(() => _submitting = true);
    final ok = await vm.submitCheckin(
      siteId: siteId,
      type: _selectedType,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Checked in successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SupervisorViewModel>();
    final sites = vm.assignedSites;

    _selectedSiteId ??= sites.isNotEmpty ? sites.first['id']?.toString() : null;

    return WorkerPanelScaffold(
      title: 'Clock In',
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WorkerStatusBanner(
              title: 'Supervisor Check-In',
              subtitle: 'Record your presence at the site as a supervisor.',
              icon: Icons.login,
              variant: WorkerStatusVariant.info,
            ),
            SizedBox(height: 16.h),
            _SectionLabel(label: 'Site'),
            SizedBox(height: 8.h),
            WorkerPanelCard(
              child: sites.isEmpty
                  ? Text(
                      'No sites assigned',
                      style: AppTypography.body().copyWith(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSiteId,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, size: 20.sp),
                        style: AppTypography.body().copyWith(
                          fontSize: 14.sp,
                          color: AppColors.textprimaryDark,
                        ),
                        onChanged: (v) => setState(() => _selectedSiteId = v),
                        items: sites.map((s) {
                          final id = s['id']?.toString() ?? '';
                          final name = s['name']?.toString() ?? id;
                          return DropdownMenuItem(value: id, child: Text(name));
                        }).toList(),
                      ),
                    ),
            ),
            SizedBox(height: 14.h),
            _SectionLabel(label: 'Check-In Type'),
            SizedBox(height: 8.h),
            WorkerPanelCard(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, size: 20.sp),
                  style: AppTypography.body().copyWith(
                    fontSize: 14.sp,
                    color: AppColors.textprimaryDark,
                  ),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
                  items: _checkinTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            _SectionLabel(label: 'Notes (optional)'),
            SizedBox(height: 8.h),
            WorkerPanelCard(
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any observations or notes…',
                  hintStyle: AppTypography.body().copyWith(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                ),
                style: AppTypography.body().copyWith(fontSize: 14.sp),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: WorkerActionButton(
                label: _submitting ? 'Checking In…' : 'Confirm Check-In',
                icon: Icons.check_circle_outline,
                variant: WorkerButtonVariant.secondary,
                onTap: _submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.body().copyWith(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
