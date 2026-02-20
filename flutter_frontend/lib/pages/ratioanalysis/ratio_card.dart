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

  Color _getVarianceColor(double variance) {
    if (variance > 10) return Colors.green.shade700;
    if (variance > -10) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _formatValue(double val) {
    return val.toStringAsFixed(2);
  }

  List<Color> _getGradientColors() {
    switch (status) {
      case 'green':
        return [Colors.green.shade50, Colors.green.shade100];
      case 'yellow':
        return [Colors.amber.shade50, Colors.amber.shade100];
      case 'red':
        return [Colors.red.shade50, Colors.red.shade100];
      default:
        return [Colors.grey.shade50, Colors.grey.shade100];
    }
  }

  Color _getBorderColor() {
    switch (status) {
      case 'green':
        return Colors.green.shade200;
      case 'yellow':
        return Colors.amber.shade200;
      case 'red':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade300;
    }
  }

  Widget _getStatusIcon() {
    switch (status) {
      case 'green':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
        );
      case 'yellow':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_amber_rounded,
              color: Colors.amber.shade800, size: 20),
        );
      case 'red':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.trending_up, color: Colors.grey.shade600, size: 20),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    double? variance;
    String? varianceText;
    Color? varianceColor;

    if (idealValue != null && idealValue != 0) {
      variance = ((value - idealValue!) / idealValue!) * 100;
      varianceText =
          '${variance > 0 ? "+" : ""}${variance.toStringAsFixed(1)}%';
      varianceColor = _getVarianceColor(variance);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getBorderColor(), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          description!,
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              _getStatusIcon(),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatValue(value),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          if (idealValue != null) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.black12),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ideal Value',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    Text(
                      '${_formatValue(idealValue!)} $unit',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (varianceText != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Variance',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      Text(
                        varianceText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: varianceColor,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
