import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../access/access.dart';
import 'user_api.dart'; // Make sure this path is correct

class AddEditUserDialog extends StatefulWidget {
  final UserRegister? user;
  final VoidCallback onSuccess;

  const AddEditUserDialog({super.key, this.user, required this.onSuccess});

  @override
  State<AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  
  String _role = 'master';
  bool _isActive = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _firstNameController = TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.user?.lastName ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    
    if (widget.user != null) {
      _role = widget.user!.role;
      _isActive = widget.user!.isActive;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.user == null && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match");
      return;
    }

    if (widget.user != null && _passwordController.text.isNotEmpty && _passwordController.text != _confirmPasswordController.text) {
       setState(() => _errorMessage = "Passwords do not match");
       return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.user == null) {
        // Create
        // Need to get current user ID for created_by
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access');
        int? currentUserId;
        // Basic decode if available, else null
        // Assuming we might need jwt_decoder package here if not already imported or available
        // But for now, we'll skip detailed decoding if package not imported in this file.
        // Actually best to use a helper from user_api if available.
        // Let's assume backend handles created_by from request.user
        
        final newUser = UserRegister(
          username: _usernameController.text,
          email: _emailController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          role: _role,
          isActive: _isActive,
          createdBy: currentUserId, // backend should handle if null, or we decode
          password: _passwordController.text,
        );
        
        await createUser(newUser);

        if (mounted) {
          widget.onSuccess();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created successfully')));
        }
      } else {
        // Update
        final Map<String, dynamic> data = {
          'username': _usernameController.text,
          'email': _emailController.text,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'role': _role,
          'is_active': _isActive,
        };

        if (_passwordController.text.isNotEmpty) {
          data['password'] = _passwordController.text;
        }

        await updateUser(widget.user!.id!, data);
        
        if (mounted) {
          widget.onSuccess();
          Navigator.of(context).pop();
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully')));
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit User' : 'Add New User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username *'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'master', child: Text('Master')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  // Add other roles as needed
                ],
                onChanged: (val) => setState(() => _role = val ?? 'master'),
              ),
              const SizedBox(height: 8),
              if (!isEditing) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password *'),
                  obscureText: true,
                  validator: (val) => val == null || val.length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password *'),
                  obscureText: true,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
              ] else ...[
                 TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'New Password (Optional)'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm New Password'),
                  obscureText: true,
                ),
              ],
               const SizedBox(height: 8),
               CheckboxListTile(
                 title: const Text('Active'),
                 value: _isActive,
                 onChanged: (val) => setState(() => _isActive = val ?? true),
                 contentPadding: EdgeInsets.zero,
               )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), 
          child: const Text('Cancel')
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
