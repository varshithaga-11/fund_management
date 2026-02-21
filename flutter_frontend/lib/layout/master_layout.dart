import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_helper.dart';
import '../providers/layout_provider.dart';
import 'master_sidebar.dart';
import 'master_header.dart';

class MasterLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const MasterLayout({
    Key? key,
    required this.child,
    this.title = 'Fund Management',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final layoutProvider = Provider.of<LayoutProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.gray50,
      body: Column(
        children: [
          // Header Header at the top (full width)
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
          Expanded(
            child: Row(
              children: [
                // Desktop Sidebar below header
                if (isDesktop)
                  MasterSidebar(
                    isExpanded: layoutProvider.isSidebarExpanded,
                    isMobileOpen: false,
                    onClose: layoutProvider.closeMobileSidebar,
                  ),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: ResponsiveHelper.getResponsivePadding(context),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: ResponsiveBoxConstraints.maxContentWidth,
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
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


