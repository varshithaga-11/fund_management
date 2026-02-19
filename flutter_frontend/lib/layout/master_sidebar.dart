import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

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
  final bool isHovered;
  final ValueChanged<bool> onHover;

  const MasterSidebar({
    super.key,
    required this.isExpanded,
    required this.isMobileOpen,
    required this.isHovered,
    required this.onHover,
  });

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
    NavItem(
      icon: Icons.manage_accounts,
      name: "User Management",
      path: AppRoutes.userManagement,
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
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return currentRoute == path;
  }

  @override
  Widget build(BuildContext context) {
    final bool showFullMenu = widget.isExpanded || widget.isHovered || widget.isMobileOpen;
    final double width = showFullMenu ? 290 : 90;

    // Mobile drawer behavior vs Desktop sidebar behavior
    // In a real responsive layout, this widget might be used inside a Drawer on mobile
    // and a persistent side Row on desktop. 
    // Here we just build the content assuming it's placed correctly by the parent layout.

    return MouseRegion(
      onEnter: (_) => !widget.isExpanded ? widget.onHover(true) : null,
      onExit: (_) => widget.onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          border: Border(right: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          children: [
            // Logo Area
            Container(
              height: 80,
              alignment: showFullMenu ? Alignment.centerLeft : Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: showFullMenu ? 24 : 0),
              child: Text(
                showFullMenu ? "Fund Management" : "KB",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  // Menu Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: showFullMenu
                        ? Text(
                            "MENU",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Icon(Icons.more_horiz, color: Colors.grey),
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
                          isExpanded: showFullMenu,
                          hasSubmenu: item.subItems != null && item.subItems!.isNotEmpty,
                          isSubmenuOpen: isSubmenuOpen,
                          onTap: () {
                            if (item.subItems != null) {
                              _toggleSubmenu(index);
                            } else if (item.path != null) {
                              Navigator.pushNamed(context, item.path!);
                            }
                          },
                        ),
                        
                        // Submenu
                        if (showFullMenu && item.subItems != null && isSubmenuOpen)
                          ...item.subItems!.map((subItem) {
                             final isSubActive = _isActive(subItem.path);
                             return _SidebarSubItem(
                               title: subItem.name,
                               isActive: isSubActive,
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
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isExpanded;
  final bool hasSubmenu;
  final bool isSubmenuOpen;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.isExpanded,
    required this.onTap,
    this.hasSubmenu = false,
    this.isSubmenuOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.blue : Colors.grey.shade700;
    final bgColor = isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            if (isExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasSubmenu)
                Icon(
                  isSubmenuOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: color,
                )
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final bool isPro;
  final bool isNew;

  const _SidebarSubItem({
    required this.title,
    required this.isActive,
    required this.onTap,
    this.isPro = false,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 48, right: 12, top: 10, bottom: 10),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
             if (isNew || isPro) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isNew ? Colors.green.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isNew ? 'NEW' : 'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isNew ? Colors.green : Colors.purple,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
