import 'package:flutter/material.dart';
import 'signup_api.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  
  bool _showPassword = false;
  bool _isLoading = false;
  bool _passwordsMatch = true;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordsMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_passwordsMatch) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = UserData(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        passwordConfirm: _confirmPasswordController.text,
        role: "master",
      );

      final result = await registerUser(userData);

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful. You can now Sign In.')),
          );
          // Clear form
          _firstNameController.clear();
          _lastNameController.clear();
          _emailController.clear();
          _usernameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          
          // Optionally navigate to sign in
           Navigator.pushNamed(context, '/');

        } else {
           String errorMessage = result.error ?? "Registration failed";
           // Handle details if possible, simplified here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign Up',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
               Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
               ),
               const SizedBox(width: 16),
               Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
               ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
             keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Password',
               border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
             onChanged: (val) => _checkPasswordsMatch(),
            validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
               border: OutlineInputBorder(
                  borderSide: BorderSide(color: _passwordsMatch ? Colors.grey : Colors.red),
               ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _passwordsMatch ? Colors.blue : Colors.red, width: 2.0),
               ),
            ),
             onChanged: (val) => _checkPasswordsMatch(),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          if (!_passwordsMatch)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text('Passwords do not match', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: (_isLoading || !_passwordsMatch) ? null : _handleSubmit,
             style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading ? const CircularProgressIndicator() : const Text('Sign Up'),
          ),

           const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an account? "),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/');
                },
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
