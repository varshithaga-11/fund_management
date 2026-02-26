import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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
  String _searchPeriod1 = '';
  String _searchPeriod2 = '';
  bool _openDropdown1 = false;
  bool _openDropdown2 = false;
  late AnimationController _spinController;
  int _spinCount = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
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

  List<PeriodListData> _filterPeriods(String searchTerm, {int? excludeId}) {
    return _periods.where((period) {
      final matchesSearch = period.label.toLowerCase().contains(searchTerm.toLowerCase()) ||
          period.periodType.toLowerCase().contains(searchTerm.toLowerCase());
      final notExcluded = excludeId != null ? period.id != excludeId : true;
      return matchesSearch && notExcluded;
    }).toList();
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
      setState(() {
        _spinCount++;
        final temp = _selectedPeriod1;
        _selectedPeriod1 = _selectedPeriod2;
        _selectedPeriod2 = temp;
        _comparisonData = null;
      });
      // Trigger animation
      _spinController.forward(from: 0.0);
    }
  }

  String _formatRatioName(String name) {
    return name
        .split('_')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
              const SizedBox(height: 16),
              Text('Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPeriods,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                _comparisonData != null ? 'Comparison Results' : 'Compare Periods',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _comparisonData != null
                    ? 'Comparing ${_comparisonData!.data.period1} vs ${_comparisonData!.data.period2}'
                    : 'Select two financial periods to analyze ratio changes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Period Selection Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Dropdowns Row with Swap Button in the middle
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: _buildCustomDropdownSimple(
                            isDark: isDark,
                            selectedValue: _selectedPeriod1,
                            searchValue: _searchPeriod1,
                            onSearchChanged: (val) => setState(() => _searchPeriod1 = val),
                            isOpen: _openDropdown1,
                            onOpenChanged: (val) => setState(() => _openDropdown1 = val),
                            items: _filterPeriods(_searchPeriod1, excludeId: _selectedPeriod2?.id),
                            onSelected: (val) {
                              setState(() {
                                _selectedPeriod1 = val;
                                _openDropdown1 = false;
                                _searchPeriod1 = '';
                              });
                            },
                            label: 'Period 1',
                          ),
                        ),
                        
                        // Swap Button in the middle
                        if (_selectedPeriod1 != null && _selectedPeriod2 != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: AnimatedBuilder(
                              animation: _spinController,
                              builder: (context, child) {
                                final angle = (_spinCount - 1 + _spinController.value) * 3.14159;
                                return GestureDetector(
                                  onTap: _handleSwap,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.blue.shade400, width: 1.5),
                                      color: isDark ? Colors.grey.shade800 : Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: angle,
                                        child: Icon(Icons.compare_arrows, color: Colors.blue.shade600, size: 18),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          const SizedBox(width: 12),

                        Flexible(
                          child: _buildCustomDropdownSimple(
                            isDark: isDark,
                            selectedValue: _selectedPeriod2,
                            searchValue: _searchPeriod2,
                            onSearchChanged: (val) => setState(() => _searchPeriod2 = val),
                            isOpen: _openDropdown2,
                            onOpenChanged: (val) => setState(() => _openDropdown2 = val),
                            items: _filterPeriods(_searchPeriod2, excludeId: _selectedPeriod1?.id),
                            onSelected: (val) {
                              setState(() {
                                _selectedPeriod2 = val;
                                _openDropdown2 = false;
                                _searchPeriod2 = '';
                              });
                            },
                            label: 'Period 2',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _loadingComparison ? null : _handleCompare,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          child: _loadingComparison
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text('Compare Periods', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dropdown Menus (Outside the card)
              if (_openDropdown1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildDropdownMenu(isDark),
                ),
              if (_openDropdown2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildDropdownMenu(isDark),
                ),

              // Comparison Results
              if (_comparisonData != null) ...[
                const SizedBox(height: 32),
                Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, height: 1),
                const SizedBox(height: 32),

                // Header with Title and Clear Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comparison Results',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Comparing ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                TextSpan(
                                  text: _comparisonData!.data.period1,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' vs ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                TextSpan(
                                  text: _comparisonData!.data.period2,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _comparisonData = null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Clear Results', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Summary Stats — 4 per row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final cols = w > 900 ? 4 : (w > 600 ? 2 : 1);
                    final spacing = 12.0;
                    final itemW = (w - spacing * (cols - 1)) / cols;

                    final improvedCount = _comparisonData!.data.ratios.values
                        .where((r) => r.percentageChange != null && r.percentageChange! > 0)
                        .length;
                    final declinedCount = _comparisonData!.data.ratios.values
                        .where((r) => r.percentageChange != null && r.percentageChange! < 0)
                        .length;
                    final unchangedCount = _comparisonData!.data.ratios.values
                        .where((r) => r.percentageChange == null || r.percentageChange == 0)
                        .length;
                    final totalCount = _comparisonData!.data.ratios.length;

                    final cards = [
                      _buildSummaryCard('Improved Ratios',  improvedCount.toString(),  Colors.green,  isDark),
                      _buildSummaryCard('Declined Ratios',  declinedCount.toString(),  Colors.red,    isDark),
                      _buildSummaryCard('Unchanged',        unchangedCount.toString(), Colors.grey,   isDark),
                      _buildSummaryCard('Total Ratios',     totalCount.toString(),     Colors.blue,   isDark),
                    ];

                    final rows = <Widget>[];
                    for (int i = 0; i < cards.length; i += cols) {
                      rows.add(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: List.generate(cols, (j) {
                              final idx = i + j;
                              return idx < cards.length
                                  ? Padding(
                                      padding: EdgeInsets.only(right: j < cols - 1 ? spacing : 0),
                                      child: SizedBox(width: itemW, child: cards[idx]),
                                    )
                                  : SizedBox(width: itemW + (j < cols - 1 ? spacing : 0));
                            }),
                          ),
                        ),
                      );
                    }
                    return Column(children: rows);
                  },
                ),

                const SizedBox(height: 32),

                // View Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildToggleButton('📊 Table View', true, isDark),
                    _buildToggleButton('🎴 Card View', false, isDark),
                  ],
                ),

                const SizedBox(height: 24),

                // Data View
                _showTableView ? _buildTableView(isDark) : _buildCardView(isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Dropdown button only (no menu)
  Widget _buildCustomDropdownSimple({
    required bool isDark,
    required PeriodListData? selectedValue,
    required String searchValue,
    required Function(String) onSearchChanged,
    required bool isOpen,
    required Function(bool) onOpenChanged,
    required List<PeriodListData> items,
    required Function(PeriodListData) onSelected,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        // Dropdown button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onOpenChanged(!isOpen),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isDark ? Colors.grey.shade800 : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: selectedValue != null
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedValue.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedValue.periodType,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    )
                        : Text(
                      'Select a period...',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.expand_less : Icons.expand_more,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Dropdown menu that appears outside/below
  Widget _buildDropdownMenu(bool isDark) {
    // Determine which dropdown is open
    final isFirstDropdown = _openDropdown1;
    final isSecondDropdown = _openDropdown2;
    
    late PeriodListData? selectedValue;
    late String searchValue;
    late List<PeriodListData> items;
    late Function(PeriodListData) onSelected;

    if (isFirstDropdown) {
      selectedValue = _selectedPeriod1;
      searchValue = _searchPeriod1;
      items = _filterPeriods(_searchPeriod1, excludeId: _selectedPeriod2?.id);
      onSelected = (val) {
        setState(() {
          _selectedPeriod1 = val;
          _openDropdown1 = false;
          _searchPeriod1 = '';
        });
      };
    } else if (isSecondDropdown) {
      selectedValue = _selectedPeriod2;
      searchValue = _searchPeriod2;
      items = _filterPeriods(_searchPeriod2, excludeId: _selectedPeriod1?.id);
      onSelected = (val) {
        setState(() {
          _selectedPeriod2 = val;
          _openDropdown2 = false;
          _searchPeriod2 = '';
        });
      };
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isDark ? Colors.grey.shade800 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search field
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
            ),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  if (isFirstDropdown) {
                    _searchPeriod1 = val;
                  } else {
                    _searchPeriod2 = val;
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Search periods...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          // Items list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 256),
            child: items.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'No periods found',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final period = items[index];
                final isSelected = selectedValue?.id == period.id;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelected(period),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade100
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              period.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.blue.shade900
                                    : (isDark ? Colors.white : Colors.grey.shade900),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              period.periodType,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isTable, bool isDark) {
    final isSelected = _showTableView == isTable;
    return GestureDetector(
      onTap: () => setState(() => _showTableView = isTable),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue.shade600 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isSelected ? (isDark ? Colors.blue.shade400 : Colors.blue.shade700) : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(bool isDark) {
    final ratioEntries = _comparisonData!.data.ratios.entries.toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // LayoutBuilder gives finite width here (from the parent column).
          // Enforce a minimum of 700 so narrow screens get horizontal scroll.
          final totalW = constraints.maxWidth < 700 ? 700.0 : constraints.maxWidth;
          final ratioW = totalW * 0.35;
          final dataW  = (totalW - ratioW) / 4;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalW,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Container(
                    color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                    child: Row(children: [
                      _tableHeaderCell('Ratio',                         ratioW, TextAlign.left,  isDark),
                      _tableHeaderCell(_comparisonData!.data.period1,   dataW,  TextAlign.right, isDark),
                      _tableHeaderCell(_comparisonData!.data.period2,   dataW,  TextAlign.right, isDark),
                      _tableHeaderCell('Difference',                    dataW,  TextAlign.right, isDark),
                      _tableHeaderCell('% Change',                      dataW,  TextAlign.right, isDark),
                    ]),
                  ),

                  // ── Data rows ────────────────────────────────────────────
                  ...ratioEntries.map((entry) {
                    final ratio = entry.value;
                    final diff  = ratio.difference;
                    final pct   = ratio.percentageChange;

                    final diffText = diff == null ? '-'
                        : '${diff > 0 ? "+" : ""}${diff.toStringAsFixed(2)}';
                    final pctText  = pct == null ? '-'
                        : '${pct > 0 ? "+" : ""}${pct.toStringAsFixed(2)}%';

                    return _ComparisonTableRow(
                      isDark: isDark,
                      children: [
                        _tableDataCell(
                          _formatRatioName(entry.key),
                          ratioW, TextAlign.left,
                          isDark ? Colors.white : const Color(0xFF111827),
                          isDark, fontWeight: FontWeight.w500,
                        ),
                        _tableDataCell(
                          ratio.period1?.toStringAsFixed(2) ?? '-',
                          dataW, TextAlign.right,
                          isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                          isDark,
                        ),
                        _tableDataCell(
                          ratio.period2?.toStringAsFixed(2) ?? '-',
                          dataW, TextAlign.right,
                          isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                          isDark,
                        ),
                        _tableDataCell(
                          diffText, dataW, TextAlign.right,
                          _getChangeColor(diff), isDark,
                          fontWeight: FontWeight.w600,
                        ),
                        _tableDataCell(
                          pctText, dataW, TextAlign.right,
                          _getChangeColor(pct), isDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tableHeaderCell(String text, double width, TextAlign align, bool isDark) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _tableDataCell(
    String text,
    double width,
    TextAlign align,
    Color color,
    bool isDark, {
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontSize: 13,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildCardView(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Force 3 columns earlier to match React desktop view
        final count = screenWidth > 1100 ? 3 : (screenWidth > 750 ? 2 : 1);
        final spacing = 12.0;
        final itemWidth = (constraints.maxWidth - (spacing * (count - 1))) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _comparisonData!.data.ratios.entries.map((entry) {
            final ratio = entry.value;
            final changePercentage = ratio.percentageChange ?? 0;
            final isPositive = changePercentage > 0;
            final isNeutral = changePercentage == 0;

            Color bgStart, bgEnd, borderColor;

            if (isPositive) {
              bgStart = isDark ? const Color(0xFF064E3B).withOpacity(0.15) : const Color(0xFFF0FDF4);
              bgEnd = isDark ? const Color(0xFF065F46).withOpacity(0.15) : const Color(0xFFECFDF5);
              borderColor = isDark ? const Color(0xFF065F46).withOpacity(0.4) : const Color(0xFFBBF7D0);
            } else if (isNeutral) {
              bgStart = isDark ? const Color(0xFF111827).withOpacity(0.3) : const Color(0xFFF9FAFB);
              bgEnd = isDark ? const Color(0xFF1F2937).withOpacity(0.3) : const Color(0xFFF8FAFC);
              borderColor = isDark ? const Color(0xFF374151).withOpacity(0.4) : const Color(0xFFE5E7EB);
            } else {
              bgStart = isDark ? const Color(0xFF7F1D1D).withOpacity(0.15) : const Color(0xFFFEF2F2);
              bgEnd = isDark ? const Color(0xFF881337).withOpacity(0.15) : const Color(0xFFFFF1F2);
              borderColor = isDark ? const Color(0xFF991B1B).withOpacity(0.4) : const Color(0xFFFECACA);
            }

            return SizedBox(
              width: itemWidth,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bgStart, bgEnd],
                ),
                border: Border.all(color: borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatRatioName(entry.key).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  
                  // Period 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _comparisonData!.data.period1,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        ratio.period1?.toStringAsFixed(2) ?? '-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Period 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _comparisonData!.data.period2,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        ratio.period2?.toStringAsFixed(2) ?? '-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Compact Footer
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: borderColor, width: 1.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CHANGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '${isPositive ? "+" : ""}${ratio.percentageChange?.toStringAsFixed(2) ?? "0.00"}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _getChangeColor(ratio.percentageChange),
                              ),
                            ),
                          ],
                        ),
                        if (ratio.difference != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${ratio.difference! > 0 ? "+" : ""}${ratio.difference!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _getChangeColor(ratio.difference),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Hoverable table row ──────────────────────────────────────────────────────

class _ComparisonTableRow extends StatefulWidget {
  final List<Widget> children;
  final bool isDark;

  const _ComparisonTableRow({
    required this.children,
    required this.isDark,
  });

  @override
  State<_ComparisonTableRow> createState() => _ComparisonTableRowState();
}

class _ComparisonTableRowState extends State<_ComparisonTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered
              ? (widget.isDark
                  ? const Color(0xFF1F2937).withOpacity(0.5)
                  : const Color(0xFFF9FAFB))
              : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: widget.isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Row(children: widget.children),
      ),
    );
  }
}
