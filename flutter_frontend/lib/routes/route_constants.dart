import 'package:flutter/material.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ValueNotifier<String?> currentRoute = ValueNotifier<String?>(null);

  static const String signIn = '/';
  static const String activate = '/activate';
  static const String signUp = '/signup';
  static const String masterDashboard = '/master/master-dashboard';
  static const String companyRatioAnalysis = '/ratio-analysis';
  static const String resetPassword = '/resetpassword';
  
  // Financial Statements
  static const String uploadData = '/upload-data';
  static const String financialStatements = '/financial-statements'; // /:periodId
  static const String statementColumns = '/statement-columns';

  // Ratio Analysis
  static const String trendAnalysis = '/ratio-analysis/trends';
  static const String ratioAnalysis = '/ratio-analysis-list'; 
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
}
