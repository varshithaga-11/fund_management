import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final bool enabled;
  final bool success;
  final bool error;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;

  const InputField({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.success = false,
    this.error = false,
    this.helperText,
    this.onChanged,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade300;
    Color focusedBorderColor = Colors.blue;
    Color focusedRingColor = Colors.blue.withOpacity(0.2);

    if (error) {
      borderColor = Colors.red.shade500;
      focusedBorderColor = Colors.red.shade300;
      focusedRingColor = Colors.red.shade500.withOpacity(0.2);
    } else if (success) {
      borderColor = Colors.green.shade500;
      focusedBorderColor = Colors.green.shade300;
      focusedRingColor = Colors.green.shade500.withOpacity(0.2);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: enabled ? Colors.black87 : Colors.grey.shade600,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: !enabled,
            fillColor: !enabled ? Colors.grey.shade50 : Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: focusedBorderColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade500),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade500, width: 2),
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: TextStyle(
              fontSize: 12,
              color: error
                  ? Colors.red.shade500
                  : success
                      ? Colors.green.shade500
                      : Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}
