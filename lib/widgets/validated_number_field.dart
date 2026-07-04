import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// حقل إدخال رقمي مع تحقق مدمج
/// يستخدم لإدخال الأسعار والأرقام الأخرى مع ضمان صحة المدخلات
class ValidatedNumberField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? suffixText;
  final double? minValue;
  final double? maxValue;
  final bool allowDecimal;
  final ValueChanged<double?>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final InputDecoration? decoration;

  const ValidatedNumberField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixText,
    this.minValue,
    this.maxValue,
    this.allowDecimal = true,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        // السماح فقط بالأرقام والنقطة العشرية
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      decoration: decoration ?? InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixText: suffixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
      validator: validator ?? _defaultValidator,
      onChanged: (value) {
        if (onChanged != null) {
          final parsed = double.tryParse(value);
          onChanged!(parsed);
        }
      },
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // اختياري - إذا أردت جعله مطلوبًا أضف معامل required
    }

    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'يرجى إدخال رقم صالح';
    }

    if (minValue != null && parsed < minValue!) {
      return 'القيمة يجب أن تكون ${minValue!.toStringAsFixed(0)} على الأقل';
    }

    if (maxValue != null && parsed > maxValue!) {
      return 'القيمة يجب ألا تتجاوز ${maxValue!.toStringAsFixed(0)}';
    }

    return null;
  }
}

/// حقل إدخال السعر مع تحقق مخصص
class PriceInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final double? minPrice;
  final double? maxPrice;
  final ValueChanged<double?>? onChanged;
  final bool required;

  const PriceInputField({
    Key? key,
    this.controller,
    this.labelText,
    this.minPrice = 0,
    this.maxPrice,
    this.onChanged,
    this.required = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: labelText ?? 'السعر',
        hintText: 'أدخل السعر',
        prefixIcon: const Icon(Icons.payments_outlined),
        suffixText: 'جنيه',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'يرجى إدخال السعر';
        }

        if (value != null && value.isNotEmpty) {
          final parsed = double.tryParse(value);
          if (parsed == null) {
            return 'يرجى إدخال رقم صالح';
          }

          if (minPrice != null && parsed < minPrice!) {
            return 'السعر يجب أن يكون ${minPrice!.toStringAsFixed(0)} جنيه على الأقل';
          }

          if (maxPrice != null && parsed > maxPrice!) {
            return 'السعر يجب ألا يتجاوز ${maxPrice!.toStringAsFixed(0)} جنيه';
          }
        }

        return null;
      },
      onChanged: (value) {
        if (onChanged != null) {
          final parsed = double.tryParse(value);
          onChanged!(parsed);
        }
      },
    );
  }
}

/// حقل إدخال رقم الهاتف مع تحقق
class PhoneInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final ValueChanged<String>? onChanged;
  final bool required;

  const PhoneInputField({
    Key? key,
    this.controller,
    this.labelText,
    this.onChanged,
    this.required = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        // السماح بالأرقام وعلامة + فقط
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
        LengthLimitingTextInputFormatter(15),
      ],
      decoration: InputDecoration(
        labelText: labelText ?? 'رقم الهاتف',
        hintText: '01XXXXXXXXX',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'يرجى إدخال رقم الهاتف';
        }

        if (value != null && value.isNotEmpty) {
          // التحقق من صيغة رقم الهاتف المصري
          final phoneRegex = RegExp(r'^(\+?2)?01[0125][0-9]{8}$');
          if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
            return 'يرجى إدخال رقم هاتف صالح';
          }
        }

        return null;
      },
      onChanged: onChanged,
    );
  }
}
