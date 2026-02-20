import 'package:flutter/material.dart';
import '../layout/master_layout.dart';
// Auth Pages
import '../components/auth/signin_form.dart';
import '../pages/authpages/sign_up.dart';
import '../components/auth/forgot_password_form.dart';
import '../pages/companyratioanalysis/company_ratio_analysis_page.dart';
import '../pages/dashboard/index.dart';

// Financial Statements Pages
import '../pages/financialstatements/upload_data_page.dart';
import '../pages/financialstatements/statement_columns_config_page.dart';
// Note: FinancialPeriodPage is navigated to dynamically, typically doesn't have a top-level route in this list but could if needed.

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
  static const String signIn = '/';
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
        return MaterialPageRoute(builder: (_) => const MasterLayout(
          title: 'Dashboard',
          child: DashboardPage()
        ));
      
      // Note: companyRatioAnalysis path '/ratio-analysis' conflicts with ratioAnalysisPage if they share the same base.
      // Adjusting paths:
      // - Company Ratio Analysis (High Level): '/ratio-analysis'
      // - Ratio Analysis (Periods List): '/ratio-analysis-list'
      case companyRatioAnalysis:
        return MaterialPageRoute(builder: (_) => const MasterLayout(
          title: 'Company Analysis',
          child: CompanyRatioAnalysisPage()
        ));

      // Auth Routes
      case signIn:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: SignInForm()));
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: ForgotPasswordForm()));

      // Master Routes (Wrapped in Master Layout where appropriate or just the Page itself if it has scaffolding)
      
      case uploadData:
         // Using the fully implemented UploadDataPage
        return MaterialPageRoute(builder: (_) => const MasterLayout(
          title: 'Upload Data',
          child: UploadDataPage()
        ));
      
      case statementColumns:
        return MaterialPageRoute(builder: (_) => const MasterLayout(
          title: 'Statement Columns',
          child: StatementColumnsConfigPage()
        ));

      case trendAnalysis:
        return MaterialPageRoute(builder: (_) => const MasterLayout(
          title: 'Trend Analysis',
          child: TrendAnalysisPage()
        ));

      case ratioAnalysis:
         return MaterialPageRoute(builder: (_) => const MasterLayout(
           title: 'Ratio Analysis',
           child: RatioAnalysisPage()
         ));

      case ratioBenchmarks:
         return MaterialPageRoute(builder: (_) => const MasterLayout(
           title: 'Benchmarks',
           child: RatioBenchmarksPage()
         ));

      case periodComparison:
         return MaterialPageRoute(builder: (_) => const MasterLayout(
           title: 'Period Comparison',
           child: PeriodComparisonPage()
         ));
      
      case userManagement:
         return MaterialPageRoute(builder: (_) => const MasterLayout(
           title: 'User Management',
           child: UserManagementPage()
         ));

      case profile:
         return MaterialPageRoute(builder: (_) => const MasterLayout(
           title: 'Profile',
           child: ProfilePage()
         ));
      
      case calendar:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Calendar')));
      
      case blank:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Blank')));

      // UI Elements
      case alerts:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Alerts')));
      case avatars:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Avatars')));
      case badges:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Badges')));
      case buttons:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Buttons')));
      case images:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Images')));
      case videos:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Videos')));
      case lineChart:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Line Chart')));
      case barChart:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Bar Chart')));


      // Handle dynamic routes
      default:
        // /financial-statements/:id
        if (path.startsWith('/financial-statements/')) {
           return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Financial Statements Period')));
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
                    return MaterialPageRoute(builder: (_) => RatioDashboardPage(periodId: periodId));
                }
            }
        }

        if (path.startsWith('/productivity-analysis/')) {
             final parts = path.split('/');
             if (parts.length > 2) {
                 final periodId = int.tryParse(parts.last);
                 if (periodId != null) {
                     return MaterialPageRoute(builder: (_) => ProductivityAnalysisPage(periodId: periodId));
                 }
             }
        }
        
        if (path.startsWith('/interpretation/')) {
            final parts = path.split('/');
             if (parts.length > 2) {
                 final periodId = int.tryParse(parts.last);
                 if (periodId != null) {
                     return MaterialPageRoute(builder: (_) => InterpretationPanelPage(periodId: periodId));
                 }
             }
        }

        return MaterialPageRoute(builder: (_) => const NotFoundPage());
    }
  }
}
