import 'package:flutter/material.dart';

class RatioCard extends StatelessWidget {
  final String name;
  final double value;
  final String unit;
  final double? idealValue;
  final String? status; // 'green', 'yellow', 'red'
  final String? description;

  const RatioCard({
    super.key,
    required this.name,
    required this.value,
    this.unit = '%',
    this.idealValue,
    this.status,
    this.description,
  });

  // --- Background colors ---
  Color _getBgColor(bool isDark) {
    if (isDark) {
      switch (status) {
        case 'green': return const Color(0xFF064E3B).withOpacity(0.12);
        case 'yellow': return const Color(0xFF78350F).withOpacity(0.12);
        case 'red': return const Color(0xFF7F1D1D).withOpacity(0.12);
        default: return const Color(0xFF1E293B);
      }
    } else {
      switch (status) {
        case 'green': return const Color(0xFFF0FDF4);
        case 'yellow': return const Color(0xFFFFFBEB);
        case 'red': return const Color(0xFFFEF2F2);
        default: return const Color(0xFFF8FAFC);
      }
    }
  }

  // --- Border colors ---
  Color _getBorderColor(bool isDark) {
    if (isDark) {
      switch (status) {
        case 'green': return const Color(0xFF059669).withOpacity(0.35);
        case 'yellow': return const Color(0xFFD97706).withOpacity(0.35);
        case 'red': return const Color(0xFFDC2626).withOpacity(0.35);
        default: return const Color(0xFF334155);
      }
    } else {
      switch (status) {
        case 'green': return const Color(0xFFBBF7D0);
        case 'yellow': return const Color(0xFFFEF3C7);
        case 'red': return const Color(0xFFFECACA);
        default: return const Color(0xFFE2E8F0);
      }
    }
  }

  Color _getIconColor(bool isDark) {
    if (isDark) {
      switch (status) {
        case 'green': return const Color(0xFF4ADE80);
        case 'yellow': return const Color(0xFFFBBF24);
        case 'red': return const Color(0xFFF87171);
        default: return const Color(0xFF94A3B8);
      }
    } else {
      switch (status) {
        case 'green': return const Color(0xFF16A34A);
        case 'yellow': return const Color(0xFFD97706);
        case 'red': return const Color(0xFFDC2626);
        default: return const Color(0xFF64748B);
      }
    }
  }

  Color _getIconBgColor(bool isDark) {
    return _getIconColor(isDark).withOpacity(0.12);
  }

  IconData _getIcon() {
    switch (status) {
      case 'green': return Icons.check_circle_outline_rounded;
      case 'yellow': return Icons.error_outline_rounded;
      case 'red': return Icons.error_outline_rounded;
      default: return Icons.trending_up_rounded;
    }
  }

  String _formatValue(double val) => val.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double? variance;
    String? varianceText;
    if (idealValue != null && idealValue != 0) {
      variance = ((value - idealValue!) / idealValue!) * 100;
      varianceText = '${variance > 0 ? "+" : ""}${variance.toStringAsFixed(1)}%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _getBgColor(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _getBorderColor(isDark), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getIconBgColor(isDark),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(), color: _getIconColor(isDark), size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatValue(value),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              if (unit.isNotEmpty) const SizedBox(width: 4),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
          if (idealValue != null) const SizedBox(height: 8),
          if (idealValue != null)
            Column(
              children: [
                Divider(
                  height: 12,
                  thickness: 1,
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ideal Value',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      '${_formatValue(idealValue!)} $unit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Variance',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      varianceText ?? '-',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _getIconColor(isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
