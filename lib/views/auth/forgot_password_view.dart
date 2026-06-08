import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/routes/routes.dart';
import 'package:security_app/widgets/app_card.dart';
import 'package:security_app/widgets/app_text.dart';
import 'package:security_app/widgets/custom_text_field.dart';
import 'package:security_app/widgets/primary_button.dart';
import 'package:security_app/widgets/space.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final success = await authViewModel.forgotPassword(email);

    if (!mounted) {
      return;
    }

    if (success) {
      context.push(
        '${Routes.passwordResetLinkSent}?email=${Uri.encodeComponent(email)}',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authViewModel.errorMessage ?? 'Failed to send reset instructions',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
              child: Builder(
                builder: (context) {
                  final authViewModel = context.watch<AuthViewModel>();
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSpacer(height: AppSizes.h(80)),
                        // Icon
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
                        AppSpacer(height: AppSizes.h(15)),
                        Text(
                          'Forgot Password',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(color: AppColors.textprimaryDark),

                          textAlign: TextAlign.center,
                        ),
                        AppSpacer(height: AppSizes.h(10)),
                        Text(
                          "We'll help you get back in",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacer(height: AppSizes.h(30)),

                        AppCard(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppText(
                                'Email Address',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.textprimaryDark,
                                    ),
                              ),
                              AppSpacer(height: AppSizes.h(10)),
                              AppTextField(
                                controller: _emailController,
                                label: "You@gmail.com",
                                labelSize: 16,
                                borderWidth: 1,
                                fillColor: Colors.grey.shade50,
                                labelColor: AppColors.textSecondary,
                                borderColor: AppColors.strokemedium,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                                enabled: !authViewModel.isLoading,
                              ),

                              AppText(
                                "We'll send reset instructions to your email",
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: AppSizes.sp(10),
                                    ),
                              ),
                              AppSpacer(height: AppSizes.h(16)),
                              PrimaryButton(
                                onPressed: authViewModel.isLoading
                                    ? null
                                    : _handleForgotPassword,
                                text: 'Send Reset Link',
                                textColor: Colors.white,
                                height: AppSizes.h(48),

                                buttonColor: AppColors.primary,
                              ),

                              AppSpacer(height: AppSizes.h(24)),
                              // Back to Login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.arrow_back,
                                    size: 24.0,
                                    color: Colors.black,
                                  ),
                                  TextButton(
                                    onPressed: authViewModel.isLoading
                                        ? null
                                        : () => context.go(Routes.login),
                                    child: AppText(
                                      'Back to Sign In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: AppSizes.sp(16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Email Field
                        // TextFormField(
                        //   controller: _emailController,
                        //   keyboardType: TextInputType.emailAddress,
                        //   decoration: const InputDecoration(
                        //     labelText: 'Email',
                        //     prefixIcon: Icon(Icons.email),
                        //     border: OutlineInputBorder(),
                        //     hintText: 'Enter your email address',
                        //   ),
                        //   validator: (value) {
                        //     if (value == null || value.isEmpty) {
                        //       return 'Please enter your email';
                        //     }
                        //     if (!value.contains('@')) {
                        //       return 'Please enter a valid email';
                        //     }
                        //     return null;
                        //   },
                        //   enabled: !authViewModel.isLoading,
                        // ),
                        // const SizedBox(height: 24),

                        // // Send Reset Link Button
                        // ElevatedButton(
                        //   onPressed: authViewModel.isLoading
                        //       ? null
                        //       : _handleForgotPassword,
                        //   style: ElevatedButton.styleFrom(
                        //     padding: const EdgeInsets.symmetric(vertical: 16),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(8),
                        //     ),
                        //   ),
                        //   child: authViewModel.isLoading
                        //       ? const SizedBox(
                        //           height: 20,
                        //           width: 20,
                        //           child: CircularProgressIndicator(
                        //             strokeWidth: 2,
                        //             color: Colors.white,
                        //           ),
                        //         )
                        //       : const Text(
                        //           'Send Reset Link',
                        //           style: TextStyle(fontSize: 16),
                        //         ),
                        // ),
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
}
