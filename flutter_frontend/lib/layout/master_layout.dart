import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_helper.dart';
import '../providers/layout_provider.dart';
import 'master_sidebar.dart';
import 'master_header.dart';

class MasterLayout extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showLayout;

  const MasterLayout({
    Key? key,
    required this.child,
    this.title,
    this.showLayout = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final layoutProvider = Provider.of<LayoutProvider>(context);

    if (!showLayout) return child;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.gray50,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Desktop Sidebar (left side)
          if (showLayout && isDesktop)
            MasterSidebar(
              isExpanded: layoutProvider.isSidebarExpanded,
              isMobileOpen: false,
              onClose: layoutProvider.closeMobileSidebar,
            ),

          // Header and Content Column (right side, expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header at the top
                if (showLayout)
                  MasterHeader(
                    onMenuPressed: () {
                      if (isDesktop) {
                        layoutProvider.toggleSidebar();
                      } else {
                        layoutProvider.toggleMobileSidebar();
                      }
                    },
                    isSidebarExpanded: layoutProvider.isSidebarExpanded,
                  ),
                
                // Main Content
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),

      // Mobile Sidebar Drawer
      endDrawer: isMobile && layoutProvider.isMobileSidebarOpen
          ? Drawer(
              child: MasterSidebar(
                isExpanded: true,
                isMobileOpen: layoutProvider.isMobileSidebarOpen,
                onClose: layoutProvider.closeMobileSidebar,
              ),
            )
          : null,
    );
  }
}


