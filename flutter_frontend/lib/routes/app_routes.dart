```
import 'package:flutter/material.dart';

// Auth Pages
import '../components/auth/signin_form.dart';
import '../pages/authpages/sign_up.dart';
import '../components/auth/forgot_password_form.dart';
import '../pages/companyratioanalysis/company_ratio_analysis_page.dart';
import '../pages/dashboard/index.dart';

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

// Master Layout Placeholder
class MasterLayout extends StatelessWidget {
  final Widget child;
  const MasterLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Layout')),
      drawer: const Drawer(),
      body: child,
    );
  }
}

class AppRoutes {
  static const String signIn = '/';
  static const String signUp = '/signup';
  static const String dashboard = '/master/master-dashboard';
  static const String companyRatioAnalysis = '/ratio-analysis';
  static const String resetPassword = '/resetpassword';
  
  // Dashboard


  // Financial Statements
  static const String uploadData = '/upload-data';
  static const String financialStatements = '/financial-statements'; // /:periodId
  static const String statementColumns = '/statement-columns';

  // Ratio Analysis
  static const String trendAnalysis = '/ratio-analysis/trends';
  static const String ratioAnalysis = '/ratio-analysis';
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

    // Helper to handle parameterized routes if needed
    // String? getParam(String key) => uri.queryParameters[key];

    switch (path) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case companyRatioAnalysis:
        return MaterialPageRoute(
            builder: (_) => const CompanyRatioAnalysisPage());
      // Auth Routes
      case signIn:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: SignInForm()));
      case signUp:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: SignUpForm()));
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: ForgotPasswordForm()));

      // Master Routes (Wrapped in Master Layout)

      
      case uploadData:
        return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Upload Data')));
      
      case statementColumns:
        return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Statement Columns')));

      case trendAnalysis:
        return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Trend Analysis')));

      case ratioAnalysis:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Ratio Analysis')));

      case ratioBenchmarks:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Ratio Benchmarks')));

      case periodComparison:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Period Comparison')));
      
      case userManagement:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('User Management')));

      case profile:
         return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Profile')));
      
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


      // Handle dynamic routes (simple example, real apps might use regex or a router package like go_router)
      default:
        // Check for parameterized routes manually if using default Navigator
        if (path.startsWith('/financial-statements/')) {
           return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Financial Statements Period')));
        }
        if (path.startsWith('/ratio-analysis/') && path != trendAnalysis) {
           return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Ratio Dashboard Period')));
        }
        if (path.startsWith('/productivity-analysis/')) {
           return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Productivity Analysis')));
        }
        if (path.startsWith('/interpretation/')) {
           return MaterialPageRoute(builder: (_) => const MasterLayout(child: PlaceholderPage('Interpretation')));
        }

        return MaterialPageRoute(builder: (_) => const NotFoundPage());
    }
  }
}
