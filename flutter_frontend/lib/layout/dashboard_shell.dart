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
  String? _previousRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update current route from ModalRoute
    final route = ModalRoute.of(context)?.settings.name;
    if (_previousRoute != route && route != null) {
      AppRoutes.currentRoute.value = route;
      _previousRoute = route;
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
    return ValueListenableBuilder<String?>(
      valueListenable: AppRoutes.currentRoute,
      builder: (context, currentRoute, _) {
        bool showLayout = _shouldShowLayout(currentRoute);
        
        return MasterLayout(
          showLayout: showLayout,
          child: widget.child,
        );
      },
    );
  }
}
