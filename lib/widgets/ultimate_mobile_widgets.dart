import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as import_cupertino;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_constants.dart';
import '../constants/typography.dart';

/// Ultimate Mobile UI Kit: A collection of widgets specifically designed 
/// to handle Android rendering bugs where data doesn't populate in standard 
/// Flutter form fields.

// Ultimate Mobile TextField Solution
class UltimateMobileTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final bool obscureText;
  final int? maxLines;
  final bool readOnly;
  final void Function(String?)? onSaved;
  final void Function(String?)? onChanged;

  const UltimateMobileTextField({
    super.key,
    required this.controller,
    this.initialValue,
    this.validator,
    this.keyboardType,
    this.decoration,
    this.obscureText = false,
    this.maxLines = 1,
    this.readOnly = false,
    this.onSaved,
    this.onChanged,
  });

  @override
  State<UltimateMobileTextField> createState() => _UltimateMobileTextFieldState();
}

class _UltimateMobileTextFieldState extends State<UltimateMobileTextField> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    final text = widget.initialValue ?? widget.controller.text;
    _internalController = TextEditingController(text: text);
    
    // Ensure external controller is in sync initially
    if (widget.initialValue != null && widget.controller.text != widget.initialValue) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  void didUpdateWidget(UltimateMobileTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the external controller's text changed FROM OUTSIDE (not by our own typing),
    // we must sync our internal one.
    if (widget.controller.text != _internalController.text) {
      _internalController.text = widget.controller.text;
      debugPrint('ULTIMATE MOBILE TEXTFIELD: External sync: "${_internalController.text}"');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deco = widget.decoration ?? const InputDecoration();

    return TextFormField(
      controller: _internalController,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      decoration: deco.copyWith(
        labelStyle: AppTypography.body().copyWith(
          fontSize: 13.sp,
          color: const Color(0xFF6B7280),
        ),
        hintStyle: AppTypography.body().copyWith(
          fontSize: 14.sp,
          color: const Color(0xFF9CA3AF),
        ),
        filled: true,
        fillColor: deco.fillColor ?? const Color(0xFFF1F1F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
      style: AppTypography.body().copyWith(
        fontSize: 14.sp,
        color: widget.readOnly ? const Color(0xFF6B7280) : const Color(0xFF1F2937),
      ),
      validator: widget.validator,
      onChanged: (value) {
        // Sync to external controller immediately
        widget.controller.text = value;
        widget.onChanged?.call(value);
      },
      onSaved: widget.onSaved,
    );
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }
}

// Ultimate Mobile Dropdown Solution - Matching Site Management style
class UltimateMobileDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String? Function(T?)? validator;
  final InputDecoration? decoration;
  final void Function(T?)? onChanged;
  final String? hintText;

  const UltimateMobileDropdown({
    super.key,
    this.value,
    required this.items,
    this.validator,
    this.decoration,
    this.onChanged,
    this.hintText,
  });

  @override
  State<UltimateMobileDropdown<T>> createState() => _UltimateMobileDropdownState<T>();
}

class _UltimateMobileDropdownState<T> extends State<UltimateMobileDropdown<T>> {
  T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
  }

  @override
  void didUpdateWidget(UltimateMobileDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _selectedValue = widget.value;
      });
      debugPrint('ULTIMATE MOBILE DROPDOWN: Updated value: "$_selectedValue"');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync if values differ
    if (widget.value != _selectedValue) {
      _selectedValue = widget.value;
    }

    final deco = widget.decoration ?? const InputDecoration();
    
    // Deduplicate items to prevent Flutter assertion crashes
    final seenValues = <T?>{};
    final uniqueItems = <DropdownMenuItem<T>>[];
    for (final item in widget.items) {
      if (!seenValues.contains(item.value)) {
        seenValues.add(item.value);
        uniqueItems.add(item);
      } else {
        debugPrint('ULTIMATE MOBILE DROPDOWN: Removed duplicate item with value "${item.value}"');
      }
    }
    
    // Safety check: Ensure _selectedValue exists in uniqueItems to prevent crash
    T? safeValue = _selectedValue;
    if (safeValue != null) {
      final exists = uniqueItems.any((item) => item.value == safeValue);
      if (!exists) {
        safeValue = null;
        debugPrint('ULTIMATE MOBILE DROPDOWN: Value "$safeValue" NOT FOUND in items. Falling back to null.');
      }
    }

    return DropdownButtonFormField<T>(
      value: safeValue,
      items: uniqueItems,
      onChanged: (value) {
        setState(() {
          _selectedValue = value;
        });
        widget.onChanged?.call(value);
      },
      validator: widget.validator,
      isExpanded: true,
      decoration: deco.copyWith(
        labelText: deco.labelText ?? widget.hintText,
        labelStyle: AppTypography.body().copyWith(
          fontSize: 13.sp,
          color: const Color(0xFF6B7280),
        ),
        hintStyle: AppTypography.body().copyWith(
          fontSize: 14.sp,
          color: const Color(0xFF9CA3AF),
        ),
        filled: true,
        fillColor: deco.fillColor ?? const Color(0xFFF1F1F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
      style: AppTypography.body().copyWith(
        fontSize: 14.sp,
        color: const Color(0xFF1F2937),
      ),
      dropdownColor: Colors.white,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: const Color(0xFF6B7280),
        size: 20.sp,
      ),
    );
  }
}

