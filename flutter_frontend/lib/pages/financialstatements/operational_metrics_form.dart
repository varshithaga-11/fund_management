import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'financial_statements_api.dart';

class OperationalMetricsForm extends StatefulWidget {
  final int periodId;
  final VoidCallback? onSave;
  final bool canUpdate;

  const OperationalMetricsForm({
    super.key,
    required this.periodId,
    this.onSave,
    this.canUpdate = true,
  });

  @override
  State<OperationalMetricsForm> createState() => _OperationalMetricsFormState();
}

class _OperationalMetricsFormState extends State<OperationalMetricsForm> {
  final _formKey = GlobalKey<FormState>();
  final _staffCountController = TextEditingController();
  
  bool _loading = false;
  int? _existingId;
  
  bool get _isReadOnly => !widget.canUpdate && _existingId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _staffCountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await getOperationalMetrics(widget.periodId);
      if (data != null) {
        setState(() {
          _existingId = data.id;
          _staffCountController.text = data.staffCount.toString();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading operational metrics: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final staffCount = int.tryParse(_staffCountController.text) ?? 0;
    if (staffCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff count must be greater than 0'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    
    final data = {
      'staff_count': staffCount,
    };

    try {
      if (_existingId != null) {
        await updateOperationalMetrics(_existingId!, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operational Metrics updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        await createOperationalMetrics(widget.periodId, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operational Metrics created successfully!'), backgroundColor: Colors.green),
        );
      }
      await _loadData();
      widget.onSave?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save operational metrics: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Operational Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _staffCountController,
              decoration: const InputDecoration(
                labelText: 'Number of Staff *',
                border: OutlineInputBorder(),
                hintText: 'Enter number of staff members',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                return null;
              },
              enabled: !_loading && !_isReadOnly,
            ),
            
            const SizedBox(height: 24),
            
            if (!_isReadOnly)
              ElevatedButton(
                onPressed: _loading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _loading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : Text(_existingId != null ? 'Update' : 'Save'),
              ),
          ],
        ),
      ),
    );
  }
}
