import 'package:flutter/material.dart';
import 'auth_page_layout.dart';
import '../../components/auth/forgot_password_form.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthPageLayout(
      child: ForgotPasswordForm(),
    );
  }
}
