import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/widgets/app_card.dart';
import 'package:security_app/widgets/app_text.dart';
import 'package:security_app/widgets/custom_text_field.dart';
import 'package:security_app/widgets/primary_button.dart';
import 'package:security_app/widgets/space.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:security_app/routes/routes.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _didPrefillFromRole = false;
  bool _isAdminPrefill = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefillFromRole) {
      return;
    }

    final role = GoRouterState.of(context).uri.queryParameters['role'];
    if (role?.toLowerCase() == 'admin') {
      _isAdminPrefill = true;
      if (_usernameController.text.trim().isEmpty) {
        _usernameController.text = 'admin';
      }
      if (_departmentController.text.trim().isEmpty) {
        _departmentController.text = 'Administration';
      }
    }

    _didPrefillFromRole = true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();
      final nameParts = _fullNameController.text.trim().split(' ');
      final success = await authViewModel.register(
        first_name: nameParts.first,
        last_name: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // Navigation will be handled automatically by router
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w(24)),
            child: Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSpacer.vertical(40),
                      Center(
                        child: Image(
                          image: const AssetImage(
                            'assets/Icons/Background.png',
                          ),
                          height: AppSizes.h(64),
                          width: AppSizes.w(64),
                          fit: BoxFit.contain,
                        ),
                      ),
                      AppSpacer.vertical(10),
                      AppText(
                        'Shiftmate',
                        style: AppTypography.display().copyWith(
                          color: AppColors.textprimaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacer.vertical(5),
                      AppText(
                        'Workforce Management',
                        style: AppTypography.body().copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isAdminPrefill) ...[
                        AppSpacer.vertical(6),
                        AppText(
                          'Admin username is prefilled and locked',
                          style: AppTypography.body().copyWith(
                            color: AppColors.primary,
                            fontSize: AppSizes.sp(12),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      AppSpacer.vertical(20),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppText(
                              'Full Name',
                              style: AppTypography.body().copyWith(
                                fontSize: AppSizes.sp(16),
                                color: AppColors.textprimaryDark,
                              ),
                            ),
                            AppSpacer.vertical(10),
                            AppTextField(
                              controller: _fullNameController,
                              label: 'Enter full name',
                              labelSize: 16,
                              borderWidth: 1,
                              fillColor: Colors.grey.shade50,
                              labelColor: AppColors.textSecondary,
                              borderColor: AppColors.strokemedium,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                              enabled: !authViewModel.isLoading,
                            ),
                            AppSpacer.vertical(6),
                            AppText(
                              'Username',
                              style: AppTypography.body().copyWith(
                                fontSize: AppSizes.sp(16),
                                color: AppColors.textprimaryDark,
                              ),
                            ),
                            AppSpacer.vertical(10),
                            AppTextField(
                              controller: _usernameController,
                              label: 'Enter username',
                              labelSize: 16,
                              borderWidth: 1,
                              fillColor: Colors.grey.shade50,
                              labelColor: AppColors.textSecondary,
                              borderColor: AppColors.strokemedium,
                              readOnly: _isAdminPrefill,
                              suffixIcon: _isAdminPrefill
                                  ? Icon(
                                      Icons.lock_outline,
                                      color: AppColors.textSecondary,
                                    )
                                  : null,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a username';
                                }
                                if (value.trim().length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                return null;
                              },
                              enabled: !authViewModel.isLoading,
                            ),
                            AppSpacer.vertical(6),
                            AppText(
                              'Email',
                              style: AppTypography.body().copyWith(
                                fontSize: AppSizes.sp(16),
                                color: AppColors.textprimaryDark,
                              ),
                            ),
                            AppSpacer.vertical(10),
                            AppTextField(
                              controller: _emailController,
                              label: 'you@example.com',
                              labelSize: 16,
                              borderWidth: 1,
                              fillColor: Colors.grey.shade50,
                              labelColor: AppColors.textSecondary,
                              borderColor: AppColors.strokemedium,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              enabled: !authViewModel.isLoading,
                            ),
                            AppSpacer.vertical(6),
                            AppText(
                              'Department',
                              style: AppTypography.body().copyWith(
                                fontSize: AppSizes.sp(16),
                                color: AppColors.textprimaryDark,
                              ),
                            ),
                            AppSpacer.vertical(10),
                            AppTextField(
                              controller: _departmentController,
                              label: 'Department (optional)',
                              labelSize: 16,
                              borderWidth: 1,
                              fillColor: Colors.grey.shade50,
                              labelColor: AppColors.textSecondary,
                              borderColor: AppColors.strokemedium,
                              enabled: !authViewModel.isLoading,
                            ),
                            AppSpacer.vertical(6),
                            AppText(
                              'Password',
                              style: AppTypography.body().copyWith(
                                fontSize: AppSizes.sp(16),
                                color: AppColors.textprimaryDark,
                              ),
                            ),
                            AppSpacer.vertical(10),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Enter password',
                              labelSize: 16,
                              borderWidth: 1,
                              fillColor: Colors.grey.shade50,
                              labelColor: AppColors.textSecondary,
                              borderColor: AppColors.strokemedium,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              enabled: !authViewModel.isLoading,
                            ),
                            AppSpacer.vertical(6),
                            AppText(
                              'Confirm Password',
                              style: AppTypography.body().copyWith(
                                fontSize: AppSizes.sp(16),
                                color: AppColors.textprimaryDark,
                              ),
                            ),
                            AppSpacer.vertical(10),
                            AppTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm password',
                              labelSize: 16,
                              borderWidth: 1,
                              fillColor: Colors.grey.shade50,
                              labelColor: AppColors.textSecondary,
                              borderColor: AppColors.strokemedium,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              enabled: !authViewModel.isLoading,
                            ),
                            AppSpacer.vertical(16),
                            PrimaryButton(
                              onPressed: authViewModel.isLoading
                                  ? null
                                  : _handleSignup,
                              text: _isAdminPrefill
                                  ? 'Continue as Admin'
                                  : 'Create Account',
                              textColor: Colors.white,
                              buttonColor: AppColors.primary,
                              height: AppSizes.h(48),
                            ),
                          ],
                        ),
                      ),
                      AppSpacer.vertical(16),
                      PrimaryButton(
                        onPressed: authViewModel.isLoading
                            ? null
                            : () => context.go(Routes.login),
                        text: 'Back to Sign In',
                        textColor: AppColors.primary,
                        buttonColor: Colors.white,
                        height: AppSizes.h(48),
                      ),
                      AppSpacer.vertical(20),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
