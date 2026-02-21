import 'package:flutter/material.dart';
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
// Note: FinancialPeriodPage is navigated to dynamically, typically doesn't have a top-level route in this list but could if needed.
import '../pages/financialstatements/financial_period_page.dart';

// Ratio Analysis Pages
import '../pages/ratioanalysis/ratio_analysis_page.dart';
import '../pages/ratioanalysis/trend_analysis_page.dart';
import '../pages/ratioanalysis/ratio_benchmarks_page.dart';
import '../pages/ratioanalysis/ratio_dashboard.dart';
import '../pages/ratioanalysis/productivity_analysis.dart';
import '../pages/ratioanalysis/interpretation_panel.dart';

// Other Pages
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

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ValueNotifier<String?> currentRoute = ValueNotifier<String?>(null);

  static const String signIn = '/';
  static const String activate = '/activate';
  static const String signUp = '/signup';
  static const String masterDashboard = '/master/master-dashboard';
  static const String companyRatioAnalysis = '/ratio-analysis';
  static const String resetPassword = '/resetpassword';
  
  // Dashboard


  // Financial Statements
  static const String uploadData = '/upload-data';
  static const String financialStatements = '/financial-statements'; // /:periodId
  static const String statementColumns = '/statement-columns';

  // Ratio Analysis
  static const String trendAnalysis = '/ratio-analysis/trends';
  static const String ratioAnalysis = '/ratio-analysis-list'; // Changed to distinct path
  static const String ratioDashboard = '/ratio-analysis/dashboard'; // /:periodId
  static const String ratioBenchmarks = '/ratio-benchmarks';
  static const String productivityAnalysis = '/productivity-analysis'; // /:periodId
  static const String interpretation = '/interpretation'; // /:periodId
  static const String periodComparison = '/period-comparison';
  static const String userManagement = '/user-management';

  // Others
  static const String profile = '/profile';
  static const String calendar = '/calendar';
  static const String blank = '/blank';
  static const String alerts = '/alerts';
  static const String avatars = '/avatars';
  static const String badges = '/badge';
  static const String buttons = '/buttons';
  static const String images = '/images';
  static const String videos = '/videos';
  static const String lineChart = '/line-chart';
  static const String barChart = '/bar-chart';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;

    // Helper to extract params if needed, though simple params can be parsed from path splitting
    // For specific period ID routes, we assume a convention or arguments passed via settings.arguments

    switch (path) {
      case masterDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MasterDashboardPage(),
        );
      
      // Note: companyRatioAnalysis path '/ratio-analysis' conflicts with ratioAnalysisPage if they share the same base.
      // Adjusting paths:
      // - Company Ratio Analysis (High Level): '/ratio-analysis'
      // - Ratio Analysis (Periods List): '/ratio-analysis-list'
      case companyRatioAnalysis:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CompanyRatioAnalysisPage(),
        );

      // Auth Routes
      case signIn:
        return MaterialPageRoute(settings: settings, builder: (_) => const SignInPage());
      case signUp:
        return MaterialPageRoute(settings: settings, builder: (_) => const SignUpPage());

      case activate:
        return MaterialPageRoute(settings: settings, builder: (_) => const ActivationPage());
      case resetPassword:
        return MaterialPageRoute(settings: settings, builder: (_) => const Scaffold(body: ForgotPasswordForm()));

      // Master Routes (Wrapped in Master Layout where appropriate or just the Page itself if it has scaffolding)
      
      case uploadData:
         // Using the fully implemented UploadDataPage
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const UploadDataPage(),
        );
      
      case statementColumns:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const StatementColumnsConfigPage(),
        );

      case trendAnalysis:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TrendAnalysisPage(),
        );

      case ratioAnalysis:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const RatioAnalysisPage(),
         );

      case ratioBenchmarks:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const RatioBenchmarksPage(),
         );

      case periodComparison:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const PeriodComparisonPage(),
         );
      
      case userManagement:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const UserManagementPage(),
         );

      case profile:
         return MaterialPageRoute(
           settings: settings,
           builder: (_) => const ProfilePage(),
         );
      
      case calendar:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Calendar'));
      
      case blank:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Blank'));
 
      // UI Elements
      case alerts:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Alerts'));
      case avatars:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Avatars'));
      case badges:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Badges'));
      case buttons:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Buttons'));
      case images:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Images'));
      case videos:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Videos'));
      case lineChart:
         return MaterialPageRoute(builder: (_) => const PlaceholderPage('Line Chart'));
      case barChart:
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
