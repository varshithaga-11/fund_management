import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_helper.dart';
import '../routes/app_routes.dart';

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
  late final VoidCallback _routeListener;
  
  // Define navigation items
  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.dashboard,
      name: "Dashboard",
      path: AppRoutes.masterDashboard,
    ),
    NavItem(
      icon: Icons.description,
      name: "Upload Data",
      path: AppRoutes.uploadData,
    ),
    NavItem(
      icon: Icons.table_chart,
      name: "Column Mapping",
      path: AppRoutes.statementColumns,
    ),
    NavItem(
      icon: Icons.bar_chart,
      name: "Ratio Analysis",
      path: AppRoutes.ratioAnalysis,
    ),
    NavItem(
      icon: Icons.trending_up,
      name: "Period Comparison",
      path: AppRoutes.periodComparison,
    ),
    NavItem(
      icon: Icons.show_chart,
      name: "Ratio Benchmarks",
      path: AppRoutes.ratioBenchmarks,
    ),
    // NavItem(
    //   icon: Icons.manage_accounts,
    //   name: "User Management",
    //   path: AppRoutes.userManagement,
    // ),
  ];

  @override
  void initState() {
    super.initState();
    _routeListener = () {
      if (mounted) setState(() {});
    };
    AppRoutes.currentRoute.addListener(_routeListener);
  }

  @override
  void dispose() {
    AppRoutes.currentRoute.removeListener(_routeListener);
    super.dispose();
  }

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
    return AppRoutes.currentRoute.value == path;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final sidebarWidth = widget.isExpanded 
        ? 290.0 // Matches React w-[290px]
        : 90.0; // Matches React w-[90px]

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      child: _buildSidebarContent(isDark, sidebarWidth),
    );
  }

  Widget _buildSidebarContent(bool isDark, double width) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Logo Area
          Container(
            alignment: widget.isExpanded ? Alignment.centerLeft : Alignment.center,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxxl, // Matches React py-8 (32px)
              horizontal: 0,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: widget.isExpanded
                  ? const Text(
                      "Fund Management",
                      key: ValueKey('expanded_logo'),
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      softWrap: false,
                      overflow: TextOverflow.clip,
                    )
                  : const Text(
                      "FM",
                      key: ValueKey('collapsed_logo'),
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      softWrap: false,
                    ),
            ),
          ),

          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: AppRoutes.currentRoute,
              builder: (context, currentRoute, _) {
                final isMobile = ResponsiveHelper.isMobile(context);
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    // Menu Header
                    if (widget.isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16, // Matches React mb-4
                        ),
                        child: Text(
                          "MENU",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
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
                                AppRoutes.navigatorKey.currentState?.pushNamed(item.path!);
                                if (isMobile) widget.onClose();
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
                                onTap: () {
                                  AppRoutes.navigatorKey.currentState?.pushNamed(subItem.path);
                                  if (isMobile) widget.onClose();
                                },
                                isPro: subItem.pro,
                                isNew: subItem.isNew,
                              );
                            }),
                        ],
                      );
                    }),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
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
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF6366F1);
    final inactiveColor =
        widget.isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    // Single background: active > hover > transparent
    Color bgColor;
    if (widget.isActive) {
      bgColor = activeColor.withOpacity(0.1);
    } else if (_isHovering) {
      bgColor = widget.isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.04);
    } else {
      bgColor = Colors.transparent;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.isActive ? activeColor : inactiveColor,
                size: 20,
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.isExpanded ? 1.0 : 0.0,
                child: widget.isExpanded
                    ? Row(
                        children: [
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 160,
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.isActive
                                    ? activeColor
                                    : inactiveColor,
                                fontWeight: widget.isActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              if (widget.isExpanded && widget.hasSubmenu)
                Icon(
                  widget.isSubmenuOpen
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 18,
                  color: widget.isActive ? activeColor : inactiveColor,
                ),
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
            left: 48,
            right: 16,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive
                      ? const Color(0xFF6366F1)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isNew || isPro) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isNew 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isNew ? 'NEW' : 'PRO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isNew ? Colors.green : Colors.orange,
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
