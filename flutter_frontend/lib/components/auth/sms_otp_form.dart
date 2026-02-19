import 'package:flutter/material.dart';
import 'sms_otp_api.dart';

class SMSOTPForm extends StatefulWidget {
  const SMSOTPForm({super.key});

  @override
  State<SMSOTPForm> createState() => _SMSOTPFormState();
}

class _SMSOTPFormState extends State<SMSOTPForm> {
  String _step = 'phone';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String _maskedPhone = '';
  int? _remainingAttempts;

  Future<void> _handleSendOTP() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your phone number')));
      return;
    }
    
    // Basic validation
    if (!_phoneController.text.startsWith('+')) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter phone number with country code')));
       return;
    }

    setState(() => _isLoading = true);
    final result = await sendSMSOTP(SendOTPData(phoneNumber: _phoneController.text));
    
    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'OTP sent successfully! Check your phone.')));
        setState(() {
          _maskedPhone = result.phoneNumber ?? _phoneController.text;
          _step = 'otp';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Failed to send OTP')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the OTP')));
      return;
    }
    if (_otpController.text.length != 6) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP must be 6 digits')));
      return;
    }

    setState(() => _isLoading = true);
    final result = await verifySMSOTP(VerifyOTPData(phoneNumber: _phoneController.text, otp: _otpController.text));

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Login successful! Redirecting...')));
        
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
            Navigator.pushReplacementNamed(context, '/admin/master-dashboard');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Invalid OTP')));
        if (result.remainingAttempts != null) {
          setState(() {
            _remainingAttempts = result.remainingAttempts;
          });
          if (result.remainingAttempts == 0) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum attempts exceeded. Please request a new OTP.')));
             setState(() {
               _step = 'phone';
               _otpController.clear();
             });
          }
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _step == 'phone' ? 'SMS Authentication' : 'Verify OTP',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
             _step == 'phone' 
              ? 'Enter your authorized mobile number to receive OTP' 
              : 'Enter the 6-digit code sent to $_maskedPhone',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          if (_step == 'phone') ...[
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number', 
                hintText: '+919876543210',
                border: OutlineInputBorder(),
                helperText: 'Include country code',
              ),
              keyboardType: TextInputType.phone,
            ),
             const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOTP,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Send OTP'),
            ),
          ] else ...[
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'Enter OTP', 
                border: const OutlineInputBorder(),
                helperText: _remainingAttempts != null ? '$_remainingAttempts attempts remaining' : null,
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(letterSpacing: 5, fontSize: 20),
            ),
             const SizedBox(height: 16),
             ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyOTP,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Verify OTP'),
            ),
             const SizedBox(height: 16),
             Row(
               children: [
                 Expanded(
                   child: OutlinedButton(
                     onPressed: () {
                       setState(() {
                         _step = 'phone';
                         _otpController.clear();
                         _remainingAttempts = null;
                       });
                     },
                     child: const Text('Change Number'),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: OutlinedButton(
                     onPressed: _handleSendOTP,
                     child: const Text('Resend OTP'),
                   ),
                 ),
               ],
             )
          ]
        ],
      ),
    );
  }
}
