import 'package:flutter/material.dart';

class MultiSelectOption {
  final String value;
  final String label;

  MultiSelectOption({required this.value, required this.label});
}

class MultiSelect extends StatefulWidget {
  final String label;
  final List<MultiSelectOption> options;
  final List<String> defaultSelected;
  final ValueChanged<List<String>>? onChange;

  const MultiSelect({
    super.key,
    required this.label,
    required this.options,
    this.defaultSelected = const [],
    this.onChange,
  });

  @override
  State<MultiSelect> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<MultiSelect> {
  late List<String> _selectedValues;
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.defaultSelected);
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: widget.options.map((option) {
                  final isSelected = _selectedValues.contains(option.value);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedValues.remove(option.value);
                        } else {
                          _selectedValues.add(option.value);
                        }
                        widget.onChange?.call(_selectedValues);
                        // Rebuild overlay to show checkmark update if needed, 
                        // but InkWell usually triggers rebuild. 
                        // Ideally we should use a Stateful Widget inside Overlay or managing state better.
                        // For simplicity, we are closing and reopening or just relying on quick interaction.
                        // Actually, standard setState in parent won't rebuild OverlayEntry content automatically 
                        // unless the OverlayEntry builder uses the parent's state directly which it does _selectedValues.
                        // However, OverlayEntry is separate from the widget tree. 
                        // To fix this commonly, we check _selectedValues in builder.
                        // We need to force overlay rebuild. Simple way:
                        _overlayEntry!.markNeedsBuild();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                        border: const Border(bottom: BorderSide(color: Colors.black12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(option.label),
                          if (isSelected)
                            const Icon(Icons.check, color: Colors.blue, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _removeOption(String value) {
    setState(() {
      _selectedValues.remove(value);
      widget.onChange?.call(_selectedValues);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).cardColor,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_selectedValues.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Select options', style: TextStyle(color: Colors.grey)),
                    ),
                  ..._selectedValues.map((value) {
                    final option = widget.options.firstWhere(
                      (o) => o.value == value,
                      orElse: () => MultiSelectOption(value: value, label: value),
                    );
                    return Chip(
                      label: Text(option.label, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeOption(value),
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
