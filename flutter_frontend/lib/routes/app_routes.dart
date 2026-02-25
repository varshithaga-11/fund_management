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

// Custom optimized page route for faster transitions
class _OptimizedPageRoute<T> extends MaterialPageRoute<T> {
  _OptimizedPageRoute({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) : super(
    builder: builder,
    settings: settings,
  );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use a faster, simpler fade transition instead of slide
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

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

    // Helper to determine if a route should show the layout
    bool shouldShowLayout(String route) {
      final authRoutes = [
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.activate,
        AppRoutes.resetPassword,
      ];
      return !authRoutes.contains(route);
    }

    Widget wrap(Widget page) {
      if (shouldShowLayout(path)) {
        return MasterLayout(
          showLayout: true,
          child: page,
        );
      }
      return page;
    }

    switch (path) {
      case AppRoutes.masterDashboard:
        return _OptimizedPageRoute(
          settings: settings,
          builder: (_) => wrap(const MasterDashboardPage()),
        );
      
      case AppRoutes.companyRatioAnalysis:
        return _OptimizedPageRoute(
          settings: settings,
          builder: (_) => wrap(const CompanyRatioAnalysisPage()),
        );

      // Auth Routes - No Layout
      case AppRoutes.signIn:
        return _OptimizedPageRoute(settings: settings, builder: (_) => const SignInPage());
      case AppRoutes.signUp:
        return _OptimizedPageRoute(settings: settings, builder: (_) => const SignUpPage());
      case AppRoutes.activate:
        return _OptimizedPageRoute(settings: settings, builder: (_) => const ActivationPage());
      case AppRoutes.resetPassword:
        return _OptimizedPageRoute(settings: settings, builder: (_) => const Scaffold(body: ForgotPasswordForm()));

      // Master Routes - With Layout
      case AppRoutes.uploadData:
        return _OptimizedPageRoute(
          settings: settings,
          builder: (_) => wrap(const UploadDataPage()),
        );
      
      case AppRoutes.statementColumns:
        return _OptimizedPageRoute(
          settings: settings,
          builder: (_) => wrap(const StatementColumnsConfigPage()),
        );

      case AppRoutes.trendAnalysis:
        return _OptimizedPageRoute(
          settings: settings,
          builder: (_) => wrap(const TrendAnalysisPage()),
        );

      case AppRoutes.ratioAnalysis:
         return _OptimizedPageRoute(
           settings: settings,
           builder: (_) => wrap(const RatioAnalysisPage()),
         );

      case AppRoutes.ratioBenchmarks:
         return _OptimizedPageRoute(
           settings: settings,
           builder: (_) => wrap(const RatioBenchmarksPage()),
         );

      case AppRoutes.periodComparison:
         return _OptimizedPageRoute(
           settings: settings,
           builder: (_) => wrap(const PeriodComparisonPage()),
         );
      
      case AppRoutes.userManagement:
         return _OptimizedPageRoute(
           settings: settings,
           builder: (_) => wrap(const UserManagementPage()),
         );

      case AppRoutes.profile:
         return _OptimizedPageRoute(
           settings: settings,
           builder: (_) => wrap(const ProfilePage()),
         );
      
      case AppRoutes.calendar:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Calendar')), settings: settings);
      
      case AppRoutes.blank:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Blank')), settings: settings);

      // UI Elements
      case AppRoutes.alerts:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Alerts')), settings: settings);
      case AppRoutes.avatars:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Avatars')), settings: settings);
      case AppRoutes.badges:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Badges')), settings: settings);
      case AppRoutes.buttons:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Buttons')), settings: settings);
      case AppRoutes.images:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Images')), settings: settings);
      case AppRoutes.videos:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Videos')), settings: settings);
      case AppRoutes.lineChart:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Line Chart')), settings: settings);
      case AppRoutes.barChart:
         return _OptimizedPageRoute(builder: (_) => wrap(const PlaceholderPage('Bar Chart')), settings: settings);


      // Handle dynamic routes
      default:
        // /financial-statements/:id
        if (path.startsWith('/financial-statements/')) {
           final parts = path.split('/');
           if (parts.length > 2) {
               final periodId = int.tryParse(parts.last);
               if (periodId != null) {
                   return _OptimizedPageRoute(
                       settings: settings,
                       builder: (_) => wrap(FinancialPeriodPage(periodId: periodId)),
                   );
               }
           }
        }
        
        if (path.startsWith('/ratio-analysis/dashboard/')) {
            final parts = path.split('/');
            if (parts.length > 3) {
                final periodId = int.tryParse(parts.last);
                if (periodId != null) {
                    return _OptimizedPageRoute(
                        settings: settings,
                        builder: (_) => wrap(RatioDashboardPage(periodId: periodId)),
                    );
                }
            }
        }

        if (path.startsWith('/productivity-analysis/')) {
             final parts = path.split('/');
             if (parts.length > 2) {
                 final periodId = int.tryParse(parts.last);
                 if (periodId != null) {
                     return _OptimizedPageRoute(
                         settings: settings,
                         builder: (_) => wrap(ProductivityAnalysisPage(periodId: periodId)),
                     );
                 }
             }
        }
        
        if (path.startsWith('/interpretation/')) {
            final parts = path.split('/');
             if (parts.length > 2) {
                 final periodId = int.tryParse(parts.last);
                 if (periodId != null) {
                     return _OptimizedPageRoute(
                         settings: settings,
                         builder: (_) => wrap(InterpretationPanelPage(periodId: periodId)),
                     );
                 }
             }
        }

        return _OptimizedPageRoute(settings: settings, builder: (_) => const NotFoundPage());
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
