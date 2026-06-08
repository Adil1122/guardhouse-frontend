import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final IconData? icon;
  final String? text;
  final Color? textColor;
  final Color? buttonColor;
  final double? height;
  final double? width;

  const PrimaryButton({
    Key? key,
    this.onPressed,
    this.child,
    this.icon,
    this.text,
    this.textColor,
    this.buttonColor,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = buttonColor ?? AppColors.primary;
    final fgColor = textColor; // only set if explicitly provided

    final buttonHeight = height;

    final style = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      padding: EdgeInsets.zero,
      minimumSize: buttonHeight != null ? Size(0, buttonHeight) : null,
    );

    final content =
        child ??
        Text(
          text ?? '',
          style: TextStyle(
            color: textColor,
            fontSize: AppSizes.sp(16),
            fontFamily: 'SFProText',
          ),
        );

    final buttonChild = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.w(20), color: textColor),
              SizedBox(width: AppSizes.w(8)),
              content,
            ],
          )
        : content;

    Widget button = ElevatedButton(
      onPressed: onPressed,

      style: style,
      child: buttonChild,
    );

    if (height != null || width != null) {
      // Use constraints so the button doesn't force overflow when parent is
      // smaller than the requested size. Treat width as maxWidth and height
      // as minHeight to preserve requested sizing without breaking layout.
      button = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width ?? double.infinity,
          minHeight: height ?? 0,
        ),
        child: button,
      );
    }

    return button;
  }
}
