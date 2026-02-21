import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_helper.dart';
import '../providers/theme_provider.dart';

class MasterHeader extends StatefulWidget {
  final VoidCallback onMenuPressed;
  final bool isSidebarExpanded;
  
  const MasterHeader({
    Key? key,
    required this.onMenuPressed,
    this.isSidebarExpanded = true,
  }) : super(key: key);
  
  @override
  State<MasterHeader> createState() => _MasterHeaderState();
}

class _MasterHeaderState extends State<MasterHeader> {
  bool _showUserMenu = false;
  
  @override
  void initState() {
    super.initState();
  }

  Future<void> _logout() async {
    // Handle logout
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      elevation: 1,
      color: isDark ? AppColors.darkCard : AppColors.white,
      borderOnForeground: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.gray200,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Menu Button
              IconButton(
                onPressed: widget.onMenuPressed,
                icon: Icon(
                  Icons.menu,
                  color: isDark ? AppColors.gray400 : AppColors.gray500,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              
              const Spacer(),
              
              // Right Actions
              Row(
                children: [
              // Dark Mode Toggle
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                    ),
                    onPressed: () {
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),
                  
                  // Notifications
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                    ),
                    onPressed: () {},
                  ),
                  
                  // User Profile Menu
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'logout') {
                          _logout();
                        }
                      },
                      itemBuilder: (context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person),
                              SizedBox(width: AppSpacing.md),
                              Text('Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings),
                              SizedBox(width: AppSpacing.md),
                              Text('Settings'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: AppSpacing.md),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

