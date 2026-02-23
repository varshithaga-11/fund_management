import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'financial_statements_api.dart';

class StatementColumnsConfigPage extends StatefulWidget {
  const StatementColumnsConfigPage({super.key});

  @override
  State<StatementColumnsConfigPage> createState() => _StatementColumnsConfigPageState();
}

class _StatementColumnsConfigPageState extends State<StatementColumnsConfigPage> {
  String _statementType = 'TRADING';
  List<StatementColumnConfig> _rows = [];
  bool _loading = false;
  bool _saving = false;
  bool _canUpdate = true;
  static const String _prefKey = 'selected_statement_type';

  final Map<String, String> _statementTypeOptions = {
    'TRADING': 'Trading Account',
    'PL': 'Profit & Loss',
    'BALANCE_SHEET': 'Balance Sheet',
    'OPERATIONAL': 'Operational',
  };

  final Map<String, List<String>> _canonicalFieldsByStatement = {
    'TRADING': ["opening_stock", "purchases", "trade_charges", "sales", "closing_stock"],
    'PL': [
      "interest_on_loans", "interest_on_bank_ac", "return_on_investment", "miscellaneous_income",
      "interest_on_deposits", "interest_on_borrowings", "establishment_contingencies", "provisions", "net_profit"
    ],
    'BALANCE_SHEET': [
      "share_capital", "deposits", "borrowings", "reserves_statutory_free", "undistributed_profit",
      "provisions", "other_liabilities", "cash_in_hand", "cash_at_bank", "investments",
      "loans_advances", "fixed_assets", "other_assets", "stock_in_trade"
    ],
    'OPERATIONAL': ["staff_count"],
  };

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString(_prefKey);
    if (savedType != null && _statementTypeOptions.containsKey(savedType)) {
      if (mounted) {
        setState(() {
          _statementType = savedType;
        });
      }
    }
    await _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _loading = true);
    try {
      final data = await getStatementColumns(_statementType);
      // Sort rows by canonical field to match React behavior
      data.sort((a, b) => a.canonicalField.compareTo(b.canonicalField));
      setState(() {
        _rows = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load column config: $e')),
        );
      }
    }
  }

  void _handleFieldChange(int id, String field, dynamic value) {
    setState(() {
      final index = _rows.indexWhere((row) => row.id == id);
      if (index != -1) {
        final row = _rows[index];
        List<String> newAliases = row.aliases;
        
        if (field == 'aliases') {
           newAliases = (value as String)
              .split(',')
              .map((e) => e.trim().replaceAll(RegExp(r'\s+'), '_'))
              .where((e) => e.isNotEmpty)
              .toList();
        }

        _rows[index] = StatementColumnConfig(
          id: row.id,
          statementType: row.statementType,
          canonicalField: row.canonicalField,
          displayName: field == 'display_name' ? value : row.displayName,
          aliases: field == 'aliases' ? newAliases : row.aliases,
          isRequired: field == 'is_required' ? value : row.isRequired,
        );
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_canUpdate) return;
    setState(() => _saving = true);
    try {
      // Iterate and update all - simple bulk save strategy as in React
      for (final row in _rows) {
        final data = {
          'display_name': row.displayName,
          'aliases': row.aliases,
          'is_required': row.isRequired,
        };
        await updateStatementColumn(row.id, data);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Column configuration updated.'), backgroundColor: Colors.green),
        );
      }
      await _loadConfigs();
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update configuration: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleAddConfig() async {
    showDialog(
      context: context,
      builder: (context) => _ConfigDialog(
        statementType: _statementType,
        existingFields: _rows.map((r) => r.canonicalField).toSet(),
        allCanonicalFields: _canonicalFieldsByStatement[_statementType] ?? [],
        onSave: (data) async {
          try {
            await createStatementColumn(data);
            if (mounted) Navigator.pop(context);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuration added.'), backgroundColor: Colors.green),
              );
            }
            await _loadConfigs();
          } catch (e) {
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _handleEditConfig(StatementColumnConfig row) async {
    showDialog(
      context: context,
      builder: (context) => _ConfigDialog(
        statementType: _statementType,
        existingFields: _rows.map((r) => r.canonicalField).toSet(),
        allCanonicalFields: _canonicalFieldsByStatement[_statementType] ?? [],
        initialData: row,
        onSave: (data) async {
          try {
             // For edit, we might only send partial updates, but currently API expects full object or partial
             // similar to what we do in bulk update but for single item
             final updateData = {
                'display_name': data['display_name'],
                'aliases': data['aliases'],
                'is_required': data['is_required'],
             };
            await updateStatementColumn(row.id, updateData);
            if (mounted) Navigator.pop(context);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuration updated.'), backgroundColor: Colors.green),
              );
            }
            await _loadConfigs();
          } catch (e) {
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableFieldsCount = (_canonicalFieldsByStatement[_statementType] ?? [])
        .where((f) => !_rows.any((r) => r.canonicalField == f))
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statement Column Mapping',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose a statement type to manage display names and ordering of financial statement fields.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.2),
                        ),
                      ],
                    ),
                  ),
                  if (_canUpdate)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: (_loading || availableFieldsCount == 0) ? null : _handleAddConfig,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            side: BorderSide(color: Colors.grey.shade200),
                            foregroundColor: Colors.grey.shade600,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Add configuration', style: TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: (_saving || _rows.isEmpty) ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _saving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Statement Type Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Statement Type', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 450,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statementType,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
                          items: _statementTypeOptions.entries.map((e) {
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() => _statementType = value);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString(_prefKey, value);
                              await _loadConfigs();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),

              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(64), child: CircularProgressIndicator()))
              else if (_rows.isEmpty)
                Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Text('No configuration for this statement type yet.', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        if (_canUpdate)
                          ElevatedButton(
                            onPressed: availableFieldsCount == 0 ? null : _handleAddConfig,
                            child: const Text('Add configuration'),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      horizontalMargin: 0,
                      columnSpacing: 60,
                      dataRowMinHeight: 100,
                      dataRowMaxHeight: 110,
                      columns: [
                        const DataColumn(label: Text('Canonical Field (Model)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)))),
                        const DataColumn(label: Text('Display Name (UI / PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)))),
                        const DataColumn(label: Text('Alternative Names / Aliases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)))),
                        const DataColumn(label: Text('Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)))),
                        if (_canUpdate) const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)))),
                      ],
                      rows: _rows.map((row) {
                        return DataRow(
                          key: ValueKey('row_${row.id}'),
                          cells: [
                            DataCell(Text(row.canonicalField, style: const TextStyle(fontSize: 14, color: Color(0xFF334155)))),
                            DataCell(
                              SizedBox(
                                width: 320,
                                child: TextFormField(
                                  key: ValueKey('dn_${_statementType}_${row.id}'),
                                  initialValue: row.displayName,
                                  enabled: _canUpdate,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                                  ),
                                  onChanged: (val) => _handleFieldChange(row.id, 'display_name', val),
                                ),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 420,
                                    child: TextFormField(
                                      key: ValueKey('al_${_statementType}_${row.id}'),
                                      initialValue: row.aliases.join(", "),
                                      enabled: _canUpdate,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                                      ),
                                      onChanged: (val) => _handleFieldChange(row.id, 'aliases', val),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Comma-separated names to match during upload',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  )
                                ],
                              ),
                            ),
                            DataCell(
                              Checkbox(
                                value: row.isRequired,
                                activeColor: const Color(0xFF4F46E5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: _canUpdate ? (val) => _handleFieldChange(row.id, 'is_required', val) : null,
                              ),
                            ),
                            if (_canUpdate)
                              DataCell(
                                OutlinedButton(
                                  onPressed: () => _handleEditConfig(row),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    foregroundColor: const Color(0xFF1E293B),
                                  ),
                                  child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigDialog extends StatefulWidget {
  final String statementType;
  final Set<String> existingFields;
  final List<String> allCanonicalFields;
  final StatementColumnConfig? initialData;
  final Function(Map<String, dynamic>) onSave;

  const _ConfigDialog({
    required this.statementType,
    required this.existingFields,
    required this.allCanonicalFields,
    this.initialData,
    required this.onSave,
  });

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _aliasesController;
  late String _canonicalField;
  bool _isRequired = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.initialData?.displayName ?? '');
    _aliasesController = TextEditingController(text: widget.initialData?.aliases.join(", ") ?? '');
    _canonicalField = widget.initialData?.canonicalField ?? '';
    _isRequired = widget.initialData?.isRequired ?? true;
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    _aliasesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter available fields
    final availableFields = widget.allCanonicalFields
        .where((f) => !widget.existingFields.contains(f) || f == widget.initialData?.canonicalField)
        .toList();

    return AlertDialog(
      title: Text(widget.initialData == null ? 'Add Configuration' : 'Edit Configuration'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: SingleChildScrollView(
        child: Container(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.initialData == null) ...[
                   if (availableFields.isEmpty)
                      const Text('All fields for this statement type are already configured.', style: TextStyle(color: Colors.grey)),
                   if (availableFields.isNotEmpty) ...[
                      const Text('Canonical Field', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _canonicalField.isNotEmpty ? _canonicalField : null,
                        decoration: InputDecoration(
                           hintText: 'Select field',
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: availableFields.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _canonicalField = value;
                              if (_displayNameController.text.isEmpty) {
                                _displayNameController.text = value.replaceAll('_', ' '); // Auto-fill display name
                              }
                            });
                          }
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                   ]
                ] else ...[
                   const Text('Canonical Field', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                   const SizedBox(height: 8),
                   TextFormField(
                     initialValue: _canonicalField,
                     enabled: false,
                     decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        fillColor: Colors.grey.shade100,
                        filled: true,
                     ),
                   ),
                ],

                const SizedBox(height: 16),
                
                const Text('Display Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                     hintText: 'e.g. Opening Stock',
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 16),
                
                const Text('Alternative Names (comma-separated)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _aliasesController,
                  decoration: InputDecoration(
                     hintText: 'e.g. beginning_stock, opening_inventory',
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Checkbox(
                      value: _isRequired,
                      onChanged: (val) => setState(() => _isRequired = val ?? false),
                    ),
                    const Text('Required')
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel')
        ),
        ElevatedButton(
          onPressed: _loading || (widget.initialData == null && availableFields.isEmpty) ? null : () async {
            if (_formKey.currentState!.validate()) {
              if (widget.initialData == null && _canonicalField.isEmpty) return;
              
              setState(() => _loading = true);
              final aliases = _aliasesController.text
                  .split(',')
                  .map((e) => e.trim().replaceAll(RegExp(r'\s+'), '_'))
                  .where((e) => e.isNotEmpty)
                  .toList();
                  
              final data = {
                if (widget.initialData == null) 'statement_type': widget.statementType,
                if (widget.initialData == null) 'canonical_field': _canonicalField,
                'display_name': _displayNameController.text.trim(),
                'aliases': aliases,
                'is_required': _isRequired,
              };
              
              await widget.onSave(data);
              if (mounted) setState(() => _loading = false);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
          child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
        ),
      ],
    );
  }
}
