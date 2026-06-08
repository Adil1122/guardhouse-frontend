import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:security_app/views/admin/steps/site_checkpoints_step.dart';
import 'package:security_app/views/admin/steps/site_documents_step.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../models/site_models.dart';
import '../../providers/site_creation_provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import 'steps/site_details_step.dart';
import 'steps/site_contacts_step.dart';
import 'steps/site_staff_preferences_step.dart';

class SiteCreationWizard extends StatelessWidget {
  final SiteDetails? initialDetails;
  final List<SiteContact>? initialContacts;
  final List<SiteCheckpoint>? initialCheckpoints;
  final List<SiteDocument>? initialDocuments;
  final List<SitePreference>? initialPreferences;
  final SiteCreationStep? initialStep; // Add initial step for development

  const SiteCreationWizard({
    super.key,
    this.initialDetails,
    this.initialContacts,
    this.initialCheckpoints,
    this.initialDocuments,
    this.initialPreferences,
    this.initialStep,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SiteCreationProvider(
        initialDetails: initialDetails,
        initialContacts: initialContacts,
        initialCheckpoints: initialCheckpoints,
        initialDocuments: initialDocuments,
        initialPreferences: initialPreferences,
        initialStep: initialStep,
      ),
      child: const _SiteCreationWizardContent(),
    );
  }
}

class _SiteCreationWizardContent extends StatefulWidget {
  const _SiteCreationWizardContent();

  @override
  State<_SiteCreationWizardContent> createState() =>
      _SiteCreationWizardContentState();
}

class _SiteCreationWizardContentState
    extends State<_SiteCreationWizardContent> {
  final PageController _pageController = PageController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Position the PageController to the initial step if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SiteCreationProvider>();
      if (provider.currentStepIndex > 0) {
        _pageController.animateToPage(
          provider.currentStepIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _getCurrentStepWidget(SiteCreationStep step) {
    switch (step) {
      case SiteCreationStep.details:
        return const SiteDetailsStep();
      case SiteCreationStep.contacts:
        return const SiteContactsStep();
      case SiteCreationStep.checkpoints:
        return const SiteCheckpointsStep();
      case SiteCreationStep.documents:
        return const SiteDocumentsStep();
      case SiteCreationStep.preferences:
        return const SiteStaffPreferencesStep();
      // Note: Use 'preferences' case for staff preferences step
    }
  }

  Future<void> _handleNext() async {
    final provider = context.read<SiteCreationProvider>();

    if (provider.currentStepIndex < provider.totalSteps - 1) {
      provider.goNext();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handlePrevious() async {
    final provider = context.read<SiteCreationProvider>();

    if (provider.canGoPrevious) {
      provider.goPrevious();
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<SiteCreationProvider>();
      final adminViewModel = context.read<AdminViewModel>();
      final siteDetails = provider.details;

      bool success = await adminViewModel.saveFullSite(
        details: siteDetails,
        contacts: provider.contacts,
        checkpoints: provider.checkpoints,
        documents: provider.documents,
        preferences: provider.preferences,
        isEdit: provider.isEdit,
        onSiteCreated: (newSiteId) {
          provider.updateDetails(provider.details.copyWith(id: newSiteId));
          provider.isEdit = true;
        },
      );

      if (success && mounted) {
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.isEdit
                  ? 'Site updated successfully'
                  : 'Site created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adminViewModel.errorMessage ??
                  (provider.isEdit
                      ? 'Failed to update site'
                      : 'Failed to create site'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SiteCreationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
            title: Text(
              provider.isEdit ? 'Edit Site' : 'Create Site',
              style: AppTypography.title().copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(80.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Progress bar
                    LinearProgressIndicator(
                      value: provider.progress,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 4.h,
                    ),
                    SizedBox(height: 12.h),
                    // Step info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stepTitle(provider.currentStep),
                                style: AppTypography.body().copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                stepDescription(provider.currentStep),
                                style: AppTypography.body().copyWith(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${provider.currentStepIndex + 1} of ${provider.totalSteps}',
                          style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: SiteCreationStep.values
                .map((step) => _getCurrentStepWidget(step))
                .toList(),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              24.w,
              16.h,
              24.w,
              MediaQuery.of(context).padding.bottom + 16.h,
            ),
            child: Row(
              children: [
                if (provider.canGoPrevious)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _handlePrevious,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: Text(
                        'Previous',
                        style: AppTypography.button().copyWith(
                          color: AppColors.primary,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                if (provider.canGoPrevious) SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || !provider.canGoNext)
                        ? null
                        : (provider.currentStepIndex == provider.totalSteps - 1)
                            ? _handleSubmit
                            : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            (provider.currentStepIndex ==
                                    provider.totalSteps - 1)
                                ? (provider.isEdit
                                    ? 'Update Site'
                                    : 'Create Site')
                                : 'Next',
                            style: AppTypography.button().copyWith(
                              color: Colors.white,
                              fontSize: 16.sp,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
