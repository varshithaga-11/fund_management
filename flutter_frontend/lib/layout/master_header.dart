import 'package:flutter/material.dart';

class MasterHeader extends StatelessWidget {
  final VoidCallback onToggleSidebar;
  final bool isMobileOpen;

  const MasterHeader({
    super.key,
    required this.onToggleSidebar,
    required this.isMobileOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 64, // Common header height
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Sidebar Toggle
          Row(
            children: [
              IconButton(
                onPressed: onToggleSidebar,
                icon: Icon(isMobileOpen ? Icons.close : Icons.menu),
                tooltip: 'Toggle Sidebar',
              ),
              const SizedBox(width: 16),
              // Mobile Logo (Text) - simplistic approach
              if (MediaQuery.of(context).size.width < 1024) 
                 const Text(
                   'Fund Management',
                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                 ),
            ],
          ),

          // Right side: Actions
          Row(
            children: [
              // Theme Toggle Placeholder
              IconButton(
                onPressed: () {
                  // TODO: Implement Theme Toggle
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme Toggle not implemented yet')),
                  );
                },
                icon: const Icon(Icons.wb_sunny_outlined), // Or dark_mode based on state
                tooltip: 'Toggle Theme',
              ),
              const SizedBox(width: 8),
              
              // Notification Placeholder
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),

              // User Dropdown
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('User Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                         Text('Admin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [Icon(Icons.person, size: 20), SizedBox(width: 8), Text('My Profile')],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [Icon(Icons.settings, size: 20), SizedBox(width: 8), Text('Account Settings')],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [Icon(Icons.logout, size: 20), SizedBox(width: 8), Text('Sign Out')],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.of(context).pushNamed('/profile');
                  } else if (value == 'logout') {
                    // Handle logout
                     Navigator.of(context).pushReplacementNamed('/');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
