import 'package:flutter/material.dart';
import 'auth_page_layout.dart';
import '../../components/auth/signin_form.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthPageLayout(
      child: SignInForm(),
    );
  }
}
