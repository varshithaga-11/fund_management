import 'package:flutter/material.dart';
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
  bool _canUpdate = false; // TODO: Check user role from storage

  final Map<String, String> _statementTypeOptions = {
    'TRADING': 'Trading Account',
    'PL': 'Profit & Loss',
    'BALANCE_SHEET': 'Balance Sheet',
    'OPERATIONAL': 'Operational',
  };

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadConfigs();
  }

  Future<void> _checkUserRole() async {
    // Mock user role check - in real app use SharedPreferences or AuthProvider
    // final userRole = await SharedPreferences.getInstance().then((prefs) => prefs.getString('userRole'));
    // setState(() => _canUpdate = userRole == 'master');
    setState(() => _canUpdate = true); // Defaulting to true for development
  }

  Future<void> _loadConfigs() async {
    setState(() => _loading = true);
    try {
      final data = await getStatementColumns(_statementType);
      setState(() {
        _rows = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load column config: $e')),
      );
    }
  }

  Future<void> _handleAddConfig() async {
    // Show dialog to add config
     await showDialog(
      context: context,
      builder: (context) => _ConfigDialog(
        statementType: _statementType,
        existingFields: _rows.map((r) => r.canonicalField).toSet(),
        onSave: (data) async {
          try {
            await createStatementColumn(data);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuration added.'), backgroundColor: Colors.green),
            );
            _loadConfigs();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }
  
  Future<void> _handleEditConfig(StatementColumnConfig config) async {
    await showDialog(
      context: context,
      builder: (context) => _ConfigDialog(
        statementType: _statementType,
        existingFields: _rows.map((r) => r.canonicalField).toSet(),
        initialData: config,
        onSave: (data) async {
          try {
            // Remove non-updatable fields if necessary, API handles it
            await updateStatementColumn(config.id, data);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuration updated.'), backgroundColor: Colors.green),
            );
            _loadConfigs();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statement Column Mapping'),
        actions: [
          if (_canUpdate)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _handleAddConfig,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _statementType,
              decoration: const InputDecoration(
                labelText: 'Statement Type',
                border: OutlineInputBorder(),
              ),
              items: _statementTypeOptions.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _statementType = value);
                  _loadConfigs();
                }
              },
            ),
          ),
          
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rows.isEmpty
                ? const Center(child: Text('No configuration found.'))
                : ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(row.displayName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Field: ${row.canonicalField}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (row.aliases.isNotEmpty)
                                Text('Aliases: ${row.aliases.join(", ")}'),
                              Text('Required: ${row.isRequired ? "Yes" : "No"}'),
                            ],
                          ),
                          trailing: _canUpdate
                              ? IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _handleEditConfig(row),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConfigDialog extends StatefulWidget {
  final String statementType;
  final Set<String> existingFields;
  final StatementColumnConfig? initialData;
  final Function(Map<String, dynamic>) onSave;

  const _ConfigDialog({
    required this.statementType,
    required this.existingFields,
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
    final availableFields = _canonicalFieldsByStatement[widget.statementType]!
        .where((f) => !widget.existingFields.contains(f) || f == widget.initialData?.canonicalField)
        .toList();

    return AlertDialog(
      title: Text(widget.initialData == null ? 'Add Configuration' : 'Edit Configuration'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.initialData == null)
                DropdownButtonFormField<String>(
                  value: _canonicalField.isNotEmpty ? _canonicalField : null,
                  decoration: const InputDecoration(labelText: 'Canonical Field'),
                  items: availableFields.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _canonicalField = value;
                        if (_displayNameController.text.isEmpty) {
                          _displayNameController.text = value.replaceAll('_', ' ');
                        }
                      });
                    }
                  },
                  validator: (value) => value == null ? 'Required' : null,
                )
              else
                 TextFormField(
                   initialValue: _canonicalField,
                   decoration: const InputDecoration(labelText: 'Canonical Field'),
                   enabled: false,
                 ),

              const SizedBox(height: 16),
              
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),
              
              TextFormField(
                controller: _aliasesController,
                decoration: const InputDecoration(labelText: 'Aliases (comma separated)'),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Required'),
                value: _isRequired,
                onChanged: (value) => setState(() => _isRequired = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : () async {
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
              
              widget.onSave(data);
            }
          },
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text('Save'),
        ),
      ],
    );
  }
}
