import 'package:flutter/material.dart';
import 'period_comparison_api.dart';

class PeriodComparisonPage extends StatefulWidget {
  const PeriodComparisonPage({super.key});

  @override
  State<PeriodComparisonPage> createState() => _PeriodComparisonPageState();
}

class _PeriodComparisonPageState extends State<PeriodComparisonPage> with SingleTickerProviderStateMixin {
  List<PeriodListData> _periods = [];
  PeriodListData? _selectedPeriod1;
  PeriodListData? _selectedPeriod2;
  PeriodComparisonResponse? _comparisonData;
  bool _loading = true;
  bool _loadingComparison = false;
  String? _error;
  bool _showTableView = true;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _loadPeriods();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _loadPeriods() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final periods = await getPeriodsList();
      if (mounted) {
        setState(() {
          _periods = periods;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load periods: $e')),
        );
      }
    }
  }

  Future<void> _handleCompare() async {
    if (_selectedPeriod1 == null || _selectedPeriod2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both periods')),
      );
      return;
    }

    if (_selectedPeriod1!.id == _selectedPeriod2!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select two different periods')),
      );
      return;
    }

    setState(() => _loadingComparison = true);
    try {
      final rawData = await comparePeriodsById(_selectedPeriod1!.id, _selectedPeriod2!.id);
      final transformed = transformRawComparisonData(
          rawData, _selectedPeriod1!.label, _selectedPeriod2!.label);
      
      if (mounted) {
        setState(() {
          _comparisonData = transformed;
          _loadingComparison = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comparison loaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingComparison = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error comparing periods: $e')),
        );
      }
    }
  }

  void _handleSwap() {
    if (_selectedPeriod1 != null && _selectedPeriod2 != null) {
      _spinController.forward(from: 0.0);
      setState(() {
        final temp = _selectedPeriod1;
        _selectedPeriod1 = _selectedPeriod2;
        _selectedPeriod2 = temp;
        _comparisonData = null; // Clear previous comparison to force re-compare or just clear view
      });
    }
  }

  String _formatRatioName(String name) {
    return name
        .split('_')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  Color _getChangeColor(double? change) {
    if (change == null) return Colors.grey;
    if (change > 0) return Colors.green;
    if (change < 0) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Period Comparison'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<PeriodListData>(
                            decoration: const InputDecoration(labelText: 'Period 1', border: OutlineInputBorder()),
                            value: _selectedPeriod1,
                            items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p.label, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _selectedPeriod1 = val),
                            isExpanded: true,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: IconButton(
                            icon: RotationTransition(
                              turns: Tween(begin: 0.0, end: 0.5).animate(_spinController),
                              child: const Icon(Icons.swap_horiz, color: Colors.blue),
                            ),
                            onPressed: _handleSwap,
                            tooltip: 'Swap Periods',
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<PeriodListData>(
                            decoration: const InputDecoration(labelText: 'Period 2', border: OutlineInputBorder()),
                            value: _selectedPeriod2,
                            items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p.label, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _selectedPeriod2 = val),
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadingComparison ? null : _handleCompare,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _loadingComparison
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Compare Periods'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Comparison Results
            if (_comparisonData != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparison Results',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_comparisonData!.data.period1} vs ${_comparisonData!.data.period2}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() => _comparisonData = null),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Stats
              Row(
                children: [
                  _buildSummaryCard(
                    'Improved',
                    _comparisonData!.data.ratios.values
                        .where((r) => r.percentageChange != null && r.percentageChange! > 0)
                        .length
                        .toString(),
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    'Declined',
                    _comparisonData!.data.ratios.values
                        .where((r) => r.percentageChange != null && r.percentageChange! < 0)
                        .length
                        .toString(),
                    Colors.red,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    'Total',
                    _comparisonData!.data.ratios.length.toString(),
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // View Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('Table View', true),
                    _buildToggleButton('Card View', false),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Data View
              if (_showTableView) _buildTableView() else _buildCardView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title.toUpperCase(),
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isTable) {
    final isSelected = _showTableView == isTable;
    return InkWell(
      onTap: () => setState(() => _showTableView = isTable),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Ratio')),
            DataColumn(label: Text(_comparisonData!.data.period1)),
            DataColumn(label: Text(_comparisonData!.data.period2)),
            const DataColumn(label: Text('Diff')),
            const DataColumn(label: Text('% Change')),
          ],
          rows: _comparisonData!.data.ratios.entries.map((entry) {
            final ratio = entry.value;
            return DataRow(cells: [
              DataCell(Text(_formatRatioName(entry.key), style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(ratio.period1?.toStringAsFixed(2) ?? '-')),
              DataCell(Text(ratio.period2?.toStringAsFixed(2) ?? '-')),
              DataCell(Text(
                ratio.difference != null
                    ? '${ratio.difference! > 0 ? "+" : ""}${ratio.difference!.toStringAsFixed(2)}'
                    : '-',
                style: TextStyle(color: _getChangeColor(ratio.difference), fontWeight: FontWeight.bold),
              )),
              DataCell(Text(
                ratio.percentageChange != null
                    ? '${ratio.percentageChange! > 0 ? "+" : ""}${ratio.percentageChange!.toStringAsFixed(2)}%'
                    : '-',
                style: TextStyle(color: _getChangeColor(ratio.percentageChange), fontWeight: FontWeight.bold),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardView() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final count = width > 900 ? 3 : (width > 600 ? 2 : 1);
      
      return GridView.count(
        crossAxisCount: count,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: _comparisonData!.data.ratios.entries.map((entry) {
          final ratio = entry.value;
          final isPositive = (ratio.percentageChange ?? 0) > 0;
          final color = _getChangeColor(ratio.percentageChange);
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatRatioName(entry.key),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('P1', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      Text(ratio.period1?.toStringAsFixed(2) ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('P2', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      Text(ratio.period2?.toStringAsFixed(2) ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Change', style: TextStyle(fontSize: 12, color: color)),
                      Text(
                        ratio.percentageChange != null
                            ? '${isPositive ? "+" : ""}${ratio.percentageChange!.toStringAsFixed(2)}%'
                            : '-',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}
