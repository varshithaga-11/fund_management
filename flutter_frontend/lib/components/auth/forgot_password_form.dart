import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme.dart' show AppColors;
import 'forgot_password_api.dart';

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> with SingleTickerProviderStateMixin {
  int _step = 1;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleSendOtp() async {
    if (_emailController.text.isEmpty) {
      _showError('Email is required');
      return;
    }
    
    if (!_validateEmail(_emailController.text)) {
      _showError('Invalid email');
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await sendOtp(_emailController.text);
    if (mounted) {
      if (result.success) {
        _showSuccess('OTP sent to your email');
        setState(() => _step = 2);
        _resetAnimation();
      } else {
        _showError(result.error ?? 'Failed');
      }
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showError('OTP is required');
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await verifyOtp(_emailController.text, _otpController.text);
    if (mounted) {
      if (result.success) {
        _showSuccess('OTP verified');
        setState(() => _step = 3);
        _resetAnimation();
      } else {
        _showError(result.error ?? 'Invalid OTP');
      }
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showError('Required fields');
      return;
    }
    
    if (_newPasswordController.text.length < 8) {
      _showError('Min 8 characters');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords mismatch');
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
        setState(() => _step = 4);
        _resetAnimation();
      } else {
        _showError(result.error ?? 'Failed');
      }
      setState(() => _isSubmitting = false);
    }
  }

  void _resetAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String placeholder, IconData? icon) {
    return InputDecoration(
      hintText: placeholder,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 16, color: Colors.grey[600]) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 32),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.9, end: 1).animate(_animationController),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Stack(
                  children: [
                    _buildCard(
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_step == 1) ...[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(height: 12),
                              const Text('Forgot Password?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('Enter your email to reset', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _emailController,
                                enabled: !_isSubmitting,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration('Email address', Icons.mail_outline),
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _handleSendOtp,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: AppColors.primary,
                                    disabledBackgroundColor: Colors.grey[400],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8))))
                                      : const Text('Send OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ] else if (_step == 2) ...[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(height: 12),
                              const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('Check your email', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _otpController,
                                enabled: !_isSubmitting,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '000000',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFAFA),
                                  counterText: '',
                                ),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 6),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _handleVerifyOtp,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8))))
                                      : const Text('Verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _isSubmitting ? null : _handleSendOtp,
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
                                child: const Text('Resend OTP?', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                              ),
                            ] else if (_step == 3) ...[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.vpn_key_outlined, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(height: 12),
                              const Text('New Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('Create a strong password', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _newPasswordController,
                                enabled: !_isSubmitting,
                                obscureText: !_showNewPassword,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showNewPassword ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.grey[600]),
                                    onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFAFA),
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _confirmPasswordController,
                                enabled: !_isSubmitting,
                                obscureText: !_showConfirmPassword,
                                decoration: InputDecoration(
                                  hintText: 'Confirm password',
                                  prefixIcon: Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.grey[600]),
                                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFAFA),
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _handleResetPassword,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8))))
                                      : const Text('Reset Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ] else if (_step == 4) ...[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0x1F059669),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                              ),
                              const SizedBox(height: 12),
                              const Text('Password Reset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('You can sign in now', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: const Color(0xFF059669),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    // Back button
                    Positioned(
                      top: 0,
                      left: 0,
                      child: IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/'),
                        icon: const Icon(Icons.arrow_back, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                        tooltip: 'Back to Login',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
