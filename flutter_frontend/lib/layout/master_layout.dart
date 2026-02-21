import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_helper.dart';
import 'master_sidebar.dart';
import 'master_header.dart';

class MasterLayout extends StatefulWidget {
  final Widget child;
  final String title;

  const MasterLayout({
    Key? key,
    required this.child,
    this.title = 'Fund Management',
  }) : super(key: key);

  @override
  State<MasterLayout> createState() => _MasterLayoutState();
}

class _MasterLayoutState extends State<MasterLayout> {
  bool _isSidebarExpanded = true;
  bool _isMobileSidebarOpen = false;

  void _toggleSidebar() {
    setState(() {
      if (ResponsiveHelper.isDesktop(context)) {
        _isSidebarExpanded = !_isSidebarExpanded;
      } else {
        _isMobileSidebarOpen = !_isMobileSidebarOpen;
      }
    });
  }

  void _closeMobileSidebar() {
    if (mounted) {
      setState(() {
        _isMobileSidebarOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final sidebarWidth = !isDesktop
        ? 0
        : (_isSidebarExpanded
            ? ResponsiveBoxConstraints.sidebarWidthExpanded
            : ResponsiveBoxConstraints.sidebarWidthCollapsed);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.gray50,
      body: Row(
        children: [
          // Desktop Sidebar
          if (isDesktop)
            MasterSidebar(
              isExpanded: _isSidebarExpanded,
              isMobileOpen: false,
              onClose: _closeMobileSidebar,
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                MasterHeader(
                  onMenuPressed: _toggleSidebar,
                  isSidebarExpanded: _isSidebarExpanded,
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: ResponsiveHelper.getResponsivePadding(context),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveBoxConstraints.maxContentWidth,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Mobile Sidebar Drawer
      endDrawer: isMobile && _isMobileSidebarOpen
          ? Drawer(
              child: MasterSidebar(
                isExpanded: true,
                isMobileOpen: _isMobileSidebarOpen,
                onClose: _closeMobileSidebar,
              ),
            )
          : null,
    );
  }
}