// Ultimate Mobile DatePicker Solution - Universal Platform Support
class UltimateMobileDatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onDateSelected;
  final InputDecoration? decoration;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const UltimateMobileDatePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onDateSelected,
    this.decoration,
    this.firstDate,
    this.lastDate,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    DateTime tempDate = initialDate ?? DateTime.now();
    DateTime? finalDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 380.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        color: Colors.transparent,
                        child: Text(
                          'Cancel',
                          style: AppTypography.body().copyWith(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Select Date',
                      style: AppTypography.title().copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        finalDate = tempDate;
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        color: Colors.transparent,
                        child: Text(
                          'Done',
                          style: AppTypography.body().copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Picker
              Expanded(
                child: import_cupertino.CupertinoDatePicker(
                  mode: import_cupertino.CupertinoDatePickerMode.date,
                  initialDateTime: initialDate ?? DateTime.now(),
                  minimumDate: firstDate ?? DateTime(1900),
                  maximumDate: lastDate ?? DateTime(2101),
                  onDateTimeChanged: (date) {
                    tempDate = date;
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );

    return finalDate;
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await show(
      context,
      initialDate: value,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deco = decoration ?? const InputDecoration();

    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(10.r),
      child: InputDecorator(
        decoration: deco.copyWith(
          labelText: label,
          labelStyle: AppTypography.body().copyWith(
            fontSize: 13.sp,
            color: const Color(0xFF6B7280),
          ),
          filled: true,
          fillColor: deco.fillColor ?? const Color(0xFFF1F1F1),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(value),
                style: AppTypography.body().copyWith(
                  fontSize: 14.sp,
                  color: value != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
            Icon(
              Icons.calendar_month_outlined,
              size: 18.sp,
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}

// Ultimate Mobile TimePicker Solution - Universal Platform Support
class UltimateMobileTimePicker {
  static Future<TimeOfDay?> show(
    BuildContext context, {
    TimeOfDay? initialTime,
  }) async {
    final now = DateTime.now();
    DateTime tempDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime?.hour ?? now.hour,
      initialTime?.minute ?? now.minute,
    );
    TimeOfDay? finalTime;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 380.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        color: Colors.transparent,
                        child: Text(
                          'Cancel',
                          style: AppTypography.body().copyWith(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Select Time',
                      style: AppTypography.title().copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        finalTime = TimeOfDay.fromDateTime(tempDateTime);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        color: Colors.transparent,
                        child: Text(
                          'Done',
                          style: AppTypography.body().copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Picker
              Expanded(
                child: import_cupertino.CupertinoDatePicker(
                  mode: import_cupertino.CupertinoDatePickerMode.time,
                  initialDateTime: tempDateTime,
                  onDateTimeChanged: (date) {
                    tempDateTime = date;
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );

    return finalTime;
  }
}


