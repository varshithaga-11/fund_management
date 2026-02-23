import 'package:flutter/material.dart';
import 'route_constants.dart';
export 'route_constants.dart';

import '../layout/master_layout.dart';
import '../pages/dashboard/master_dashboard.dart';
// Auth Pages
import '../pages/authpages/sign_in.dart';
import '../components/auth/signin_form.dart';

import '../pages/authpages/sign_up.dart';
import '../pages/authpages/activation_page.dart';
import '../components/auth/forgot_password_form.dart';
import '../pages/companyratioanalysis/company_ratio_analysis_page.dart';
import '../pages/dashboard/index.dart';

// Financial Statements Pages
import '../pages/financialstatements/upload_data_page.dart';
import '../pages/financialstatements/statement_columns_config_page.dart';
import '../pages/financialstatements/financial_period_page.dart';

// Ratio Analysis Pages
import '../pages/ratioanalysis/ratio_analysis_page.dart';
import '../pages/ratioanalysis/trend_analysis_page.dart';
import '../pages/ratioanalysis/ratio_benchmarks_page.dart';
import '../pages/ratioanalysis/ratio_dashboard.dart';
import '../pages/ratioanalysis/productivity_analysis.dart';
import '../pages/ratioanalysis/interpretation_panel.dart';
import '../pages/periodcomparison/period_comparison_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/usermanagement/user_management_page.dart';

// Placeholder Pages (To be implemented)
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Page (Not Implemented Yet)')),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: const Center(child: Text('404 - Page Not Found')),
    );
  }
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;

    // Helper to extract params if needed, though simple params can be parsed from path splitting
    // For specific period ID routes, we assume a convention or arguments passed via settings.arguments

    switch (path) {
      case AppRoutes.masterDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MasterDashboardPage(),
        );
      
      case AppRoutes.companyRatioAnalysis:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CompanyRatioAnalysisPage(),
        );

      // Auth Routes
      case AppRoutes.signIn:
        return MaterialPageRoute(settings: settings, builder: (_) => const SignInPage());
      case AppRoutes.signUp:
        return MaterialPageRoute(settings: settings, builder: (_) => const SignUpPage());

      case AppRoutes.activate:
        return MaterialPageRoute(settings: settings, builder: (_) => const ActivationPage());
      case AppRoutes.resetPassword:
        return MaterialPageRoute(settings: settings, builder: (_) => const Scaffold(body: ForgotPasswordForm()));

      // Master Routes
      case AppRoutes.uploadData:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const UploadDataPage(),
        );
      
      case AppRoutes.statementColumns:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const StatementColumnsConfigPage(),
        );

      case AppRoutes.trendAnalysis:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TrendAnalysisPage(),
        );

      case AppRoutes.ratioAnalysis:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const RatioAnalysisPage(),
         );

      case AppRoutes.ratioBenchmarks:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const RatioBenchmarksPage(),
         );

      case AppRoutes.periodComparison:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const PeriodComparisonPage(),
         );
      
      case AppRoutes.userManagement:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const UserManagementPage(),
         );

      case AppRoutes.profile:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const ProfilePage(),
         );
      
      case AppRoutes.calendar:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Calendar'));
      
      case AppRoutes.blank:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Blank'));

      // UI Elements
      case AppRoutes.alerts:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Alerts'));
      case AppRoutes.avatars:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Avatars'));
      case AppRoutes.badges:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Badges'));
      case AppRoutes.buttons:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Buttons'));
      case AppRoutes.images:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Images'));
      case AppRoutes.videos:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Videos'));
      case AppRoutes.lineChart:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Line Chart'));
      case AppRoutes.barChart:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Bar Chart'));


      // Handle dynamic routes
      default:
        // /financial-statements/:id
        // /financial-statements/:id
        if (path.startsWith('/financial-statements/')) {
           final parts = path.split('/');
           if (parts.length > 2) {
               final periodId = int.tryParse(parts.last);
               if (periodId != null) {
                   return MaterialPageRoute(
                       settings: settings,
                       builder: (_) => FinancialPeriodPage(periodId: periodId),
                   );
               }
           }
        }
        
        // /ratio-analysis/dashboard/:periodId
        // This regex/check handles checking if the path starts with the base.
        // Since we have specific paths defined like '/ratio-analysis/trends', we need to be careful.
        // But the case statement handles exact matches first.
        
        if (path.startsWith('/ratio-analysis/dashboard/')) {
            // Extract ID
            final parts = path.split('/');
            if (parts.length > 3) {
                final periodId = int.tryParse(parts.last);
                if (periodId != null) {
                    return MaterialPageRoute(
                        settings: settings,
                        builder: (_) => RatioDashboardPage(periodId: periodId),
                    );
                }
            }
        }

        if (path.startsWith('/productivity-analysis/')) {
             final parts = path.split('/');
             if (parts.length > 2) {
                 final periodId = int.tryParse(parts.last);
                 if (periodId != null) {
                     return MaterialPageRoute(
                         settings: settings,
                         builder: (_) => ProductivityAnalysisPage(periodId: periodId),
                     );
                 }
             }
        }
        
        if (path.startsWith('/interpretation/')) {
            final parts = path.split('/');
             if (parts.length > 2) {
                 final periodId = int.tryParse(parts.last);
                 if (periodId != null) {
                     return MaterialPageRoute(
                         settings: settings,
                         builder: (_) => InterpretationPanelPage(periodId: periodId),
                     );
                 }
             }
        }

        return MaterialPageRoute(settings: settings, builder: (_) => const NotFoundPage());
    }
  }
}

class ShellRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateRoute(newRoute);
    }
  }

  void _updateRoute(Route<dynamic> route) {
    if (route.settings.name != null) {
      AppRoutes.currentRoute.value = route.settings.name;
    }
  }
}
