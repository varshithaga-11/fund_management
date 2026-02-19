import 'package:flutter/material.dart';
import 'auth_page_layout.dart';
import '../../components/auth/signup_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthPageLayout(
      child: SignUpForm(),
    );
  }
}
