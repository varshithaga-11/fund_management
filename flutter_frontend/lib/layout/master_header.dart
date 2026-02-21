import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_helper.dart';
import '../providers/theme_provider.dart';
import '../routes/app_routes.dart';

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
  
  @override
  void initState() {
    super.initState();
  }

  Future<void> _logout() async {
    // Clear any auth state here if needed
    AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      elevation: 1,
      color: isDark ? AppColors.darkCard : AppColors.white,
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
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // User Profile Menu
                  PopupMenuButton<String>(
                    offset: const Offset(0, 45),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.gray200,
                        width: 1,
                      ),
                    ),
                    color: isDark ? AppColors.darkCard : AppColors.white,
                    onSelected: (value) {
                      if (value == 'logout') {
                        _logout();
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline, 
                              size: 20,
                              color: isDark ? AppColors.gray300 : AppColors.gray700,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Profile', 
                              style: AppTypography.body2.copyWith(
                                color: isDark ? AppColors.gray300 : AppColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings_outlined, 
                              size: 20,
                              color: isDark ? AppColors.gray300 : AppColors.gray700,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Settings', 
                              style: AppTypography.body2.copyWith(
                                color: isDark ? AppColors.gray300 : AppColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout, size: 20, color: AppColors.danger),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Logout', 
                              style: AppTypography.body2.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 22,
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
