import 'package:flutter/material.dart';
import '../constants/typography.dart';
import '../constants/app_constants.dart';

class AppText extends StatelessWidget {
  final String text;
  final double? size; // logical size in sp (pass raw number, will be scaled)
  final FontWeight? weight;
  final Color? color;
  final TextAlign? align;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  const AppText(
    this.text, {
    Key? key,
    this.size,
    this.weight,
    this.color,
    this.align,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fallbackBody = AppTypography.body();
    final base =
        style ?? Theme.of(context).textTheme.bodyMedium ?? fallbackBody;

    final double? fontSize = size != null ? AppSizes.sp(size!) : base.fontSize;

    final textStyle = base.copyWith(
      fontFamily: AppTypography.fontFamily,
      fontSize: fontSize,
      fontWeight: weight ?? base.fontWeight,
      color: color ?? base.color,
    );

    return Text(
      text,
      style: textStyle,
      textAlign: textAlign ?? align,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
