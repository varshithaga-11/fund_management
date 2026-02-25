import 'package:flutter/material.dart';
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
  String openSection = 'trading';

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
    for (var k in ['opening_stock', 'purchases', 'trade_charges', 'sales', 'closing_stock']) {
      ta[k] = TextEditingController();
    }
    for (var k in [
      'interest_on_loans', 'interest_on_bank_ac', 'return_on_investment',
      'miscellaneous_income', 'interest_on_deposits', 'interest_on_borrowings',
      'establishment_contingencies', 'provisions', 'net_profit',
    ]) {
      pl[k] = TextEditingController();
    }
    for (var k in [
      'share_capital', 'deposits', 'borrowings', 'reserves_statutory_free',
      'undistributed_profit', 'provisions', 'other_liabilities',
      'cash_in_hand', 'cash_at_bank', 'investments', 'loans_advances',
      'fixed_assets', 'other_assets', 'stock_in_trade',
    ]) {
      bs[k] = TextEditingController();
    }
    loadAll();
  }

  @override
  void didUpdateWidget(covariant PeriodDataEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.periodId != oldWidget.periodId) loadAll();
  }

  @override
  void dispose() {
    for (var c in [...ta.values, ...pl.values, ...bs.values]) {
      c.dispose();
    }
    staffCount.dispose();
    super.dispose();
  }

  void _clear(Map<String, TextEditingController> map) {
    for (var c in map.values) c.clear();
  }

  double _val(Map<String, TextEditingController> map, String key) =>
      double.tryParse(map[key]?.text ?? '') ?? 0.0;

  double totalLiabilities() =>
      _val(bs, 'share_capital') + _val(bs, 'deposits') + _val(bs, 'borrowings') +
      _val(bs, 'reserves_statutory_free') + _val(bs, 'undistributed_profit') +
      _val(bs, 'provisions') + _val(bs, 'other_liabilities');

  double totalAssets() =>
      _val(bs, 'cash_in_hand') + _val(bs, 'cash_at_bank') + _val(bs, 'investments') +
      _val(bs, 'loans_advances') + _val(bs, 'fixed_assets') + _val(bs, 'other_assets') +
      _val(bs, 'stock_in_trade');

  Future<void> loadAll() async {
    setState(() => loadingData = true);
    try {
      final taData = await getTradingAccount(widget.periodId);
      final plData = await getProfitLoss(widget.periodId);
      final bsData = await getBalanceSheet(widget.periodId);
      final omData = await getOperationalMetrics(widget.periodId);

      if (taData != null) {
        taId = taData.id;
        ta['opening_stock']!.text = taData.openingStock.toString();
        ta['purchases']!.text = taData.purchases.toString();
        ta['trade_charges']!.text = taData.tradeCharges.toString();
        ta['sales']!.text = taData.sales.toString();
        ta['closing_stock']!.text = taData.closingStock.toString();
      } else {
        taId = null;
        _clear(ta);
      }

      if (plData != null) {
        plId = plData.id;
        pl['interest_on_loans']!.text = plData.interestOnLoans.toString();
        pl['interest_on_bank_ac']!.text = plData.interestOnBankAc.toString();
        pl['return_on_investment']!.text = plData.returnOnInvestment.toString();
        pl['miscellaneous_income']!.text = plData.miscellaneousIncome.toString();
        pl['interest_on_deposits']!.text = plData.interestOnDeposits.toString();
        pl['interest_on_borrowings']!.text = plData.interestOnBorrowings.toString();
        pl['establishment_contingencies']!.text = plData.establishmentContingencies.toString();
        pl['provisions']!.text = plData.provisions.toString();
        pl['net_profit']!.text = plData.netProfit.toString();
      } else {
        plId = null;
        _clear(pl);
      }

      if (bsData != null) {
        bsId = bsData.id;
        bs['share_capital']!.text = bsData.shareCapital.toString();
        bs['deposits']!.text = bsData.deposits.toString();
        bs['borrowings']!.text = bsData.borrowings.toString();
        bs['reserves_statutory_free']!.text = bsData.reservesStatutoryFree.toString();
        bs['undistributed_profit']!.text = bsData.undistributedProfit.toString();
        bs['provisions']!.text = bsData.provisions.toString();
        bs['other_liabilities']!.text = bsData.otherLiabilities.toString();
        bs['cash_in_hand']!.text = bsData.cashInHand.toString();
        bs['cash_at_bank']!.text = bsData.cashAtBank.toString();
        bs['investments']!.text = bsData.investments.toString();
        bs['loans_advances']!.text = bsData.loansAdvances.toString();
        bs['fixed_assets']!.text = bsData.fixedAssets.toString();
        bs['other_assets']!.text = bsData.otherAssets.toString();
        bs['stock_in_trade']!.text = bsData.stockInTrade.toString();
      } else {
        bsId = null;
        _clear(bs);
      }

      if (omData != null) {
        omId = omData.id;
        staffCount.text = omData.staffCount.toString();
      } else {
        omId = null;
        staffCount.text = '1';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loadingData = false);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => loading = true);
    try {
      final taPayload = {
        'opening_stock': _val(ta, 'opening_stock'),
        'purchases': _val(ta, 'purchases'),
        'trade_charges': _val(ta, 'trade_charges'),
        'sales': _val(ta, 'sales'),
        'closing_stock': _val(ta, 'closing_stock'),
      };
      if (taId != null) await updateTradingAccount(taId!, taPayload);
      else await createTradingAccount(widget.periodId, taPayload);

      final plPayload = {
        'interest_on_loans': _val(pl, 'interest_on_loans'),
        'interest_on_bank_ac': _val(pl, 'interest_on_bank_ac'),
        'return_on_investment': _val(pl, 'return_on_investment'),
        'miscellaneous_income': _val(pl, 'miscellaneous_income'),
        'interest_on_deposits': _val(pl, 'interest_on_deposits'),
        'interest_on_borrowings': _val(pl, 'interest_on_borrowings'),
        'establishment_contingencies': _val(pl, 'establishment_contingencies'),
        'provisions': _val(pl, 'provisions'),
        'net_profit': _val(pl, 'net_profit'),
      };
      if (plId != null) await updateProfitLoss(plId!, plPayload);
      else await createProfitLoss(widget.periodId, plPayload);

      final bsPayload = {
        'share_capital': _val(bs, 'share_capital'),
        'deposits': _val(bs, 'deposits'),
        'borrowings': _val(bs, 'borrowings'),
        'reserves_statutory_free': _val(bs, 'reserves_statutory_free'),
        'undistributed_profit': _val(bs, 'undistributed_profit'),
        'provisions': _val(bs, 'provisions'),
        'other_liabilities': _val(bs, 'other_liabilities'),
        'cash_in_hand': _val(bs, 'cash_in_hand'),
        'cash_at_bank': _val(bs, 'cash_at_bank'),
        'investments': _val(bs, 'investments'),
        'loans_advances': _val(bs, 'loans_advances'),
        'fixed_assets': _val(bs, 'fixed_assets'),
        'other_assets': _val(bs, 'other_assets'),
        'stock_in_trade': _val(bs, 'stock_in_trade'),
      };
      if (bsId != null) await updateBalanceSheet(bsId!, bsPayload);
      else await createBalanceSheet(widget.periodId, bsPayload);

      final omPayload = {'staff_count': int.tryParse(staffCount.text) ?? 1};
      if (omId != null) await updateOperationalMetrics(omId!, omPayload);
      else await createOperationalMetrics(widget.periodId, omPayload);

      await calculateRatios(widget.periodId);
      widget.onSuccess?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Updated successfully'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tl = totalLiabilities();
    final ta_ = totalAssets();
    final diff = (tl - ta_).abs();
    final isBalanced = diff < 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Trading Account ──────────────────────────────────────────────
        _Section(
          id: 'trading',
          title: 'Trading Account',
          openSection: openSection,
          isDark: isDark,
          onToggle: (id) => setState(() => openSection = id == openSection ? '' : id),
          content: _Grid(
            isDark: isDark,
            fields: ta.entries
                .map((e) => _Field(ctrl: e.value, label: _label(e.key), isDark: isDark))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // ── Profit & Loss ────────────────────────────────────────────────
        _Section(
          id: 'profitloss',
          title: 'Profit & Loss',
          openSection: openSection,
          isDark: isDark,
          onToggle: (id) => setState(() => openSection = id == openSection ? '' : id),
          content: _Grid(
            isDark: isDark,
            fields: pl.entries
                .map((e) => _Field(ctrl: e.value, label: _label(e.key), isDark: isDark))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // ── Balance Sheet ────────────────────────────────────────────────
        _Section(
          id: 'balancesheet',
          title: 'Balance Sheet',
          openSection: openSection,
          isDark: isDark,
          onToggle: (id) => setState(() => openSection = id == openSection ? '' : id),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _subHeading('Liabilities', Colors.blue, isDark),
              const SizedBox(height: 12),
              _Grid(
                isDark: isDark,
                fields: [
                  'share_capital', 'deposits', 'borrowings',
                  'reserves_statutory_free', 'undistributed_profit',
                  'provisions', 'other_liabilities',
                ].map((k) => _Field(ctrl: bs[k]!, label: _label(k), isDark: isDark)).toList(),
              ),
              Divider(
                height: 40,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              ),
              _subHeading('Assets', Colors.green, isDark),
              const SizedBox(height: 12),
              _Grid(
                isDark: isDark,
                fields: [
                  'cash_in_hand', 'cash_at_bank', 'investments',
                  'loans_advances', 'fixed_assets', 'other_assets', 'stock_in_trade',
                ].map((k) => _Field(ctrl: bs[k]!, label: _label(k), isDark: isDark)).toList(),
              ),
              const SizedBox(height: 16),
              // Balance indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isBalanced
                      ? Colors.green.withOpacity(0.08)
                      : Colors.red.withOpacity(0.08),
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
                      isBalanced ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      color: isBalanced ? Colors.green.shade600 : Colors.red.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isBalanced
                            ? 'Balance sheet is balanced (Liabilities = Assets)'
                            : 'Balance sheet is unbalanced — '
                              'Liabilities: ${tl.toStringAsFixed(2)}, '
                              'Assets: ${ta_.toStringAsFixed(2)} '
                              '(Δ ${diff.toStringAsFixed(2)})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isBalanced
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Operational Metrics ──────────────────────────────────────────
        _Section(
          id: 'operational',
          title: 'Operational Metrics',
          openSection: openSection,
          isDark: isDark,
          onToggle: (id) => setState(() => openSection = id == openSection ? '' : id),
          content: _Grid(
            isDark: isDark,
            fields: [_Field(ctrl: staffCount, label: 'Staff count', isDark: isDark)],
          ),
        ),

        const SizedBox(height: 20),

        // ── Submit button (right-aligned, matching React) ─────────────────
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: loading ? null : _handleSubmit,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              loading ? 'Updating...' : 'Update data & recalculate ratios',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  /// "opening_stock" → "opening stock"
  String _label(String key) => key.replaceAll('_', ' ');

  Widget _subHeading(String text, MaterialColor color, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? color.shade300 : color.shade700,
      ),
    );
  }
}

// ─── Section accordion ───────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String id;
  final String title;
  final String openSection;
  final bool isDark;
  final void Function(String) onToggle;
  final Widget content;

  const _Section({
    required this.id,
    required this.title,
    required this.openSection,
    required this.isDark,
    required this.onToggle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = openSection == id;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          InkWell(
            onTap: () => onToggle(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: isOpen
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 22,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (isOpen)
            Padding(
              padding: const EdgeInsets.all(20),
              child: content,
            ),
        ],
      ),
    );
  }
}

// ─── Responsive 2-column grid ────────────────────────────────────────────────

class _Grid extends StatelessWidget {
  final List<Widget> fields;
  final bool isDark;

  const _Grid({required this.fields, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwo = constraints.maxWidth > 560;
        if (!useTwo) {
          return Column(
            children: fields
                .map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: f,
                    ))
                .toList(),
          );
        }
        final rows = <Widget>[];
        for (int i = 0; i < fields.length; i += 2) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fields[i]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: i + 1 < fields.length
                        ? fields[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

// ─── Single labeled input field ──────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool isDark;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Capitalize first letter only
    final displayLabel =
        label.isEmpty ? '' : label[0].toUpperCase() + label.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF475569) : const Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFF4F46E5),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
