import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_helper.dart';
import '../providers/theme_provider.dart';
import '../routes/route_constants.dart';

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
  bool _isApplicationMenuOpen = false;
  
  @override
  void initState() {
    super.initState();
  }

  Future<void> _logout() async {
    // Clear any auth state here if needed
    AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
  }

  void _toggleApplicationMenu() {
    setState(() {
      _isApplicationMenuOpen = !_isApplicationMenuOpen;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveHelper.isMobile(context);
    
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
        child: Column(
          children: [
            // Main Header Row
            Container(
              height: ResponsiveHelper.getResponsiveValue(
                context,
                mobile: 64, // React mobile height
                tablet: 76, // React desktop height
                desktop: 76,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveValue(
                  context,
                  mobile: AppSpacing.md, // 12px
                  tablet: AppSpacing.xxl, // 24px
                  desktop: AppSpacing.xxl, // 24px
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu Button & Title/Logo area
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: widget.onMenuPressed,
                        icon: Icon(
                          Icons.menu,
                          color: isDark ? AppColors.gray400 : AppColors.gray500,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                  ),
                  
                  // Right Actions
                  if (!isMobile)
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                        
                        const SizedBox(width: AppSpacing.md),
                        
                        // User Profile Menu
                        _buildUserMenu(context, isDark),
                      ],
                    )
                  else
                    // Three-dot Menu - Mobile View
                    IconButton(
                      onPressed: _toggleApplicationMenu,
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark ? AppColors.gray400 : AppColors.gray500,
                      ),
                    ),
                ],
              ),
            ),
            
            // Mobile Application Menu (collapsible)
            if (isMobile && _isApplicationMenuOpen)
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.gray200,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dark Mode Toggle
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                color: isDark ? AppColors.gray400 : AppColors.gray500,
                              ),
                              onPressed: () {
                                themeProvider.toggleTheme();
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.gray400 : AppColors.gray600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    // User Profile Menu
                    _buildUserMenu(context, isDark),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, bool isDark) {
    return PopupMenuButton<String>(
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
        } else if (value == 'profile') {
          AppRoutes.navigatorKey.currentState?.pushNamed(AppRoutes.profile);
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
    );
  }}