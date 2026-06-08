import 'package:flutter/widgets.dart';
import '../constants/app_constants.dart';

/// A small reusable spacer widget that applies ScreenUtil scaling using
/// `AppSizes.h` / `AppSizes.w` helpers when provided with raw values.
class AppSpacer extends StatelessWidget {
  final double? height;
  final double? width;

  const AppSpacer({Key? key, this.height, this.width}) : super(key: key);

  /// Vertical spacer by pixels (will be scaled via AppSizes.h)
  factory AppSpacer.vertical(double h) => AppSpacer(height: h);

  /// Horizontal spacer by pixels (will be scaled via AppSizes.w)
  factory AppSpacer.horizontal(double w) => AppSpacer(width: w);

  @override
  Widget build(BuildContext context) {
    final double? h = height != null ? AppSizes.h(height!) : null;
    final double? w = width != null ? AppSizes.w(width!) : null;
    return SizedBox(height: h, width: w);
  }
}
