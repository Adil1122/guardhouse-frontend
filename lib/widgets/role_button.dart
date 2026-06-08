import 'package:flutter/material.dart';
import 'package:security_app/widgets/space.dart';
import '../constants/app_constants.dart';
import '../constants/typography.dart';

class RoleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const RoleButton({Key? key, required this.label, required this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF3F4F6),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: AppSizes.h(14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTypography.body()),
            AppSpacer(width: AppSizes.w(10)),
            const Icon(Icons.arrow_forward, color: Colors.black87, size: 25),
          ],
        ),
      ),
    );
  }
}
