import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_helper.dart';

// Navigation Item Model
class NavItem {
  final String name;
  final IconData icon;
  final String? path;
  final List<SubNavItem>? subItems;

  NavItem({
    required this.name,
    required this.icon,
    this.path,
    this.subItems,
  });
}

class SubNavItem {
  final String name;
  final String path;
  final bool pro;
  final bool isNew;

  SubNavItem({
    required this.name,
    required this.path,
    this.pro = false,
    this.isNew = false,
  });
}

class MasterSidebar extends StatefulWidget {
  final bool isExpanded;
  final bool isMobileOpen;
  final VoidCallback onClose;

  const MasterSidebar({
    Key? key,
    required this.isExpanded,
    required this.isMobileOpen,
    required this.onClose,
  }) : super(key: key);

  @override
  State<MasterSidebar> createState() => _MasterSidebarState();
}

class _MasterSidebarState extends State<MasterSidebar> {
  int? _openSubmenuIndex;
  
  // Define navigation items
  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.dashboard,
      name: "Dashboard",
      path: "/master/master-dashboard",
    ),
    NavItem(
      icon: Icons.description,
      name: "Upload Data",
      path: "/upload-data",
    ),
    NavItem(
      icon: Icons.table_chart,
      name: "Column Mapping",
      path: "/statement-columns",
    ),
    NavItem(
      icon: Icons.bar_chart,
      name: "Ratio Analysis",
      path: "/ratio-analysis",
    ),
    NavItem(
      icon: Icons.trending_up,
      name: "Period Comparison",
      path: "/period-comparison",
    ),
    NavItem(
      icon: Icons.show_chart,
      name: "Ratio Benchmarks",
      path: "/ratio-benchmarks",
    ),
    NavItem(
      icon: Icons.manage_accounts,
      name: "User Management",
      path: "/user-management",
    ),
  ];

  void _toggleSubmenu(int index) {
    setState(() {
      if (_openSubmenuIndex == index) {
        _openSubmenuIndex = null;
      } else {
        _openSubmenuIndex = index;
      }
    });
  }

  bool _isActive(String? path) {
    if (path == null) return false;
    return ModalRoute.of(context)?.settings.name == path;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final sidebarWidth = widget.isExpanded 
        ? ResponsiveBoxConstraints.sidebarWidthExpanded 
        : ResponsiveBoxConstraints.sidebarWidthCollapsed;

    // On mobile, render as drawer overlay
    if (isMobile && widget.isMobileOpen) {
      return Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black26),
            ),
          ),
          // Sidebar drawer
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: ResponsiveBoxConstraints.sidebarWidthExpanded,
            child: _buildSidebarContent(isDark, ResponsiveBoxConstraints.sidebarWidthExpanded),
          ),
        ],
      );
    }

    // Desktop sidebar
    if (isMobile) return const SizedBox.shrink();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      child: _buildSidebarContent(isDark, sidebarWidth),
    );
  }

  Widget _buildSidebarContent(bool isDark, double width) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.gray200,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 70,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.gray200,
                ),
              ),
            ),
            alignment: widget.isExpanded ? Alignment.centerLeft : Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded ? AppSpacing.lg : 0,
            ),
            child: widget.isExpanded
                ? Text(
                    "FM",
                    style: AppTypography.h5.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                // Menu Header
                if (widget.isExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      "MENU",
                      style: AppTypography.overline.copyWith(
                        color: isDark ? AppColors.gray500 : AppColors.gray400,
                      ),
                    ),
                  ),

                // Nav Items
                ..._navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = _isActive(item.path);
                  final isSubmenuOpen = _openSubmenuIndex == index;

                  return Column(
                    children: [
                      _SidebarItem(
                        icon: item.icon,
                        title: item.name,
                        isActive: isActive,
                        isExpanded: widget.isExpanded,
                        isDark: isDark,
                        hasSubmenu: item.subItems != null && item.subItems!.isNotEmpty,
                        isSubmenuOpen: isSubmenuOpen,
                        onTap: () {
                          if (item.subItems != null && item.subItems!.isNotEmpty) {
                            _toggleSubmenu(index);
                          } else if (item.path != null) {
                            Navigator.pushNamed(context, item.path!);
                          }
                        },
                      ),
                      
                      // Submenu
                      if (widget.isExpanded && item.subItems != null && isSubmenuOpen)
                        ...item.subItems!.map((subItem) {
                          final isSubActive = _isActive(subItem.path);
                          return _SidebarSubItem(
                            title: subItem.name,
                            isActive: isSubActive,
                            isDark: isDark,
                            onTap: () => Navigator.pushNamed(context, subItem.path),
                            isPro: subItem.pro,
                            isNew: subItem.isNew,
                          );
                        }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isExpanded;
  final bool isDark;
  final bool hasSubmenu;
  final bool isSubmenuOpen;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.isExpanded,
    required this.isDark,
    required this.onTap,
    this.hasSubmenu = false,
    this.isSubmenuOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? AppColors.gray500 : AppColors.gray600;
    final bgColor = isActive 
        ? AppColors.primary.withOpacity(0.1)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 20,
              ),
              if (isExpanded) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.body2.copyWith(
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSubmenu)
                  Icon(
                    isSubmenuOpen ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: isActive ? activeColor : inactiveColor,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;
  final bool isPro;
  final bool isNew;

  const _SidebarSubItem({
    required this.title,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    this.isPro = false,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(
            left: AppSpacing.xxxl,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          child: Row(
            children: [
              Text(
                title,
                style: AppTypography.body3.copyWith(
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? AppColors.gray400 : AppColors.gray600),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isNew || isPro) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isNew 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    isNew ? 'NEW' : 'PRO',
                    style: AppTypography.overline.copyWith(
                      fontSize: 10,
                      color: isNew ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
