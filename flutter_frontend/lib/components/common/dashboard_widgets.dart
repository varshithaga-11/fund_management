import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_helper.dart';

// Stat Card Widget for displaying key metrics
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color gradientStart;
  final Color gradientEnd;
  final bool isLoading;
  final VoidCallback? onTap;
  
  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.gradientStart,
    required this.gradientEnd,
    this.isLoading = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.gray200,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        color: isDark ? AppColors.darkCard : AppColors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: Stack(
            children: [
              // Gradient background accent
              Positioned(
                top: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [gradientStart, gradientEnd],
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [gradientStart, gradientEnd],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradientStart.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: AppColors.white, size: 24),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    // Value
                    if (isLoading)
                      const ShimmerLoader(width: 120, height: 32)
                    else
                      Text(
                        value,
                        style: AppTypography.h3.copyWith(
                          color: isDark ? AppColors.white : AppColors.black,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: AppSpacing.sm),
                    // Title
                    Text(
                      title,
                      style: AppTypography.body2.copyWith(
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dashboard Card for generic content
class DashboardCard extends StatelessWidget {
  final String? title;
  final Widget? child;
  final EdgeInsets padding;
  final bool isLoading;
  final List<Widget>? actions;
  final BorderRadius? borderRadius;
  
  const DashboardCard({
    Key? key,
    this.title,
    this.child,
    this.padding = const EdgeInsets.all(24),
    this.isLoading = false,
    this.actions,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? BorderRadius.circular(AppRadius.xxl);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.gray200,
        ),
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        color: isDark ? AppColors.darkCard : AppColors.white,
      ),
      child: Column(
        children: [
          // Header
          if (title != null || actions != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: AppTypography.h4.copyWith(
                        color: isDark ? AppColors.white : AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (actions != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                ],
              ),
            ),
          // Divider
          if (title != null || actions != null)
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.gray200,
            ),
          // Content
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: ShimmerLoader(width: double.infinity, height: 200),
            )
          else if (child != null)
            Padding(
              padding: padding,
              child: child,
            ),
        ],
      ),
    );
  }
}

// Shimmer loader for loading states
class ShimmerLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const ShimmerLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0, 0.5, 1],
          colors: [
            isDark ? AppColors.gray700 : AppColors.gray200,
            isDark ? AppColors.gray600 : AppColors.gray100,
            isDark ? AppColors.gray700 : AppColors.gray200,
          ],
          tileMode: TileMode.clamp,
        ).createShader(
          Rect.fromLTWH(
            0,
            0,
            bounds.width,
            bounds.height,
          ),
        );
      },
      child: Transform.translate(
        offset: Offset(
          _controller.value * 400 - 200,
          0,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray700 : AppColors.gray200,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}

// Responsive Grid Widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double gap;
  
  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
    this.gap = AppSpacing.lg,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.getResponsiveValue(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );
    
    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

// Custom Button
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final bool fullWidth;
  
  const AppButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.fullWidth = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );
    
    final button = isOutlined
        ? OutlinedButton(onPressed: isLoading ? null : onPressed, child: child)
        : ElevatedButton(onPressed: isLoading ? null : onPressed, child: child);
    
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onRetry;
  
  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark ? AppColors.gray600 : AppColors.gray300,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.h5.copyWith(
                color: isDark ? AppColors.gray300 : AppColors.gray700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.gray400 : AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
