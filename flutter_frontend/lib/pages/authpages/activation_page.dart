
import 'package:flutter/material.dart';
import 'auth_page_layout.dart';
import '../../components/auth/activation_form.dart';

class ActivationPage extends StatelessWidget {
  const ActivationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthPageLayout(
      child: ActivationForm(),
    );
  }
}
