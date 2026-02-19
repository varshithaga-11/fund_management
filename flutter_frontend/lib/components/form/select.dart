import 'package:flutter/material.dart';

class SelectOption {
  final String value;
  final String label;

  SelectOption({required this.value, required this.label});
}

class Select extends StatelessWidget {
  final String? label;
  final List<SelectOption> options;
  final String? value;
  final ValueChanged<String?>? onChange;
  final String? placeholder;
  final String? error;
  final bool disabled;
  final String? Function(String?)? validator;

  const Select({
    super.key,
    this.label,
    required this.options,
    this.value,
    this.onChange,
    this.placeholder,
    this.error,
    this.disabled = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
           Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
        ],
        DropdownButtonFormField<String>(
          value: value,
          onChanged: disabled ? null : onChange,
          validator: validator,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.label),
            );
          }).toList(),
          decoration: InputDecoration(
            hintText: placeholder ?? 'Select an option',
            errorText: error,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          dropdownColor: Theme.of(context).cardColor,
        ),
      ],
    );
  }
}
