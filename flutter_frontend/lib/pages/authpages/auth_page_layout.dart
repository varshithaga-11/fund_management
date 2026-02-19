import 'package:flutter/material.dart';

class AuthPageLayout extends StatelessWidget {
  final Widget child;

  const AuthPageLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Content Area (Form)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: child,
                ),
              ),
            ),
          ),

          // Illustration Area (Desktop Only)
          if (isDesktop)
            Expanded(
              child: Container(
                color: const Color(0xFF0F172A), // brand-950 equivalent
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background grid effect could go here
                     Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Fund Management",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '"Management Of funds"',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const Positioned(
                      bottom: 24,
                      right: 24,
                      child: SizedBox(), // ThemeToggler placeholder
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
