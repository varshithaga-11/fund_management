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
                        Expanded(
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

                        Expanded(
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

                // Summary Stats
                LayoutBuilder(
                  builder: (context, constraints) {
                    final count = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: count,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12, // Reduced from 16
                      crossAxisSpacing: 12, // Reduced from 16
                      childAspectRatio: 2.6, // Increased from 2.2 to reduce height
                      children: [
                        _buildSummaryCard(
                          'Improved Ratios',
                          _comparisonData!.data.ratios.values
                              .where((r) => r.percentageChange != null && r.percentageChange! > 0)
                              .length
                              .toString(),
                          Colors.green,
                          isDark,
                        ),
                        _buildSummaryCard(
                          'Declined Ratios',
                          _comparisonData!.data.ratios.values
                              .where((r) => r.percentageChange != null && r.percentageChange! < 0)
                              .length
                              .toString(),
                          Colors.red,
                          isDark,
                        ),
                        _buildSummaryCard(
                          'Total Ratios',
                          _comparisonData!.data.ratios.length.toString(),
                          Colors.blue,
                          isDark,
                        ),
                      ],
                    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced from 12
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2), // Reduced from 4
          Text(
            value,
            style: TextStyle(
              fontSize: 22, // Reduced from 24
              fontWeight: FontWeight.bold,
              color: color,
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate column widths to match 3-column card layout
        final totalWidth = constraints.maxWidth;
        final cardCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        
        // Adjust column widths based on available space
        double ratioColWidth = totalWidth * 0.35;
        double dataColWidth = (totalWidth - ratioColWidth) / 4;
        
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Container(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  child: Row(
                    children: [
                      Container(
                        width: ratioColWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'Ratio',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: dataColWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Text(
                          _comparisonData!.data.period1,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: dataColWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Text(
                          _comparisonData!.data.period2,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: dataColWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Text(
                          'Difference',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: dataColWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Text(
                          '% Change',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Data Rows
                ...ratioEntries.map((entry) {
                  final ratio = entry.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                        ),
                      ),
                      color: Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: ratioColWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            _formatRatioName(entry.key),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          width: dataColWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text(
                            ratio.period1?.toStringAsFixed(2) ?? '-',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Container(
                          width: dataColWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text(
                            ratio.period2?.toStringAsFixed(2) ?? '-',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Container(
                          width: dataColWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text(
                            ratio.difference != null
                                ? '${ratio.difference! > 0 ? "+" : ""}${ratio.difference!.toStringAsFixed(2)}'
                                : '-',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _getChangeColor(ratio.difference),
                            ),
                          ),
                        ),
                        Container(
                          width: dataColWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text(
                            ratio.percentageChange != null
                                ? '${ratio.percentageChange! > 0 ? "+" : ""}${ratio.percentageChange!.toStringAsFixed(2)}%'
                                : '-',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _getChangeColor(ratio.percentageChange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardView(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, // Reduced from 12
          crossAxisSpacing: 10, // Reduced from 12
          childAspectRatio: 2.1, // Increased from 1.8 to reduce height
          children: _comparisonData!.data.ratios.entries.map((entry) {
            final ratio = entry.value;
            final changePercentage = ratio.percentageChange ?? 0;
            final isPositive = changePercentage > 0;
            final isNeutral = changePercentage == 0;

            Color bgGradientStart, bgGradientEnd, borderColor, dividerColor;

            if (isPositive) {
              bgGradientStart = Colors.green.shade50;
              bgGradientEnd = Colors.green.shade100;
              borderColor = Colors.green.shade200;
              dividerColor = Colors.green.shade200;
              if (isDark) {
                bgGradientStart = Colors.green.shade900.withOpacity(0.15);
                bgGradientEnd = Colors.green.shade800.withOpacity(0.15);
                borderColor = Colors.green.shade800.withOpacity(0.5);
                dividerColor = Colors.green.shade800.withOpacity(0.5);
              }
            } else if (isNeutral) {
              bgGradientStart = Colors.grey.shade50;
              bgGradientEnd = Colors.grey.shade100;
              borderColor = Colors.grey.shade200;
              dividerColor = Colors.grey.shade200;
              if (isDark) {
                bgGradientStart = Colors.grey.shade900.withOpacity(0.15);
                bgGradientEnd = Colors.grey.shade800.withOpacity(0.15);
                borderColor = Colors.grey.shade700.withOpacity(0.5);
                dividerColor = Colors.grey.shade700.withOpacity(0.5);
              }
            } else {
              bgGradientStart = Colors.red.shade50;
              bgGradientEnd = Colors.red.shade100;
              borderColor = Colors.red.shade200;
              dividerColor = Colors.red.shade200;
              if (isDark) {
                bgGradientStart = Colors.red.shade900.withOpacity(0.15);
                bgGradientEnd = Colors.red.shade800.withOpacity(0.15);
                borderColor = Colors.red.shade800.withOpacity(0.5);
                dividerColor = Colors.red.shade800.withOpacity(0.5);
              }
            }

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bgGradientStart, bgGradientEnd],
                ),
                border: Border.all(color: borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reduced from 16
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ratio Name
                  Text(
                    _formatRatioName(entry.key),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8), // Reduced from 12

                  // Period 1 Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _comparisonData!.data.period1,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        ratio.period1?.toStringAsFixed(2) ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Period 2 Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _comparisonData!.data.period2,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        ratio.period2?.toStringAsFixed(2) ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  Divider(height: 8, thickness: 1, color: dividerColor.withOpacity(0.3)), // Reduced height from 16

                  // Change Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Change: ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          if (ratio.difference != null)
                            Text(
                              '${ratio.difference! > 0 ? "+" : ""}${ratio.difference!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getChangeColor(ratio.difference),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        ratio.percentageChange != null
                            ? '${isPositive ? "+" : ""}${ratio.percentageChange!.toStringAsFixed(2)}%'
                            : '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getChangeColor(ratio.percentageChange),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
