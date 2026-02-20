import 'package:flutter/material.dart';
import '../../financialstatements/financial_statements_api.dart';
import 'ratio_dashboard.dart';
import 'trend_analysis_page.dart';
// import 'ratio_benchmarks_page.dart'; // Optional, user might want to navigate here

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
          SnackBar(content: Text('Error fetching periods: $e')),
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
          // Also check month names if we parse start_date
          // Simpler: just check label and dates string
          return label.contains(lowerQuery) || 
                 period.startDate.contains(lowerQuery) || 
                 period.endDate.contains(lowerQuery);
        }).toList();
      }
    });
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
        title: const Text('Ratio Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            tooltip: 'View Trends',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TrendAnalysisPage()),
              );
            },
          ),
          // Optionally add link to Benchmarks page if needed, but not in original header
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by month name or year...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterPeriods("");
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterPeriods,
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Found ${_filteredPeriods.length} period${_filteredPeriods.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),

            // Period Grid
            Expanded(
              child: _filteredPeriods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _periods.isEmpty
                                ? "No Periods Found"
                                : "No Results Found",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _periods.isEmpty
                                ? "Please upload financial statements to start analyzing ratios."
                                : "Try adjusting your search filters.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(builder: (context, constraints) {
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth > 900
                              ? 3
                              : (constraints.maxWidth > 600 ? 2 : 1),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _filteredPeriods.length,
                        itemBuilder: (context, index) {
                          final period = _filteredPeriods[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RatioDashboardPage(periodId: period.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.insert_chart,
                                              color: Colors.blue.shade700),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: period.isFinalized
                                                ? Colors.green.shade50
                                                : Colors.amber.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            period.isFinalized
                                                ? 'Finalized'
                                                : 'Draft',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: period.isFinalized
                                                  ? Colors.green.shade700
                                                  : Colors.amber.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      period.label,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${period.startDate} - ${period.endDate}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'View Analysis',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward,
                                            size: 14, color: Colors.grey),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
            ),
          ],
        ),
      ),
    );
  }
}
