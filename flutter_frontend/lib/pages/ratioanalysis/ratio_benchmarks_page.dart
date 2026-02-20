import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'benchmarks_api.dart';

class RatioBenchmarksPage extends StatefulWidget {
  const RatioBenchmarksPage({super.key});

  @override
  _RatioBenchmarksPageState createState() => _RatioBenchmarksPageState();
}

class _RatioBenchmarksPageState extends State<RatioBenchmarksPage> {
  RatioBenchmarksResponse? _data;
  Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;
  bool _canUpdate = false;

  static const Map<String, List<String>> _categories = {
    'Trading': [
      'stock_turnover',
      'gross_profit_ratio_min',
      'gross_profit_ratio_max'
    ],
    'Fund Structure': [
      'own_fund_to_wf',
      'loans_to_wf_min',
      'loans_to_wf_max',
      'investments_to_wf_min',
      'investments_to_wf_max',
      'earning_assets_to_wf_min',
    ],
    'Yield & Cost': [
      'avg_cost_of_wf',
      'avg_yield_on_wf',
      'misc_income_to_wf_min',
      'interest_exp_to_interest_income_max',
    ],
    'Margins': [
      'gross_financial_margin',
      'operating_cost_to_wf_min',
      'operating_cost_to_wf_max',
      'net_financial_margin',
      'risk_cost_to_wf_max',
      'net_margin',
    ],
    'Credit Deposit': ['credit_deposit_ratio_min'],
    'Capital Efficiency': ['capital_turnover_ratio'],
    'Productivity': ['per_employee_deposit_min', 'per_employee_loan_min'],
  };

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadData();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole') ?? '';
    setState(() {
      _canUpdate = userRole == 'master';
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await getRatioBenchmarks();
      final controllers = <String, TextEditingController>{};

      final allKeys = data.keysOrder.isNotEmpty
          ? data.keysOrder
          : data.benchmarks.keys.toList();

      for (var key in allKeys) {
        final val = data.benchmarks[key];
        controllers[key] = TextEditingController(
          text: val != null ? val.toString() : '',
        );
      }

      setState(() {
        _data = data;
        _controllers = controllers;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load benchmarks: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_canUpdate) return;
    setState(() => _saving = true);
    try {
      final benchmarks = <String, double?>{};
      _controllers.forEach((key, controller) {
        final text = controller.text.trim();
        if (text.isEmpty) {
          benchmarks[key] = null;
        } else {
          final val = double.tryParse(text);
          benchmarks[key] = val; // Note: sending null if parse fails is acceptable behavior per frontend logic
        }
      });

      await updateRatioBenchmarks(benchmarks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Benchmarks updated successfully')),
        );
        _loadData(); // Reload to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update benchmarks: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Widget _buildCategorySection(String title, List<String> keys, List<String> allKeys) {
    final visibleKeys = keys.where((k) => allKeys.contains(k)).toList();
    if (visibleKeys.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final itemWidth = isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
              
              return Wrap(
                spacing: 24, // Horizontal gap
                runSpacing: 12, // Vertical gap (Decreased)
                children: visibleKeys.map((key) {
                  final label = _data?.labels[key] ?? key.replaceAll('_', ' ');
                  final controller = _controllers[key];
                  
                  if (controller == null) return const SizedBox.shrink();

                  return SizedBox(
                    width: itemWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700
                            )),
                        const SizedBox(height: 4),
                        TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '—',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          enabled: _canUpdate,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_data == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load data')),
      );
    }

    final allKeys = _data!.keysOrder.isNotEmpty
        ? _data!.keysOrder
        : _data!.benchmarks.keys.toList();
        
    final handledKeys = _categories.values.expand((element) => element).toList();
    final otherKeys = allKeys.where((k) => !handledKeys.contains(k)).toList();

    return Scaffold(
      // No AppBar, using custom header to match React layout inside standard container
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ratio Benchmarks',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (_canUpdate)
                  ElevatedButton(
                    onPressed: _saving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1), // Indigo/Primary
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save changes'),
                  )
                else
                  Text(
                    'Read Only',
                    style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description/Info
            Text(
              'These values are used for traffic light status (green/yellow/red) in the Ratio Dashboard. Leave blank where no fixed benchmark applies.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            
            const SizedBox(height: 24),

            if (!_canUpdate)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Only Master role can update benchmarks.',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Categories
            ..._categories.entries.map((entry) =>
                _buildCategorySection(entry.key, entry.value, allKeys)),
            
            if (otherKeys.isNotEmpty)
              _buildCategorySection('Other', otherKeys, allKeys),
          ],
        ),
      ),
    );
  }
}
