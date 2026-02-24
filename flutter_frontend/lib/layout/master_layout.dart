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
      body: Stack(
        children: [
          // Desktop Sidebar (absolutely positioned - doesn't affect layout)
          if (showLayout && isDesktop)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: MasterSidebar(
                isExpanded: layoutProvider.isSidebarExpanded,
                isMobileOpen: false,
                onClose: layoutProvider.closeMobileSidebar,
              ),
            ),

          // Main content with animated left margin
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Column(
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
                
                // Main Content with animated left margin
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.only(
                      left: isDesktop && showLayout
                        ? (layoutProvider.isSidebarExpanded ? 290 : 90)
                        : 0,
                    ),
                    child: Padding(
                      padding: ResponsiveHelper.getResponsivePadding(context),
                      child: child,
                    ),
                  ),
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


