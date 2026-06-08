import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/typography.dart';
import '../viewmodels/password_visibility.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final double? labelSize; // logical size in sp
  final bool obscureText; // initial obscure state
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final String? Function(String?)? validator;
  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;
  final double? height;
  final TextInputType? keyboardType;
  final Color? labelColor;
  final bool isPassword; // if true, show built-in password toggle
  final bool showPasswordToggle; // allow hiding toggle when needed
  final bool readOnly;
  final String? hintText;

  const AppTextField({
    Key? key,
    this.controller,
    this.label,
    this.labelSize,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.validator,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.height,
    this.labelColor,
    this.keyboardType,
    this.isPassword = false,
    this.showPasswordToggle = true,
    this.readOnly = false,
    this.hintText,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: widget.labelSize != null
          ? AppSizes.sp(widget.labelSize!)
          : null,
      color: widget.labelColor ?? AppColors.textprimaryDark,
    );

    final OutlineInputBorder baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius),
      borderSide: BorderSide(
        color: widget.borderColor ?? AppColors.strokemedium,
        width: widget.borderWidth,
      ),
    );

    Widget? suffix = widget.suffixIcon;

    // Use PasswordVisibility provider for password fields. Require provider in debug.
    PasswordVisibility? vis;
    try {
      vis = Provider.of<PasswordVisibility>(context);
    } catch (_) {
      vis = null;
    }

    if (widget.isPassword) {
      assert(
        vis != null,
        'PasswordVisibility provider required for password fields. Wrap the field tree with ChangeNotifierProvider<PasswordVisibility>.',
      );
      if (vis != null && widget.showPasswordToggle) {
        suffix = IconButton(
          icon: Icon(
            vis.obscured ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: widget.enabled ? vis.toggle : null,
        );
      }
    }

    final double? fixedHeight = widget.height;

    final EdgeInsets contentPadding = fixedHeight != null
        ? EdgeInsets.symmetric(vertical: 0, horizontal: AppSizes.w(16))
        : EdgeInsets.symmetric(
            vertical: AppSizes.h(12),
            horizontal: AppSizes.w(16),
          );

    final field = TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword
          ? (vis?.obscured ?? widget.obscureText)
          : widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppSizes.sp(14),
        color: AppColors.textprimaryDark,
      ),
      decoration: InputDecoration(
        // keep the field vertically roomy so the fixed `height` is respected
        isDense: false,
        labelText: widget.label,
        hintText: widget.hintText,
        labelStyle: labelStyle,
        // Reserve space for potential error text so the field doesn't resize.
        // Use a zero-sized error style so the red border can be shown without
        // changing the widget height.
        helperText: ' ',
        errorStyle: TextStyle(color: Colors.red, fontSize: 0, height: 0),
        errorMaxLines: 1,
        prefixIcon: widget.prefixIcon,
        prefixIconConstraints: BoxConstraints(
          minWidth: AppSizes.w(40),
          minHeight: AppSizes.h(24),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: widget.fillColor ?? Colors.grey.shade50,
        // Content padding depends on whether the caller set a fixed height.
        contentPadding: contentPadding,
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: baseBorder.borderSide.copyWith(
            color: widget.borderColor ?? AppColors.primary,
            width: widget.borderWidth > 0 ? widget.borderWidth : 1,
          ),
        ),
      ),
      textAlignVertical: TextAlignVertical.center,
    );

    if (fixedHeight != null) {
      return SizedBox(height: fixedHeight, child: field);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: AppSizes.h(40)),
      child: field,
    );
  }
}
