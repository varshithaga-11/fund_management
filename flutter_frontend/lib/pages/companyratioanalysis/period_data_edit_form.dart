import 'package:flutter/material.dart';
import '../../components/form/input/inputfield.dart';
import 'financial_statements_api.dart';

class PeriodDataEditForm extends StatefulWidget {
  final int periodId;
  final VoidCallback? onSuccess;

  const PeriodDataEditForm({
    super.key,
    required this.periodId,
    this.onSuccess,
  });

  @override
  State<PeriodDataEditForm> createState() => _PeriodDataEditFormState();
}

class _PeriodDataEditFormState extends State<PeriodDataEditForm> {
  bool loading = false;
  bool loadingData = true;
  String openSection = "trading";

  // State maps
  final Map<String, TextEditingController> ta = {};
  int? taId;

  final Map<String, TextEditingController> pl = {};
  int? plId;

  final Map<String, TextEditingController> bs = {};
  int? bsId;

  final TextEditingController staffCount = TextEditingController();
  int? omId;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    for (var key in ["opening_stock", "purchases", "trade_charges", "sales", "closing_stock"]) {
      ta[key] = TextEditingController();
    }
    for (var key in [
      "interest_on_loans", "interest_on_bank_ac", "return_on_investment",
      "miscellaneous_income", "interest_on_deposits", "interest_on_borrowings",
      "establishment_contingencies", "provisions", "net_profit"
    ]) {
      pl[key] = TextEditingController();
    }
    for (var key in [
      "share_capital", "deposits", "borrowings", "reserves_statutory_free",
      "undistributed_profit", "provisions", "other_liabilities",
      "cash_in_hand", "cash_at_bank", "investments", "loans_advances",
      "fixed_assets", "other_assets", "stock_in_trade"
    ]) {
      bs[key] = TextEditingController();
    }

