import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final bool expand;

  const AppCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.width,
    this.height,
    this.expand = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);

    if (expand) {
      content = SizedBox.expand(child: content);
    } else if (width != null || height != null) {
      // Use flexible constraints instead of a hard-sized box so the card can
      // still adapt on small screens (e.g., landscape) and avoid overflow.
      content = ConstrainedBox(
        constraints: BoxConstraints(
          // allow the card to be at most the requested width, but not
          // force a larger width than available
          maxWidth: width ?? double.infinity,
          // treat provided height as a minimum height rather than fixed
          minHeight: height ?? 0,
        ),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, 4), // positive Y -> shadow below only
            blurRadius: 6,
            spreadRadius: -4, // reduce lateral spread to avoid left/right glow
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, 10), // positive Y -> shadow below only
            blurRadius: 15,
            spreadRadius: -3, // reduce lateral spread to avoid left/right glow
          ),
        ],
      ),
      child: Card(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        child: content,
      ),
    );
  }
}
