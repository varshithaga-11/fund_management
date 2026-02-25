import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
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
      'gross_profit_ratio_max',
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
    if (mounted) {
      setState(() => _canUpdate = userRole == 'master');
    }
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
      if (mounted) {
        setState(() {
          _data = data;
          _controllers = controllers;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to load benchmarks: $e', isError: true);
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
        benchmarks[key] = text.isEmpty ? null : double.tryParse(text);
      });
      await updateRatioBenchmarks(benchmarks);
      if (mounted) {
        _showSnack('Benchmarks updated successfully.');
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to update benchmarks: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading benchmarks...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: isDark ? AppColors.gray600 : AppColors.gray400),
              const SizedBox(height: 16),
              Text('Failed to load data',
                  style: TextStyle(
                      color: isDark ? AppColors.gray300 : AppColors.gray700)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final allKeys = _data!.keysOrder.isNotEmpty
        ? _data!.keysOrder
        : _data!.benchmarks.keys.toList();
    final handledKeys = _categories.values.expand((e) => e).toList();
    final otherKeys = allKeys.where((k) => !handledKeys.contains(k)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Ratio Benchmarks',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.gray900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_canUpdate)
                        ElevatedButton(
                          onPressed: _saving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Save changes',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                        )
                      else
                        Text(
                          'Only Master role can update benchmarks.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.amber.shade400
                                : Colors.amber.shade700,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Subtitle ─────────────────────────────────────────────
                  Text(
                    'These values are used for traffic light status (green/yellow/red) in the Ratio Dashboard. Leave blank where no fixed benchmark applies.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Category sections ────────────────────────────────────
                  ..._categories.entries
                      .map((entry) => _buildSection(
                          entry.key, entry.value, allKeys, isDark))
                      .where((w) => w != null)
                      .map((w) => Column(children: [w!, const SizedBox(height: 20)])),

                  // ── Other keys ───────────────────────────────────────────
                  if (otherKeys.isNotEmpty) ...[
                    _buildSection('Other', otherKeys, allKeys, isDark) ??
                        const SizedBox.shrink(),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSection(
      String title, List<String> keys, List<String> allKeys, bool isDark) {
    final visible = keys.where((k) => allKeys.contains(k)).toList();
    if (visible.isEmpty) return null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.gray200,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),

          // 2-column grid using LayoutBuilder
          LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth > 600;
              if (!useGrid) {
                // Single column
                return Column(
                  children: visible
                      .map((key) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildField(key, isDark),
                          ))
                      .toList(),
                );
              }
              // Two-column grid
              final rows = <Widget>[];
              for (int i = 0; i < visible.length; i += 2) {
                final left = visible[i];
                final right = i + 1 < visible.length ? visible[i + 1] : null;
                rows.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildField(left, isDark)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: right != null
                              ? _buildField(right, isDark)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(children: rows);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField(String key, bool isDark) {
    final label =
        _data?.labels[key] ?? key.replaceAll('_', ' ');
    final controller = _controllers[key];
    if (controller == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.gray300 : AppColors.gray700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: _canUpdate,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.white : AppColors.gray900,
          ),
          decoration: InputDecoration(
            hintText: '—',
            hintStyle: TextStyle(
              color: isDark ? AppColors.gray600 : AppColors.gray400,
            ),
            filled: true,
            fillColor: _canUpdate
                ? (isDark ? AppColors.darkBg : AppColors.white)
                : (isDark
                    ? AppColors.darkBg.withOpacity(0.5)
                    : AppColors.gray50),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.gray200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.gray200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.gray100,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
