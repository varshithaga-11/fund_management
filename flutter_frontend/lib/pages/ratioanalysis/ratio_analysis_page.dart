import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/responsive_helper.dart';
import '../../theme/app_theme.dart';
import '../../routes/route_constants.dart';
import '../financialstatements/financial_statements_api.dart';

class RatioAnalysisPage extends StatefulWidget {
  const RatioAnalysisPage({super.key});

  @override
  State<RatioAnalysisPage> createState() => _RatioAnalysisPageState();
}

class _RatioAnalysisPageState extends State<RatioAnalysisPage> {
  List<FinancialPeriodData> _periods = [];
  List<FinancialPeriodData> _filteredPeriods = [];
  bool _loading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPeriods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPeriods() async {
    try {
      final periods = await getFinancialPeriods();
      setState(() {
        _periods = periods;
        _filteredPeriods = periods;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching periods: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _filterPeriods(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPeriods = _periods;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredPeriods = _periods.where((period) {
          final label = period.label.toLowerCase();
          return label.contains(lowerQuery) || 
                 period.startDate.contains(lowerQuery) || 
                 period.endDate.contains(lowerQuery);
        }).toList();
      }
    });
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
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading periods...', 
                style: TextStyle(
                  fontSize: 14, 
                  color: isDark ? AppColors.gray400 : AppColors.gray600
                )
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ratio Analysis',
                            style: (isDark ? h2 : h2).copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a financial period to analyze ratios or view trends',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.gray400 : AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.trendAnalysis,
                          );
                        },
                        icon: const Icon(Icons.trending_up, size: 18),
                        label: const Text('View Trends'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.gray200
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 20, color: AppColors.gray400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by month name or year...',
                              hintStyle: TextStyle(
                                color: isDark ? AppColors.gray500 : AppColors.gray400,
                                fontSize: 14
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: _filterPeriods,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.gray900,
                              fontSize: 14
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _filterPeriods("");
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Found ${_filteredPeriods.length} period${_filteredPeriods.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Period Grid
                  if (_periods.isEmpty)
                    _buildEmptyState(context, isDark, true)
                  else if (_filteredPeriods.isEmpty)
                    _buildEmptyState(context, isDark, false)
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                        
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 1.6, // Higher aspect ratio = Shorter height
                          ),
                          itemCount: _filteredPeriods.length,
                          itemBuilder: (context, index) {
                            final period = _filteredPeriods[index];
                            return PeriodCardWidget(
                              period: period,
                              isDark: isDark,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '${AppRoutes.ratioDashboard}/${period.id}',
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool isNoData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppColors.gray800 : AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined, 
                size: 40, 
                color: isDark ? AppColors.gray600 : AppColors.gray400
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isNoData ? "No Periods Found" : "No Results Found",
              style: (isDark ? h4 : h4).copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.gray900
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isNoData 
                ? "Please upload financial statements to start analyzing ratios."
                : "Try adjusting your search filters to find the period you're looking for.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.gray500 : AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Hoverable Period Card Widget
class PeriodCardWidget extends StatefulWidget {
  final FinancialPeriodData period;
  final bool isDark;
  final VoidCallback onTap;

  const PeriodCardWidget({
    required this.period,
    required this.isDark,
    required this.onTap,
    super.key,
  });

  @override
  State<PeriodCardWidget> createState() => _PeriodCardWidgetState();
}

class _PeriodCardWidgetState extends State<PeriodCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.period.isFinalized ? AppColors.success : AppColors.warning;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -6.0 : 0.0),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : Colors.white,
            border: Border.all(
              color: widget.isDark ? AppColors.darkBorder : AppColors.gray200,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.02),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20), // Reduced from 24
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Icon and Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44, // Slightly smaller
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.isDark 
                            ? AppColors.info.withOpacity(0.1) 
                            : AppColors.info.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.description_outlined, 
                        color: widget.isDark ? AppColors.info : AppColors.primary, 
                        size: 22
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.period.isFinalized ? 'Finalized' : 'Draft',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Reduced from 20

                // Period Label
                Text(
                  widget.period.label,
                  style: (widget.isDark ? h3 : h3).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17, // Slightly smaller
                    color: _isHovered
                        ? AppColors.primary
                        : (widget.isDark ? Colors.white : AppColors.gray900),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8), // Reduced from 12

                // Date Range
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined, 
                      size: 13, 
                      color: widget.isDark ? AppColors.gray400 : AppColors.gray500
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.period.startDate} - ${widget.period.endDate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark ? AppColors.gray400 : AppColors.gray600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                const Divider(height: 24), // Reduced from 32

                // Footer CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'View Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: widget.isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded, 
                      size: 15, 
                      color: _isHovered 
                          ? AppColors.primary 
                          : (widget.isDark ? AppColors.gray500 : AppColors.gray400)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
