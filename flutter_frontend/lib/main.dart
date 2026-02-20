
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'routes/app_routes.dart';
import 'components/auth/activation_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  
  final activationService = ActivationService();
  final bool isActivated = await activationService.isActivated();
  
  runApp(MyApp(isActivated: isActivated));
}

class MyApp extends StatelessWidget {
  final bool isActivated;
  const MyApp({super.key, required this.isActivated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fund Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: isActivated ? AppRoutes.signIn : AppRoutes.activate,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