    loadAll();
  }

  @override
  void didUpdateWidget(covariant PeriodDataEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.periodId != oldWidget.periodId) {
      loadAll();
    }
  }

  @override
  void dispose() {
    for (var c in ta.values) { c.dispose(); }
    for (var c in pl.values) { c.dispose(); }
    for (var c in bs.values) { c.dispose(); }
    staffCount.dispose();
    super.dispose();
  }

  Future<void> loadAll() async {
    setState(() => loadingData = true);
    try {
      final taData = await getTradingAccount(widget.periodId);
      final plData = await getProfitLoss(widget.periodId);
      final bsData = await getBalanceSheet(widget.periodId);
      final omData = await getOperationalMetrics(widget.periodId);

      if (taData != null) {
        taId = taData.id;
        ta["opening_stock"]?.text = taData.openingStock.toString();
        ta["purchases"]?.text = taData.purchases.toString();
        ta["trade_charges"]?.text = taData.tradeCharges.toString();
        ta["sales"]?.text = taData.sales.toString();
        ta["closing_stock"]?.text = taData.closingStock.toString();
      } else { taId = null; _clear(ta); }

      if (plData != null) {
        plId = plData.id;
        pl["interest_on_loans"]?.text = plData.interestOnLoans.toString();
        pl["interest_on_bank_ac"]?.text = plData.interestOnBankAc.toString();
        pl["return_on_investment"]?.text = plData.returnOnInvestment.toString();
        pl["miscellaneous_income"]?.text = plData.miscellaneousIncome.toString();
        pl["interest_on_deposits"]?.text = plData.interestOnDeposits.toString();
        pl["interest_on_borrowings"]?.text = plData.interestOnBorrowings.toString();
        pl["establishment_contingencies"]?.text = plData.establishmentContingencies.toString();
        pl["provisions"]?.text = plData.provisions.toString();
        pl["net_profit"]?.text = plData.netProfit.toString();
      } else { plId = null; _clear(pl); }

      if (bsData != null) {
        bsId = bsData.id;
        bs["share_capital"]?.text = bsData.shareCapital.toString();
        bs["deposits"]?.text = bsData.deposits.toString();
        bs["borrowings"]?.text = bsData.borrowings.toString();
        bs["reserves_statutory_free"]?.text = bsData.reservesStatutoryFree.toString();
        bs["undistributed_profit"]?.text = bsData.undistributedProfit.toString();
        bs["provisions"]?.text = bsData.provisions.toString();
        bs["other_liabilities"]?.text = bsData.otherLiabilities.toString();
        bs["cash_in_hand"]?.text = bsData.cashInHand.toString();
        bs["cash_at_bank"]?.text = bsData.cashAtBank.toString();
        bs["investments"]?.text = bsData.investments.toString();
        bs["loans_advances"]?.text = bsData.loansAdvances.toString();
        bs["fixed_assets"]?.text = bsData.fixedAssets.toString();
        bs["other_assets"]?.text = bsData.otherAssets.toString();
        bs["stock_in_trade"]?.text = bsData.stockInTrade.toString();
      } else { bsId = null; _clear(bs); }

      if (omData != null) {
        omId = omData.id;
        staffCount.text = omData.staffCount.toString();
      } else {
        omId = null;
        staffCount.text = "1";
      }

    } catch (e) {
      debugPrint("Error loading period data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      if (mounted) setState(() => loadingData = false);
    }
  }

  void _clear(Map<String, TextEditingController> map) {
    for (var c in map.values) { c.clear(); }
  }

  // Calculated Fields
  double _val(Map<String, TextEditingController> map, String key) {
    return double.tryParse(map[key]?.text ?? "") ?? 0.0;
  }

  double totalLiabilities() {
    return _val(bs, "share_capital") + _val(bs, "deposits") + _val(bs, "borrowings") +
           _val(bs, "reserves_statutory_free") + _val(bs, "undistributed_profit") +
           _val(bs, "provisions") + _val(bs, "other_liabilities");
  }

  double totalAssets() {
    return _val(bs, "cash_in_hand") + _val(bs, "cash_at_bank") + _val(bs, "investments") +
           _val(bs, "loans_advances") + _val(bs, "fixed_assets") + _val(bs, "other_assets") +
           _val(bs, "stock_in_trade");
  }

  Future<void> _handleSubmit() async {
    setState(() => loading = true);
    try {
      // 1. Trading Account
      final taPayload = {
        "opening_stock": _val(ta, "opening_stock"),
        "purchases": _val(ta, "purchases"),
        "trade_charges": _val(ta, "trade_charges"),
        "sales": _val(ta, "sales"),
        "closing_stock": _val(ta, "closing_stock"),
      };
      if (taId != null) await updateTradingAccount(taId!, taPayload);
      else await createTradingAccount(widget.periodId, taPayload);

      // 2. Profit & Loss
      final plPayload = {
        "interest_on_loans": _val(pl, "interest_on_loans"),
        "interest_on_bank_ac": _val(pl, "interest_on_bank_ac"),
        "return_on_investment": _val(pl, "return_on_investment"),
        "miscellaneous_income": _val(pl, "miscellaneous_income"),
        "interest_on_deposits": _val(pl, "interest_on_deposits"),
        "interest_on_borrowings": _val(pl, "interest_on_borrowings"),
        "establishment_contingencies": _val(pl, "establishment_contingencies"),
        "provisions": _val(pl, "provisions"),
        "net_profit": _val(pl, "net_profit"),
      };
      if (plId != null) await updateProfitLoss(plId!, plPayload);
      else await createProfitLoss(widget.periodId, plPayload);

      // 3. Balance Sheet
      final bsPayload = {
        "share_capital": _val(bs, "share_capital"),
        "deposits": _val(bs, "deposits"),
        "borrowings": _val(bs, "borrowings"),
        "reserves_statutory_free": _val(bs, "reserves_statutory_free"),
        "undistributed_profit": _val(bs, "undistributed_profit"),
        "provisions": _val(bs, "provisions"),
        "other_liabilities": _val(bs, "other_liabilities"),
        "cash_in_hand": _val(bs, "cash_in_hand"),
        "cash_at_bank": _val(bs, "cash_at_bank"),
        "investments": _val(bs, "investments"),
        "loans_advances": _val(bs, "loans_advances"),
        "fixed_assets": _val(bs, "fixed_assets"),
        "other_assets": _val(bs, "other_assets"),
        "stock_in_trade": _val(bs, "stock_in_trade"),
      };
      if (bsId != null) await updateBalanceSheet(bsId!, bsPayload);
      else await createBalanceSheet(widget.periodId, bsPayload);

      // 4. Operational Metrics
      final omPayload = {"staff_count": int.tryParse(staffCount.text) ?? 1};
      if (omId != null) await updateOperationalMetrics(omId!, omPayload);
      else await createOperationalMetrics(widget.periodId, omPayload);

      // 5. Calculate
      await calculateRatios(widget.periodId);

      widget.onSuccess?.call();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully')));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    double tl = totalLiabilities();
    double taVal = totalAssets();
    double diff = (tl - taVal).abs();
    bool isBalanced = diff < 0.01;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSection(
            "trading",
            "Trading Account",
            _buildFieldGrid(
              context,
              ta.keys.map((k) => _buildInput(ta[k]!, k.replaceAll("_", " "))).toList(),
            ),
          ),
          
          _buildSection(
            "profitloss",
            "Profit & Loss",
            _buildFieldGrid(
              context,
              pl.keys.map((k) => _buildInput(pl[k]!, k.replaceAll("_", " "))).toList(),
            ),
          ),
            
          _buildSection(
            "balancesheet",
            "Balance Sheet",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LIABILITIES",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue.shade400 : Colors.blue.shade700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldGrid(
                  context,
                  [
                    "share_capital", "deposits", "borrowings", "reserves_statutory_free",
                    "undistributed_profit", "provisions", "other_liabilities"
                  ].map((k) => _buildInput(bs[k]!, k.replaceAll("_", " "))).toList(),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(),
                ),

                Text(
                  "ASSETS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldGrid(
                  context,
                  [
                    "cash_in_hand", "cash_at_bank", "investments", "loans_advances",
                    "fixed_assets", "other_assets", "stock_in_trade"
                  ].map((k) => _buildInput(bs[k]!, k.replaceAll("_", " "))).toList(),
                ),

                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isBalanced 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isBalanced 
                          ? Colors.green.withOpacity(0.3) 
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isBalanced ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: isBalanced ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isBalanced 
                              ? "Liabilities = Assets" 
                              : "Assets not equal to Liabilities. Liabilities ${tl.toStringAsFixed(2)} vs Assets ${taVal.toStringAsFixed(2)} (Δ ${diff.toStringAsFixed(2)})",
                          style: TextStyle(
                            color: isBalanced ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildSection(
            "operational",
            "Operational Metrics",
            _buildFieldGrid(
              context,
              [_buildInput(staffCount, "Staff Count")],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: loading ? null : _handleSubmit,
                icon: loading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  loading ? "Updating..." : "Update data & recalculate ratios",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Indigo
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection(String id, String title, Widget content) {
    bool isOpen = openSection == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => openSection = isOpen ? "" : id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: isOpen 
                  ? (isDark ? Colors.grey.shade800 : Colors.grey.shade50)
                  : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildFieldGrid(BuildContext context, List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 2 : 1;
        final spacing = 16.0;
        
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((w) {
            return SizedBox(
              width: crossAxisCount == 2 
                  ? (constraints.maxWidth - spacing) / 2 
                  : constraints.maxWidth,
              child: w,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.replaceAll("_", " ").toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        InputField(
          controller: controller,
          hintText: "0.00",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}
