import 'package:flutter/material.dart';
import 'master_layout.dart';
import '../routes/route_constants.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;
  const DashboardShell({Key? key, required this.child}) : super(key: key);

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final _innerNavigatorKey = GlobalKey<NavigatorState>();
  String? _currentRoute;

  @override
  void initState() {
    super.initState();
    // Use a small delay to get the initial route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppRoutes.currentRoute.value == null) {
        final route = ModalRoute.of(context)?.settings.name;
        AppRoutes.currentRoute.value = route;
      }
    });
  }

  void _updateRoute() {
    final route = ModalRoute.of(AppRoutes.navigatorKey.currentContext!)?.settings.name;
    if (_currentRoute != route) {
      setState(() {
        _currentRoute = route;
      });
    }
  }

  bool _shouldShowLayout(String? route) {
    if (route == null) return false;
    // Auth routes that should NOT have the layout
    final authRoutes = [
      AppRoutes.signIn,
      AppRoutes.signUp,
      AppRoutes.activate,
      AppRoutes.resetPassword,
    ];
    return !authRoutes.contains(route);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (context) => ValueListenableBuilder<String?>(
          valueListenable: AppRoutes.currentRoute,
          builder: (context, currentRoute, _) {
            bool showLayout = _shouldShowLayout(currentRoute);
            
            return MasterLayout(
              showLayout: showLayout,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}
