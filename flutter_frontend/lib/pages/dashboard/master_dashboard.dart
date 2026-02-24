import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// Platform helpers: dart:io on native, dart:html on web — isolated via conditional import
import 'export_stub.dart'
    if (dart.library.html) 'export_web.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_helper.dart'; // Added
import 'dashboard_api.dart';


class MasterDashboardPage extends StatefulWidget {
  const MasterDashboardPage({Key? key}) : super(key: key);

  @override
  State<MasterDashboardPage> createState() => _MasterDashboardPageState();
}

class _MasterDashboardPageState extends State<MasterDashboardPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  DashboardData? _dashboardData;

  // Filter / Export state
  bool _showExportMenu = false;
  bool _showYearDropdown = false;
  String? _selectedYear; // null = show all periods
  final TextEditingController _yearSearchController = TextEditingController();
  final LayerLink _exportLayerLink = LayerLink();
  final LayerLink _yearLayerLink = LayerLink();
  OverlayEntry? _exportOverlay;
  OverlayEntry? _yearOverlay;

  int _donutTouchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _yearSearchController.dispose();
    _removeExportOverlay();
    _removeYearOverlay();
    super.dispose();
  }

  // Returns only periods matching the selected year label (or all if none selected)
  List<DashboardPeriodData> get _filteredPeriods {
    final all = _dashboardData?.periods ?? [];
    if (_selectedYear == null) return all;
    return all.where((p) => p.label == _selectedYear).toList();
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await getDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
          _isRefreshing = false;
        });
        debugPrint('Dashboard: loaded ${data?.periods.length ?? 0} periods');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadDashboardData();
  }

  // ============ EXPORT DATA HELPER ============

  List<Map<String, dynamic>> _getExportData() {
    final periods = _filteredPeriods;
    return periods.map((p) => {
      'Label': p.label,
      'Type': p.periodType,
      'Status': p.isFinalized ? 'Finalized' : 'Draft',
      'Revenue': p.revenue.toStringAsFixed(2),
      'Net Profit': p.netProfit.toStringAsFixed(2),
    }).toList();
  }

  // ============ CSV EXPORT ============

  Future<void> _handleExportCSV({bool isExcel = false}) async {
    try {
      final data = _getExportData();
      if (data.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      final ext = isExcel ? 'xlsx' : 'csv';
      // Use explicit ordered columns so they always appear in the right order
      const colOrder = ['Label', 'Type', 'Status', 'Revenue', 'Net Profit'];
      final headerLine = colOrder.join(',');
      final rowLines = data.map((row) =>
          colOrder.map((k) => '"${row[k] ?? ''}"').join(',')).join('\n');
      
      // Add UTF-8 BOM for Excel compatibility (crucial for ₹ and other symbols)
      final csvContent = '\uFEFF$headerLine\n$rowLines';
      final filename = 'financial_data_$dateStr.$ext';

      if (kIsWeb) {
        downloadTextWeb(filename, csvContent);
      } else {
        await saveTextAndOpenNative(filename, csvContent);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ext file exported')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  // ============ PDF EXPORT ============

  Future<void> _handleExportPDF() async {
    try {
      final data = _getExportData();
      if (data.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }
      final bytes = await _buildPdfBytes(data);
      final filename = 'financial_report_${DateTime.now().toIso8601String().split('T')[0]}.pdf';
      if (kIsWeb) {
        downloadFileWeb(filename, bytes);
      } else {
        await saveAndOpenNative(filename, bytes);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF exported successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    }
  }

  // ============ WORD EXPORT ============

  Future<void> _handleExportWord() async {
    try {
      final data = _getExportData();
      if (data.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }
      final dateStr = DateTime.now().toLocal().toString().split(' ')[0];
      final tableRows = data.map((r) => '<tr>'
          '<td>${r['Label']}</td><td>${r['Type']}</td>'
          '<td>${r['Status']}</td><td>${r['Revenue']}</td><td>${r['Net Profit']}</td>'
          '</tr>').join('');
      final content = '''
<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns="http://www.w3.org/TR/REC-html40">
<head><meta charset="utf-8"><title>Financial Report</title></head>
<body>
  <h2>Financial Dashboard Report</h2>
  <p>Generated: $dateStr</p>
  <table border="1" style="border-collapse:collapse;width:100%">
    <thead><tr style="background-color:#4F46E5;color:white">
      <th>Label</th><th>Type</th><th>Status</th><th>Revenue</th><th>Net Profit</th>
    </tr></thead>
    <tbody>$tableRows</tbody>
  </table>
</body></html>''';
      final filename = 'financial_report_${DateTime.now().toIso8601String().split('T')[0]}.doc';
      if (kIsWeb) {
        downloadTextWeb(filename, content);
      } else {
        await saveTextAndOpenNative(filename, content);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Word document exported')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Word export failed: $e')));
    }
  }

  // ============ PRINT ============

  Future<void> _handlePrint() async {
    try {
      final data = _getExportData();
      if (kIsWeb) {
        // Web: trigger browser print dialog (same as React's window.print())
        printWeb();
      } else {
        // Native: generate PDF and open system print dialog
        final bytes = await _buildPdfBytes(data);
        final filename = 'print_${DateTime.now().toIso8601String().split('T')[0]}.pdf';
        await saveAndOpenNative(filename, bytes);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print dialog opened')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print failed: $e')));
    }
  }

  // ============ SHARED PDF BUILDER ============

  Future<List<int>> _buildPdfBytes(List<Map<String, dynamic>> data) async {
    final doc = pw.Document();
    final dateStr = DateTime.now().toLocal().toString().split(' ')[0];
    final headers = ['Label', 'Type', 'Status', 'Revenue', 'Net Profit'];
    final rows = data
        .map((r) => [r['Label']!, r['Type']!, r['Status']!, r['Revenue']!, r['Net Profit']!])
        .toList();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Text('Financial Dashboard Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text('Generated: $dateStr', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        pw.SizedBox(height: 20),
        if (data.isEmpty)
          pw.Text('No data available.', style: const pw.TextStyle(fontSize: 12))
        else
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
            cellAlignments: {0: pw.Alignment.centerLeft},
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            cellHeight: 28,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerHeight: 30,
          ),
      ],
    ));
    return doc.save();
  }


  String _formatCurrency(double value) {
    final v = value / 1000000;
    return v.toStringAsFixed(2);
  }

  String _formatPercentage(double value) {
    final rounded = value.abs() < 0.05 ? 0.0 : value;
    return rounded.toStringAsFixed(1);
  }

  // ============ OVERLAY HELPERS ============

  void _removeExportOverlay() {
    _exportOverlay?.remove();
    _exportOverlay = null;
  }

  void _removeYearOverlay() {
    _yearOverlay?.remove();
    _yearOverlay = null;
  }

  void _toggleExportMenu(BuildContext context) {
    if (_showExportMenu) {
      _removeExportOverlay();
      setState(() => _showExportMenu = false);
    } else {
      _removeYearOverlay();
      setState(() {
        _showYearDropdown = false;
        _showExportMenu = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _exportOverlay = _buildExportOverlayEntry(context);
        Overlay.of(context).insert(_exportOverlay!);
      });
    }
  }

  void _toggleYearDropdown(BuildContext context) {
    debugPrint('_toggleYearDropdown called, current state: $_showYearDropdown');
    if (_showYearDropdown) {
      _removeYearOverlay();
      setState(() => _showYearDropdown = false);
    } else {
      _removeExportOverlay();
      setState(() {
        _showExportMenu = false;
        _showYearDropdown = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _yearOverlay = _buildYearOverlayEntry(context);
        Overlay.of(context).insert(_yearOverlay!);
      });
    }
  }

  OverlayEntry _buildExportOverlayEntry(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeExportOverlay();
          setState(() => _showExportMenu = false);
        },
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _exportLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 44),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.white,
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.gray200),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.12), blurRadius: 16)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildExportItem('CSV', '.csv', isDark, () {
                          _removeExportOverlay();
                          setState(() => _showExportMenu = false);
                          _handleExportCSV();
                        }),
                        _buildExportItem('Excel', '.xlsx', isDark, () {
                          _removeExportOverlay();
                          setState(() => _showExportMenu = false);
                          _handleExportCSV(isExcel: true);
                        }),
                        _buildExportItem('PDF', '.pdf', isDark, () {
                          _removeExportOverlay();
                          setState(() => _showExportMenu = false);
                          _handleExportPDF();
                        }),
                        _buildExportItem('Word', '.doc', isDark, () {
                          _removeExportOverlay();
                          setState(() => _showExportMenu = false);
                          _handleExportWord();
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportItem(String label, String ext, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(label, style: AppTypography.body3.copyWith(fontWeight: FontWeight.w600, color: isDark ? AppColors.gray300 : AppColors.gray700)),
            const Spacer(),
            Text(ext, style: AppTypography.body3.copyWith(color: AppColors.gray400, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  OverlayEntry _buildYearOverlayEntry(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeYearOverlay();
          setState(() => _showYearDropdown = false);
        },
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _yearLayerLink,
              showWhenUnlinked: true,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 8),
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                color: isDark ? AppColors.darkCard : AppColors.white,
                child: Container(
                  width: 280,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.white,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.gray300),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.12), blurRadius: 16)],
                  ),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      final allPeriods = _dashboardData?.periods ?? [];
                      final searchText = _yearSearchController.text.toLowerCase();
                      final filtered = allPeriods
                          .where((p) => p.label.toLowerCase().contains(searchText))
                          .toList();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBg : AppColors.gray50,
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.gray300),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Icon(Icons.search, size: 16, color: AppColors.gray400),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: TextField(
                                      controller: _yearSearchController,
                                      onChanged: (_) => setOverlayState(() {}),
                                      style: AppTypography.body3.copyWith(
                                          color: isDark ? AppColors.white : AppColors.black),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Search periods...',
                                        hintStyle: AppTypography.body3.copyWith(color: AppColors.gray400),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  if (_yearSearchController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 14),
                                      onPressed: () {
                                        _yearSearchController.clear();
                                        setOverlayState(() {});
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: [
                                _buildYearDropdownItem(
                                  label: 'All Periods',
                                  isSelected: _selectedYear == null,
                                  isDark: isDark,
                                  isReset: true,
                                  onTap: () {
                                    _removeYearOverlay();
                                    setState(() {
                                      _showYearDropdown = false;
                                      _selectedYear = null;
                                    });
                                  },
                                ),
                                const Divider(height: 1),
                                if (filtered.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        Icon(Icons.info_outline, size: 24, color: AppColors.gray400),
                                        const SizedBox(height: 8),
                                        Text(
                                          allPeriods.isEmpty
                                              ? 'No periods found.\nCheck if data is loaded.'
                                              : 'No results matching search.',
                                          style: AppTypography.body3.copyWith(color: AppColors.gray400),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...filtered.map((p) => _buildYearDropdownItem(
                                        label: p.label,
                                        isSelected: false,
                                        isDark: isDark,
                                        onTap: () {
                                          _removeYearOverlay();
                                          Navigator.pushNamed(context, '/ratio-analysis/dashboard/${p.id}');
                                        },
                                      )),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearDropdownItem({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    bool isReset = false,
  }) {
    return _HoverEffect(
      hoverScale: 1.0,
      hoverElevation: 0,
      builder: (isHovered) => InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: isSelected 
            ? AppColors.primary.withOpacity(0.12) 
            : (isHovered ? (isDark ? AppColors.gray700 : AppColors.gray100) : Colors.transparent),
          child: Row(
            children: [
              if (isReset)
                Icon(Icons.clear_all, size: 16, color: isSelected ? AppColors.primary : AppColors.gray400)
              else if (isSelected)
                const Icon(Icons.check, size: 16, color: AppColors.primary)
              else
                Icon(Icons.calendar_today, size: 14, color: isHovered ? AppColors.primary : AppColors.gray400), 
              
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body3.copyWith(
                    color: isSelected 
                      ? AppColors.primary 
                      : (isDark ? AppColors.white : AppColors.black),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text('Loading Dashboard...',
                style: AppTypography.body2.copyWith(color: AppColors.gray500, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isDesktop = width >= 1024;

    final periods = _dashboardData?.periods ?? []; 
    
    // Use API-provided stats for the dashboard overview (parity with React)
    final double revenueValue = _dashboardData?.totalRevenue ?? 0.0;
    final double marginValue = _dashboardData?.avgProfitMargin ?? 0.0;
    final double growthValue = _dashboardData?.growthRate ?? 0.0;
    
    final totalPeriods = periods.length;
    final finalizedPeriods = periods.where((p) => p.isFinalized).length;

    // Top periods by profit (always from all periods)
    final topPeriodsList = List<DashboardPeriodData>.from(periods)
      ..sort((a, b) => b.netProfit.compareTo(a.netProfit));
    final top5 = topPeriodsList.take(5).toList();

    // Recent by created_at desc (always from all periods)
    final recent = List<DashboardPeriodData>.from(periods)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent5 = recent.take(5).toList();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let shell handle background
        body: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== HEADER =====
                _buildHeader(isDark, isMobile, context),
                SizedBox(height: AppSpacing.xxl),
    
                // ===== FILTER BAR =====
                _buildFilterBar(isDark, context),
                SizedBox(height: AppSpacing.xxl),
    
                // ===== MAIN STAT CARDS (3 cards, responsive) =====
                _buildMainStatCards(isDark, isMobile, revenueValue, marginValue, growthValue),
                SizedBox(height: AppSpacing.xxl),
    
                // ===== SECONDARY STATS ROW =====
                _buildSecondaryStats(isDark, isMobile, totalPeriods, finalizedPeriods, _dashboardData?.totalProfit ?? 0.0),
                SizedBox(height: AppSpacing.xxl),
    
                // ===== CHARTS =====
                _buildChartsSection(isDark, isMobile, isDesktop, periods),
                SizedBox(height: AppSpacing.xxl),
    
                // ===== BOTTOM: TOP PERIODS + RECENT ACTIVITY =====
                _buildBottomSection(isDark, isMobile, top5, recent5, context),
                SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ HEADER ============

  Widget _buildHeader(bool isDark, bool isMobile, BuildContext context) {
    final titleRow = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Dashboard',
          style: AppTypography.h2.copyWith(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Overview of your fund management system',
          style: AppTypography.body2.copyWith(color: isDark ? AppColors.gray400 : AppColors.gray600),
        ),
      ],
    );

    final buttonRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Export button with dropdown
          CompositedTransformTarget(
            link: _exportLayerLink,
            child: _buildHeaderButton(
              isDark: isDark,
              icon: Icons.download_outlined,
              label: 'Export',
              trailingIcon: Icons.keyboard_arrow_down,
              trailingRotated: _showExportMenu,
              onTap: () => _toggleExportMenu(context),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          _buildHeaderButton(
            isDark: isDark,
            icon: Icons.print_outlined,
            label: 'Print',
            onTap: _handlePrint,
          ),
          SizedBox(width: AppSpacing.md),
          _buildHeaderButton(
            isDark: isDark,
            icon: Icons.refresh,
            label: 'Refresh',
            isSpinning: _isRefreshing,
            onTap: _isRefreshing ? null : _handleRefresh,
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          SizedBox(height: AppSpacing.lg),
          buttonRow,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleRow),
        SizedBox(width: AppSpacing.md),
        buttonRow,
      ],
    );
  }

  Widget _buildHeaderButton({
    required bool isDark,
    required IconData icon,
    required String label,
    IconData? trailingIcon,
    bool trailingRotated = false,
    bool isSpinning = false,
    VoidCallback? onTap,
  }) {
    return _HoverEffect(
      hoverScale: 1.03,
      hoverElevation: 8,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      builder: (isHovered) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isHovered 
              ? (isDark ? AppColors.gray700 : AppColors.gray50) 
              : (isDark ? AppColors.darkCard : AppColors.white),
            border: Border.all(
              color: isHovered ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.gray200),
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(isHovered ? 0.12 : 0.06), 
                blurRadius: isHovered ? 8 : 4,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSpinning)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.gray500)),
                )
              else
                Icon(icon, size: 16, color: isHovered ? AppColors.primary : (isDark ? AppColors.gray300 : AppColors.gray700)),
              SizedBox(width: AppSpacing.sm),
              Text(label,
                  style: AppTypography.body3
                      .copyWith(
                        fontWeight: isHovered ? FontWeight.w600 : FontWeight.w500, 
                        color: isHovered ? AppColors.primary : (isDark ? AppColors.gray300 : AppColors.gray700),
                      )),
              if (trailingIcon != null) ...[
                SizedBox(width: AppSpacing.xs),
                AnimatedRotation(
                  turns: trailingRotated ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(trailingIcon, size: 16, color: isHovered ? AppColors.primary : (isDark ? AppColors.gray400 : AppColors.gray500)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============ FILTER BAR ============

  Widget _buildFilterBar(bool isDark, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.gray200),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.tune, size: 16, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.md),
          Text('Filters',
              style: AppTypography.body2.copyWith(
                  fontWeight: FontWeight.w600, color: isDark ? AppColors.white : AppColors.black)),
          const Spacer(),
          // Period filter dropdown — shows active label + clear button when filtered
          CompositedTransformTarget(link: _yearLayerLink,
            child: _HoverEffect(
              hoverScale: 1.02,
              hoverElevation: 4,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              builder: (isHovered) => GestureDetector(
                onTap: () => _toggleYearDropdown(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isHovered 
                        ? (isDark ? AppColors.gray700 : AppColors.gray100)
                        : (isDark ? AppColors.darkBg : AppColors.gray50),
                    border: Border.all(
                        color: isHovered ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.gray300)),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Period',
                        style: AppTypography.body3.copyWith(
                            color: isDark ? AppColors.white : AppColors.black,
                            fontWeight: FontWeight.normal),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.gray400),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ MAIN STAT CARDS ============

  Widget _buildMainStatCards(bool isDark, bool isMobile, double revenue, double margin, double growth) {
    final cards = [
      _buildMainStatCard(
        isDark: isDark,
        title: 'Total Revenue',
        value: '₹${_formatCurrency(revenue)}M',
        icon: Icons.trending_up,
        gradientStart: AppColors.gradientGreenStart,
        gradientEnd: AppColors.gradientGreenEnd,
        bgColor: const Color(0xFF10B98110),
      ),
      _buildMainStatCard(
        isDark: isDark,
        title: 'Avg Profit Margin',
        value: '${_formatPercentage(margin)}%',
        icon: Icons.percent,
        gradientStart: AppColors.gradientPurpleStart,
        gradientEnd: AppColors.gradientPurpleEnd,
        bgColor: const Color(0x1A8B5CF6),
      ),
      _buildMainStatCard(
        isDark: isDark,
        title: 'Growth Rate',
        value: '${growth > 0 ? '+' : ''}${_formatPercentage(growth)}%',
        icon: growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
        gradientStart: AppColors.gradientOrangeStart,
        gradientEnd: AppColors.gradientOrangeEnd,
        bgColor: const Color(0x1AF59E0B),
        trailingIcon: growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
        trailingColor: growth >= 0 ? AppColors.success : AppColors.danger,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(padding: EdgeInsets.only(bottom: AppSpacing.lg), child: c))
            .toList(),
      );
    }

    return Row(
      children: cards.asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? AppSpacing.lg : 0),
            child: c,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMainStatCard({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color gradientStart,
    required Color gradientEnd,
    required Color bgColor,
    IconData? trailingIcon,
    Color? trailingColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.gray200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.hardEdge,
          children: [
            // Background gradient circle - top right (React style)
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      gradientStart.withOpacity(0.15),
                      gradientEnd.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge (React style: h-12 w-12)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gradientStart, gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradientEnd.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 16),
                  // Metric value (React text-3xl font-bold)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: TextStyle(
                            color: isDark ? AppColors.white : AppColors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 32,
                            letterSpacing: -0.8,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          trailingIcon,
                          size: 24,
                          color: trailingColor ?? AppColors.success,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Label text (React text-sm)
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ), // Stack
        ), // ClipRRect
      ), // AnimatedContainer
    ); // MouseRegion
  }

  // ============ SECONDARY STATS ============

  Widget _buildSecondaryStats(bool isDark, bool isMobile, int totalPeriods, int finalizedPeriods, double totalProfit) {
    final cards = [
      _buildSecondaryCard(
        isDark: isDark,
        label: 'Financial Periods',
        value: '$totalPeriods',
        icon: Icons.description_outlined,
        iconColor: AppColors.primary,
        gradientColors: [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
        darkGradientColors: [AppColors.darkCard, AppColors.darkBg],
        badgeText: '$finalizedPeriods Finalized',
        badgeIcon: Icons.bolt,
      ),
      _buildSecondaryCard(
        isDark: isDark,
        label: 'Total Net Profit',
        value: '₹${_formatCurrency(totalProfit)}M',
        icon: Icons.trending_up,
        iconColor: AppColors.success,
        gradientColors: [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
        darkGradientColors: [AppColors.darkCard, AppColors.darkBg],
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(padding: EdgeInsets.only(bottom: AppSpacing.lg), child: c))
            .toList(),
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        SizedBox(width: AppSpacing.lg),
        Expanded(child: cards[1]),
      ],
    );
  }

  Widget _buildSecondaryCard({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required List<Color> darkGradientColors,
    String? badgeText,
    IconData? badgeIcon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? darkGradientColors : gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.gray200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.body3
                          .copyWith(color: isDark ? AppColors.gray400 : AppColors.gray600, fontWeight: FontWeight.w500)),
                  SizedBox(height: AppSpacing.sm),
                  Text(value,
                      style: AppTypography.h3.copyWith(
                          color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(isDark ? 0.1 : 0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.08),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 28),
                ),
              ),
            ],
          ),
          if (badgeText != null) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.circle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badgeIcon != null) ...[
                    Icon(badgeIcon, size: 12, color: AppColors.primary),
                    SizedBox(width: AppSpacing.xs),
                  ],
                  Text(badgeText,
                      style: AppTypography.body3.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ CHARTS ============

  Widget _buildChartsSection(bool isDark, bool isMobile, bool isDesktop, List<DashboardPeriodData> periods) {
    final barChart = _buildChartCard(
      isDark: isDark,
      title: 'Revenue & Profit Analysis',
      child: _buildBarChart(periods, isDark),
    );
    final donutChart = _buildChartCard(
      isDark: isDark,
      title: 'Period Distribution',
      child: _buildDonutChart(periods, isDark),
    );

    if (isMobile) {
      return Column(
        children: [
          barChart,
          SizedBox(height: AppSpacing.lg),
          donutChart,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 8, child: barChart),
          SizedBox(width: AppSpacing.lg),
          Expanded(flex: 4, child: donutChart),
        ],
      ),
    );
  }

  Widget _buildChartCard({required bool isDark, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.gray200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.h5.copyWith(
                  color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<DashboardPeriodData> periods, bool isDark) {
    // Sort by createdAt and take last 10
    final sorted = List<DashboardPeriodData>.from(periods)
      ..sort((a, b) => DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));
    final last10 = sorted.length > 10 ? sorted.sublist(sorted.length - 10) : sorted;

    if (last10.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text('No data available', style: AppTypography.body2.copyWith(color: AppColors.gray400)),
        ),
      );
    }

    final currencyFmt = NumberFormat.compactSimpleCurrency(locale: 'en_IN', name: '₹');
    final fullCurrencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    double maxDataValue = 0;
    for (final p in last10) {
      if (p.revenue > maxDataValue) maxDataValue = p.revenue;
      if (p.netProfit > maxDataValue) maxDataValue = p.netProfit;
    }
    
    // Match React Image scale: 0 to 8000K in steps of 2000K
    double interval = 2000000; 
    double maxY = 8000000;
    
    // Check if data actually exceeds 8M, adjust if necessary to prevent overflow
    if (maxDataValue > maxY) {
      maxY = ((maxDataValue / interval).ceil() * interval).toDouble();
    }

    return Column(
      children: [
        Expanded(
          child: ClipRect(
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                barGroups: last10.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barsSpace: 6,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.netProfit,
                      color: const Color(0xFF3B82F6), // Vibrant Blue from image
                      width: 45,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: entry.value.revenue,
                      color: const Color(0xFF7DD3FC), // Soft Sky Blue from image
                      width: 45,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (val, meta) {
                      final i = val.toInt();
                      if (i < last10.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            last10[i].label,
                            style: AppTypography.caption.copyWith(
                                color: AppColors.gray500, fontSize: 11),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, right: 8),
                    child: Text('Amount (₹)',
                        style: TextStyle(
                            color: isDark ? AppColors.gray400 : AppColors.gray500, 
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 64, 
                    interval: interval, 
                    getTitlesWidget: (val, meta) {
                      final kValue = (val / 1000).toInt();
                      return Text(
                        '₹${kValue}K',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.gray500, fontSize: 10, fontWeight: FontWeight.normal),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: isDark ? AppColors.gray700.withOpacity(0.5) : AppColors.gray200,
                  strokeWidth: 0.5,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.gray700 : AppColors.gray200,
                    width: 1,
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: isDark ? AppColors.darkCard : AppColors.gray800,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, gi, rod, ri) {
                    final label = ri == 0 ? 'Net Profit' : 'Revenue';
                    return BarTooltipItem(
                      '$label\n',
                      AppTypography.body3.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '₹ ${fullCurrencyFmt.format(rod.toY).replaceAll('₹', '').trim()}',
                          style: AppTypography.body3.copyWith(color: rod.color, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Net Profit', const Color(0xFF3C50E0), isDark),
            const SizedBox(width: 24),
            _buildLegendItem('Revenue', const Color(0xFF80CAEE), isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.body3.copyWith(color: isDark ? AppColors.gray300 : AppColors.gray600)),
      ],
    );
  }

  Widget _buildDonutChart(List<DashboardPeriodData> periods, bool isDark) {
    final counts = <String, int>{};
    for (final p in periods) {
      final type = p.periodType.replaceAll('_', ' ');
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final total = periods.length;
    final colors = [
      const Color(0xFF3C50E0),
      const Color(0xFF80CAEE),
      const Color(0xFF0FADCF),
      const Color(0xFF6577F3),
    ];

    if (counts.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(child: Text('No data available', style: AppTypography.body2.copyWith(color: AppColors.gray400))),
      );
    }

    final sections = counts.entries.toList().asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final pct = (e.value / total) * 100;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: pct,
        title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
        titleStyle: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 9),
        radius: 50,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _donutTouchedIndex = -1;
                          return;
                        }
                        _donutTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: counts.entries.toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    final isTouched = i == _donutTouchedIndex;
                    final pct = (e.value / total) * 100;
                    final double radius = isTouched ? 60 : 50;
                    final double fontSize = isTouched ? 12 : 9;

                    return PieChartSectionData(
                      color: colors[i % colors.length],
                      value: pct,
                      title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
                      titleStyle: AppTypography.caption.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.bold, fontSize: fontSize),
                      radius: radius,
                      badgeWidget: isTouched ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.gray800 : AppColors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Text(e.key, style: AppTypography.body3.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                      ) : null,
                      badgePositionPercentageOffset: 1.2,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 65,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total',
                      style: AppTypography.h2.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  Text('Periods',
                      style: AppTypography.caption.copyWith(color: isDark ? AppColors.gray400 : AppColors.gray600)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: counts.entries.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final label = e.key
                .split(' ')
                .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
                .join(' ');
            return _buildLegendItem('$label (${e.value})', colors[i % colors.length], isDark);
          }).toList(),
        ),
      ],
    );
  }

  // ============ BOTTOM SECTION ============

  Widget _buildBottomSection(bool isDark, bool isMobile, List<DashboardPeriodData> top5,
      List<DashboardPeriodData> recent5, BuildContext context) {
    final topCard = _buildTopPeriodsCard(isDark, top5, context);
    final activityCard = _buildRecentActivityCard(isDark, recent5, context);

    if (isMobile) {
      return Column(
        children: [
          topCard,
          SizedBox(height: AppSpacing.lg),
          activityCard,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: topCard),
          SizedBox(width: AppSpacing.lg),
          Expanded(child: activityCard),
        ],
      ),
    );
  }

  // ============ TOP PERIODS ============

  Widget _buildTopPeriodsCard(bool isDark, List<DashboardPeriodData> top5, BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        bottom: 20,
        left: ResponsiveHelper.getResponsiveValue(context, mobile: 20, tablet: 30, desktop: 30),
        right: ResponsiveHelper.getResponsiveValue(context, mobile: 20, tablet: 30, desktop: 30),
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.gray200),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(Icons.emoji_events, color: AppColors.white, size: 20),
              ),
              SizedBox(width: AppSpacing.md),
              Text('Top Periods',
                  style: AppTypography.h5.copyWith(
                      color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: AppSpacing.xl),

          if (top5.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text('No periods available',
                    style: AppTypography.body3.copyWith(color: AppColors.gray400)),
              ),
            )
          else
            Column(
              children: top5.asMap().entries.map((entry) {
                final index = entry.key;
                final period = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HoverEffect(
                    hoverScale: 1.02,
                    hoverElevation: 4,
                    builder: (isHovered) => GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/financial-statements/${period.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? (isHovered ? AppColors.gray700 : AppColors.black.withOpacity(0.1)) : (isHovered ? AppColors.gray50 : AppColors.white),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.gray200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(isHovered ? 0.1 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: index == 0
                                          ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                                          : index == 1
                                              ? [const Color(0xFFD1D5DB), const Color(0xFF9CA3AF)]
                                              : [const Color(0xFF93C5FD), const Color(0xFF3B82F6)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${index + 1}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(period.label,
                                        style: AppTypography.body1.copyWith(
                                            fontWeight: FontWeight.bold, color: isDark ? AppColors.white : AppColors.gray900)),
                                    Text(period.periodType.replaceAll('_', ' '),
                                        style: AppTypography.body3.copyWith(color: AppColors.gray400, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '₹${_formatCurrency(period.netProfit)}M',
                              style: AppTypography.body1.copyWith(
                                  fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }


  // ============ RECENT ACTIVITY TIMELINE ============

  Widget _buildRecentActivityCard(bool isDark, List<DashboardPeriodData> recent5, BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        bottom: 20,
        left: ResponsiveHelper.getResponsiveValue(context, mobile: 20, tablet: 30, desktop: 30),
        right: ResponsiveHelper.getResponsiveValue(context, mobile: 20, tablet: 30, desktop: 30),
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.gray200),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.info, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(Icons.timeline, color: AppColors.white, size: 20),
              ),
              SizedBox(width: AppSpacing.md),
              Text('Recent Activity',
                  style: AppTypography.h5.copyWith(
                      color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: AppSpacing.xl),

          if (recent5.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text('No recent activity found.',
                    style: AppTypography.body3.copyWith(color: AppColors.gray400)),
              ),
            )
          else
            // Timeline items - each item is a single Row with dot+line and content
            Column(
              children: recent5.asMap().entries.map((entry) {
                final index = entry.key;
                final period = entry.value;
                final isLast = index == recent5.length - 1;
                final isFinalized = period.isFinalized;
                final timeAgo = _timeAgo(period.createdAt);

                return _HoverEffect(
                  hoverScale: 1.02,
                  hoverElevation: 4,
                  cursor: SystemMouseCursors.click,
                  builder: (isHovered) => GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/financial-statements/${period.id}'),
                    child: IntrinsicHeight(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: dot + dashed line
                        SizedBox(
                          width: 40,
                          child: Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isFinalized ? AppColors.success : AppColors.warning,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (isFinalized ? AppColors.success : AppColors.warning).withOpacity(0.2),
                                    width: 3,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: CustomPaint(
                                    size: const Size(1, double.infinity),
                                    painter: _DashedLinePainter(
                                      color: isDark ? AppColors.gray700 : AppColors.gray300,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Right: Card content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark ? (isHovered ? AppColors.gray700 : AppColors.black.withOpacity(0.1)) : (isHovered ? AppColors.gray50 : AppColors.white),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.gray200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isHovered ? 0.1 : 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        period.label,
                                        style: AppTypography.body1.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.white : AppColors.gray900,
                                        ),
                                      ),
                                      Text(
                                        timeAgo,
                                        style: AppTypography.body2.copyWith(
                                          color: isDark ? AppColors.gray500 : AppColors.gray400,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        isFinalized ? Icons.check_circle_outline : Icons.edit_note,
                                        size: 14,
                                        color: isFinalized ? AppColors.success : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isFinalized ? 'Finalized' : 'Draft',
                                        style: AppTypography.body3.copyWith(
                                          color: isFinalized ? AppColors.success : AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                );
              }).toList().cast<Widget>(),
            ),
        ],
      ),
    );
  }

  String _timeAgo(String createdAtStr) {
    try {
      final createdAt = DateTime.parse(createdAtStr);
      final diff = DateTime.now().difference(createdAt);
      final minutes = diff.inMinutes;
      final hours = diff.inHours;
      final days = diff.inDays;
      if (minutes < 60) return '${minutes}m ago';
      if (hours < 24) return '${hours}h ago';
      return '${days}d ago';
    } catch (_) {
      return '';
    }
  }
}

// Hover effect wrapper widget for interactive elements
class _HoverEffect extends StatefulWidget {
  final Widget Function(bool isHovered) builder;
  final double hoverScale;
  final double hoverElevation;
  final BorderRadius? borderRadius;
  final MouseCursor? cursor;

  const _HoverEffect({
    required this.builder,
    this.hoverScale = 1.02,
    this.hoverElevation = 8,
    this.borderRadius,
    this.cursor,
  });

  @override
  State<_HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<_HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor ?? SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        transform: Matrix4.identity()
          ..scale(_isHovered ? widget.hoverScale : 1.0),
        transformAlignment: Alignment.center,
        child: widget.builder(_isHovered),
      ),
    );
  }
}

// Custom painter for dashed vertical line
class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;
    final x = size.width / 2;

    while (startY < size.height) {
      canvas.drawLine(Offset(x, startY), Offset(x, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
