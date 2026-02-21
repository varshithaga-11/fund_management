import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'components/auth/activation_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  
  // Initialize API service
  await ApiService.initialize();
  
  final activationService = ActivationService();
  final bool isActivated = await activationService.isActivated();
  
  runApp(MyApp(isActivated: isActivated));
}

class MyApp extends StatelessWidget {
  final bool isActivated;
  const MyApp({super.key, required this.isActivated});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Fund Management',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildLightTheme(),
            darkTheme: AppTheme.buildDarkTheme(),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: isActivated ? AppRoutes.signIn : AppRoutes.activate,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
