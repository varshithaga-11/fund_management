import 'package:flutter/material.dart';
import 'forgot_password_api.dart';

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  int _step = 1;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _handleSendOtp() async {
    setState(() => _isSubmitting = true);
    final result = await sendOtp(_emailController.text);
    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email.')));
        setState(() => _step = 2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Failed')));
      }
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() => _isSubmitting = true);
    final result = await verifyOtp(_emailController.text, _otpController.text);
    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP verified. Please enter new password.')));
        setState(() => _step = 3);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Failed')));
      }
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }
    if (_newPasswordController.text.length < 8) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters long.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await resetPassword(
      _emailController.text,
      _otpController.text,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );
     if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful. You can now sign in.')));
        setState(() => _step = 4);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Failed')));
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_step == 1) ...[
            const Text('Forgot Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Enter your email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSendOtp,
              child: _isSubmitting ? const CircularProgressIndicator() : const Text('Send OTP'),
            ),
          ] else if (_step == 2) ...[
             const Text('Verify OTP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'Enter OTP', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleVerifyOtp,
              child: _isSubmitting ? const CircularProgressIndicator() : const Text('Verify OTP'),
            ),
             TextButton(onPressed: _handleSendOtp, child: const Text("Resend OTP")),
          ] else if (_step == 3) ...[
             const Text('Reset Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             TextField(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              decoration: InputDecoration(
                labelText: 'New password', border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showNewPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                )
              ),
            ),
            const SizedBox(height: 16),
             TextField(
              controller: _confirmPasswordController,
               obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm new password', border: const OutlineInputBorder(),
                 suffixIcon: IconButton(
                  icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                )
              ),
            ),
             const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleResetPassword,
              child: _isSubmitting ? const CircularProgressIndicator() : const Text('Reset Password'),
            ),
          ] else if (_step == 4) ...[
             const Text('Password Reset Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
             const SizedBox(height: 16),
             const Text('You can now sign in with your new password.'),
             TextButton(
               onPressed: () => Navigator.pushNamed(context, '/'), 
               child: const Text('Go to Sign In')
             ),
          ]
        ],
      ),
    );
  }
}
