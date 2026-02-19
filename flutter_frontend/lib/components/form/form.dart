import 'package:flutter/material.dart';

class FormContainer extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Widget child;
  final VoidCallback? onSubmit;

  const FormContainer({
    super.key,
    required this.formKey,
    required this.child,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          child,
          // You might check if you want the submit button logic here or passed as child
        ],
      ),
    );
  }
}
