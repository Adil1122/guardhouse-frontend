import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:security_app/widgets/app_text.dart';
import 'package:security_app/widgets/custom_text_field.dart';
import 'package:security_app/widgets/role_button.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/password_visibility.dart';
import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import 'package:security_app/routes/routes.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/space.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();
      final success = await authViewModel.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        final role = authViewModel.currentUser?['role'];
        if (role != null) {
          if (role.toString().contains('admin')) {
            context.go(Routes.admin);
          } else if (role.toString().contains('supervisor')) {
            context.go(Routes.supervisor);
          } else if (role.toString().contains('security-officer')) {
            context.go(Routes.worker);
          }
        }
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
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
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
                        // Logo or App Name
                        Center(
                          child: Image(
                            image: const AssetImage(
                              'assets/Icons/Background.png',
                            ),
                            height: AppSizes.h(64),
                            width: AppSizes.w(64),
                            fit: BoxFit.contain,
                          ),
                          // SvgPicture.asset(
                          //   'assets/Icons/shiftmate_logo_white.svg',
                          //   height: AppSizes.h(64),
                          //   width: AppSizes.w(64),
                          //   fit: BoxFit.contain,
                          // ),
                        ),
                        AppSpacer.vertical(10),

                        AppText(
                          'Shiftmate',
                          style: AppTypography.display().copyWith(
                            color: AppColors.textprimaryDark,
                          ),
                          align: TextAlign.center,
                        ),
                        AppSpacer.vertical(5),

                        AppText(
                          'Workforce Management',
                          style: AppTypography.body().copyWith(
                            color: AppColors.textSecondary,
                          ),
                          align: TextAlign.center,
                        ),
                        AppSpacer.vertical(20),

                        ChangeNotifierProvider(
                          create: (_) => PasswordVisibility(obscured: true),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Email Field
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
                                  label: "Enter Email",
                                  labelSize: 16,
                                  borderWidth: 1,
                                  fillColor: Colors.grey.shade50,
                                  labelColor: AppColors.textSecondary,
                                  borderColor: AppColors.strokemedium,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your Email';
                                    }
                                    return null;
                                  },
                                  enabled: !authViewModel.isLoading,
                                ),

                                AppText(
                                  'Password',
                                  style: AppTypography.body().copyWith(
                                    fontSize: AppSizes.sp(16),
                                    color: AppColors.textprimaryDark,
                                  ),
                                ),
                                AppSpacer.vertical(10),

                                // AppTextField(
                                //   controller: _usernameController,
                                //   label: 'Enter username',
                                //   labelSize: 14,
                                //   fillColor: Colors.grey.shade50,
                                //   borderColor: const Color(0xFFE5E7EB),
                                //   borderWidth: 1,
                                //   height: 50,

                                // Password Field
                                AppTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  labelSize: 16,
                                  isPassword: true,
                                  fillColor: Colors.grey.shade50,
                                  labelColor: AppColors.textSecondary,
                                  borderColor: AppColors.strokemedium,
                                  borderWidth: 1,

                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                  enabled: !authViewModel.isLoading,
                                ),

                                if (authViewModel.errorMessage != null && authViewModel.errorMessage!.isNotEmpty) ...[
                                  AppSpacer.vertical(10),
                                  Text(
                                    authViewModel.errorMessage!,
                                    style: AppTypography.body().copyWith(
                                      color: Colors.red.shade600,
                                      fontSize: AppSizes.sp(13),
                                    ),
                                  ),
                                ],

                                AppSpacer.vertical(15),

                                // Login Button
                                PrimaryButton(
                                  onPressed: authViewModel.isLoading
                                      ? null
                                      : _handleLogin,
                                  buttonColor: AppColors.primary,
                                  text: "Sign In",

                                  height: AppSizes.h(48),
                                  textColor: AppColors.background,
                                ),
                                // PrimaryButton(
                                //   onPressed: authViewModel.isLoading
                                //       ? null
                                //       : _handleLogin,
                                //   child: authViewModel.isLoading
                                //       ? SizedBox(
                                //           height: AppSizes.h(20),
                                //           width: AppSizes.w(20),
                                //           child: const CircularProgressIndicator(
                                //             strokeWidth: 2,
                                //             color: Colors.white,
                                //           ),
                                //         )
                                //       : const Text('Login'),
                                // ),
                                AppSpacer.vertical(12),

                                // Forgot Password Link
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    onPressed: () =>
                                        context.push(Routes.forgotPassword),
                                    child: Text(
                                      'Forgot Password?',
                                      style: AppTypography.body().copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        AppSpacer.vertical(20),

                        // // Divider
                        // Row(
                        //   children: [
                        //     const Expanded(child: Divider()),
                        //     Padding(
                        //       padding: EdgeInsets.symmetric(
                        //         horizontal: AppSizes.w(12),
                        //       ),
                        //       child: Text('OR', style: AppTypography.label()),
                        //     ),
                        //     const Expanded(child: Divider()),
                        //   ],
                        // ),
                        // AppSpacer.vertical(20),

                        // // Sign Up Button
                        // OutlinedButton(
                        //   onPressed: authViewModel.isLoading
                        //       ? null
                        //       : () => context.push('/signup'),
                        //   style: OutlinedButton.styleFrom(
                        //     padding: EdgeInsets.symmetric(
                        //       vertical: AppSizes.h(14),
                        //     ),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(
                        //         AppSizes.radius,
                        //       ),
                        //     ),
                        //   ),
                        //   child: const Text('Create New Account'),
                        // ),
                        // AppSpacer.vertical(12),

                        // // Help Text
                        // Text(
                        //   'Demo: Use "admin", "supervisor", or "worker" as username prefix',
                        //   style: AppTypography.label().copyWith(
                        //     color: AppColors.textSecondary,
                        //     fontStyle: FontStyle.italic,
                        //   ),
                        //   textAlign: TextAlign.center,
                        // ),
                        // AppSpacer.vertical(20),

                                                AppSpacer.vertical(20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Role buttons moved to `lib/widgets/role_button.dart` as `RoleButton`.
}
