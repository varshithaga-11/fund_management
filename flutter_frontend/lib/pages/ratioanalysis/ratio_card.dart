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

  // --- Gradient BG colors matching React CSS classes ---
  List<Color> _getGradientColors(bool isDark) {
    if (isDark) {
      switch (status) {
        case 'green':
          return [const Color(0xFF064E3B).withOpacity(0.3), const Color(0xFF065F46).withOpacity(0.3)];
        case 'yellow':
          return [const Color(0xFF78350F).withOpacity(0.3), const Color(0xFF92400E).withOpacity(0.3)];
        case 'red':
          return [const Color(0xFF7F1D1D).withOpacity(0.3), const Color(0xFF991B1B).withOpacity(0.3)];
        default:
          return [const Color(0xFF0F172A).withOpacity(0.4), const Color(0xFF1E293B).withOpacity(0.4)];
      }
    } else {
      switch (status) {
        case 'green':
          return [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)]; // from-emerald-50 to-green-50
        case 'yellow':
          return [const Color(0xFFFFFBEB), const Color(0xFFFEFCE8)]; // from-amber-50 to-yellow-50
        case 'red':
          return [const Color(0xFFFEF2F2), const Color(0xFFFFF1F2)]; // from-red-50 to-rose-50
        default:
          return [const Color(0xFFF8FAFC), const Color(0xFFF9FAFB)]; // from-slate-50 to-gray-50
      }
    }
  }

  // --- Border colors ---
  Color _getBorderColor(bool isDark) {
    if (isDark) {
      switch (status) {
        case 'green': return const Color(0xFF065F46); // emerald-800
        case 'yellow': return const Color(0xFF92400E); // amber-800
        case 'red': return const Color(0xFF991B1B); // red-800
        default: return const Color(0xFF334155); // slate-700
      }
    } else {
      switch (status) {
        case 'green': return const Color(0xFFA7F3D0); // emerald-200
        case 'yellow': return const Color(0xFFFDE68A); // amber-200
        case 'red': return const Color(0xFFFECACA); // red-200
        default: return const Color(0xFFE2E8F0); // slate-200
      }
    }
  }

  // --- Icon circle bg + icon color ---
  Color _getIconBg(bool isDark) {
    if (isDark) {
      switch (status) {
        case 'green': return const Color(0xFF064E3B).withOpacity(0.4); // emerald-900/40
        case 'yellow': return const Color(0xFF78350F).withOpacity(0.4); // amber-900/40
        case 'red': return const Color(0xFF7F1D1D).withOpacity(0.4); // red-900/40
        default: return const Color(0xFF1E293B).withOpacity(0.4); // slate-800/40
      }
    } else {
      switch (status) {
        case 'green': return const Color(0xFFD1FAE5); // emerald-100
        case 'yellow': return const Color(0xFFFEF3C7); // amber-100
        case 'red': return const Color(0xFFFEE2E2); // red-100
        default: return const Color(0xFFF1F5F9); // slate-100
      }
    }
  }

  Color _getIconColor(bool isDark) {
    if (isDark) {
      switch (status) {
        case 'green': return const Color(0xFF34D399); // emerald-400
        case 'yellow': return const Color(0xFFFBBF24); // amber-400
        case 'red': return const Color(0xFFF87171); // red-400
        default: return const Color(0xFF94A3B8); // slate-400
      }
    } else {
      switch (status) {
        case 'green': return const Color(0xFF059669); // emerald-600
        case 'yellow': return const Color(0xFFD97706); // amber-600
        case 'red': return const Color(0xFFDC2626); // red-600
        default: return const Color(0xFF475569); // slate-600
      }
    }
  }

  IconData _getIcon() {
    switch (status) {
      case 'green': return Icons.check_circle;
      case 'yellow': return Icons.error_outline;
      case 'red': return Icons.error_outline;
      default: return Icons.trending_up;
    }
  }

  Color _getVarianceColor(double variance) {
    if (variance > 10) return const Color(0xFF059669);
    if (variance > -10) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  String _formatValue(double val) => val.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double? variance;
    String? varianceText;
    Color? varianceColor;
    if (idealValue != null && idealValue != 0) {
      variance = ((value - idealValue!) / idealValue!) * 100;
      varianceText = '${variance > 0 ? "+" : ""}${variance.toStringAsFixed(1)}%';
      varianceColor = _getVarianceColor(variance);
    }

    return Container(
      // p-6 = 24px, rounded-xl = 12px, border-2 = 2px border
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(isDark),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(isDark), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + status icon  (mb-4)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // text-sm font-bold uppercase tracking-wide
                    Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF4B5563),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // w-10 h-10 rounded-full icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getIconBg(isDark),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(_getIcon(), color: _getIconColor(isDark), size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16), // mt-4

          // Main value: text-4xl font-black
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatValue(value),
                  style: TextStyle(
                    fontSize: 36, // text-4xl
                    fontWeight: FontWeight.w900, // font-black
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14, // text-sm
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),

          // Ideal + Variance section (only if idealValue provided)
          if (idealValue != null) ...[
            const SizedBox(height: 12), // mt-3
            // border-t border-gray-300/50
            Container(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.12),
            ),
            const SizedBox(height: 8),
            // space-y-1 rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ideal Value',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF4B5563),
                  ),
                ),
                Text(
                  '${_formatValue(idealValue!)} $unit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Variance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF4B5563),
                  ),
                ),
                Text(
                  varianceText ?? '-',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: varianceColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
