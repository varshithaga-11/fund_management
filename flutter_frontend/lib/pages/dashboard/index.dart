import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dashboard_api.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  bool refreshing = false;
  DashboardData? data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await getDashboardData();
      if (mounted) {
        setState(() {
          data = res;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    await _loadData();
    setState(() => refreshing = false);
  }

  String formatCurrency(double val) {
    return (val / 1000000).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Default values if data null
    final periods = data?.periods ?? [];
    final totalRevenue = data?.totalRevenue ?? 0;
    
    // Calculate total profit manually from filtered periods as per React logic (filteredPeriods)
    // But here 'periods' IS the filtered list from API
    // React code: const totalProfit = filteredPeriods.reduce(...)
    double totalProfit = 0;
    for (var p in periods) {
      totalProfit += p.netProfit;
    }

    final avgProfitMargin = data?.avgProfitMargin ?? 0;
    final growthRate = data?.growthRate ?? 0;
    final finalizedCount = periods.where((p) => p.isFinalized).length;

    // Top 5 by Profit
    final topPeriods = List<DashboardPeriodData>.from(periods)
      ..sort((a, b) => b.netProfit.compareTo(a.netProfit));
    final top5 = topPeriods.take(5).toList();

    // Recent Activity (sort by createdAt desc)
    final recent = List<DashboardPeriodData>.from(periods)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent5 = recent.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Dashboard"),
        actions: [
          IconButton(
            icon: refreshing 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Icon(Icons.refresh),
            onPressed: refreshing ? null : _refresh,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Stats Grid
              const Text("Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              GridView.count(
                crossAxisCount: 2, // Start with 2 per row for mobile/tablet responsive feel
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard("Total Revenue", "₹${formatCurrency(totalRevenue)}M", Colors.green, Icons.trending_up),
                  _buildStatCard("Avg Profit Margin", "${avgProfitMargin.toStringAsFixed(1)}%", Colors.purple, Icons.percent),
                  _buildStatCard("Growth Rate", "${growthRate > 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%", Colors.orange, Icons.moving),
                  _buildStatCard("Total Periods", "${periods.length} ($finalizedCount Final)", Colors.blue, Icons.description),
                ],
              ),
              
              const SizedBox(height: 24),

              // Charts
              const Text("Visual Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Simple Bar Chart Placeholder (Full FL Chart impl is verbose, keeping simple for "index" conversion scope)
              // Or better: Use simplified chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text("Revenue vs Profit (Last 10 Periods)", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200, 
                        child: _buildBarChart(periods)
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text("Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Top Periods List
              _buildListSection("Top Periods", top5, (p) => "Profit: ₹${formatCurrency(p.netProfit)}M", true),
              
              const SizedBox(height: 16),

              // Recent Activity
              _buildListSection("Recent Activity", recent5, (p) => p.isFinalized ? "Finalized" : "Draft", false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 18,
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                 Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(String title, List<DashboardPeriodData> items, String Function(DashboardPeriodData) trailingBuilder, bool rank) {
    return Card(
      child: Column(
        children: [
          ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          const Divider(height: 1),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text("No data available")),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              leading: rank 
                ? CircleAvatar(radius: 14, backgroundColor: Colors.grey.shade200, child: Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Colors.black)))
                : CircleAvatar(radius: 14, backgroundColor: item.isFinalized ? Colors.green.shade100 : Colors.blue.shade100, child: Icon(item.isFinalized ? Icons.check : Icons.edit, size: 14, color: item.isFinalized ? Colors.green : Colors.blue)),
              title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(item.periodType),
              trailing: Text(trailingBuilder(item), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onTap: () {
                // Navigate to detail?
                // Navigator.pushNamed(context, '/financial-statements/${item.id}');
              },
            );
          }).toList()
        ],
      ),
    );
  }

  Widget _buildBarChart(List<DashboardPeriodData> allPeriods) {
     // Sort by date asc, take last 10
     final data = List<DashboardPeriodData>.from(allPeriods)
      ..sort((a,b) => a.startDate.compareTo(b.startDate)); // simple string compare for ISO dates
     final chartData = data.reversed.take(10).toList().reversed.toList();

     if (chartData.isEmpty) return const Center(child: Text("No data for chart"));

     // Find max Y for scaling
     double maxY = 0;
     for(var p in chartData) {
       if(p.revenue > maxY) maxY = p.revenue;
     }

     return BarChart(
       BarChartData(
         barGroups: chartData.asMap().entries.map((e) {
           return BarChartGroupData(
             x: e.key,
             barRods: [
               BarChartRodData(toY: e.value.revenue, color: Colors.blue, width: 8),
               BarChartRodData(toY: e.value.netProfit, color: Colors.green, width: 8),
             ]
           );
         }).toList(),
         titlesData: FlTitlesData(
           bottomTitles: AxisTitles(
             sideTitles: SideTitles(
               showTitles: true,
               getTitlesWidget: (val, meta) {
                 int idx = val.toInt();
                 if (idx >= 0 && idx < chartData.length) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 4.0),
                     child: Text(chartData[idx].label.split(' ').first, style: const TextStyle(fontSize: 9)),
                   );
                 }
                 return const Text('');
               }
             )
           ),
           leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
         ),
         borderData: FlBorderData(show: false),
         gridData: const FlGridData(show: false),
       )
     );
  }
}
