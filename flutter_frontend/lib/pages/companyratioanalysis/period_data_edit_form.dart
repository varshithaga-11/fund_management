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
      return const Center(child: CircularProgressIndicator());
    }

    double tl = totalLiabilities();
    double taVal = totalAssets();
    double diff = (tl - taVal).abs();
    bool isBalanced = diff < 0.01;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSection("trading", "Trading Account", ta.keys.map((k) => 
            _buildInput(ta[k]!, k.replaceAll("_", " "))).toList()),
          
          _buildSection("profitloss", "Profit & Loss", pl.keys.map((k) => 
            _buildInput(pl[k]!, k.replaceAll("_", " "))).toList()),
            
          _buildSection("balancesheet", "Balance Sheet", [
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Liabilities", style: TextStyle(fontWeight: FontWeight.bold))),
            ...["share_capital", "deposits", "borrowings", "reserves_statutory_free", "undistributed_profit", "provisions", "other_liabilities"]
               .map((k) => _buildInput(bs[k]!, k.replaceAll("_", " "))),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Assets", style: TextStyle(fontWeight: FontWeight.bold))),
             ...["cash_in_hand", "cash_at_bank", "investments", "loans_advances", "fixed_assets", "other_assets", "stock_in_trade"]
               .map((k) => _buildInput(bs[k]!, k.replaceAll("_", " "))),

             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Text(
                 isBalanced ? "Liabilities = Assets" : "Diff: ${diff.toStringAsFixed(2)}",
                 style: TextStyle(color: isBalanced ? Colors.green : Colors.red),
               ),
             )
          ]),

          _buildSection("operational", "Operational Metrics", [
            _buildInput(staffCount, "Staff Count")
          ]),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : _handleSubmit,
                icon: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.refresh),
                label: const Text("Update & Recalculate"),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection(String id, String title, List<Widget> children) {
    bool isOpen = openSection == id;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onTap: () {
              setState(() {
                openSection = isOpen ? "" : id;
              });
            },
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            )
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputField(
        controller: controller,
        hintText: label,
        helperText: label, // Using helper text as label since InputField design varies
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}
