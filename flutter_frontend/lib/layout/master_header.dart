import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/profile/profile_api.dart';

class MasterHeader extends StatefulWidget {
  final VoidCallback onToggleSidebar;
  final bool isMobileOpen;

  const MasterHeader({
    super.key,
    required this.onToggleSidebar,
    required this.isMobileOpen,
  });

  @override
  State<MasterHeader> createState() => _MasterHeaderState();
}

class _MasterHeaderState extends State<MasterHeader> {
  UserProfileData? _profile;
  String _role = 'User';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('userRole') ?? 'User';
      final profile = await getUserProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _role = role;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile in header: $e');
      // If profile fails, we still have the role from prefs
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access');
    await prefs.remove('refresh');
    await prefs.remove('userRole');
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

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
                onPressed: widget.onToggleSidebar,
                icon: Icon(widget.isMobileOpen ? Icons.close : Icons.menu),
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
                    if (MediaQuery.of(context).size.width > 600)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ('${_profile?.firstName ?? ""} ${_profile?.lastName ?? ""}'.trim().isNotEmpty)
                                ? '${_profile!.firstName} ${_profile!.lastName}'.trim()
                                : (_profile?.username ?? 'User'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(_role.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ('${_profile?.firstName ?? ""} ${_profile?.lastName ?? ""}'.trim().isNotEmpty)
                              ? '${_profile!.firstName} ${_profile!.lastName}'.trim()
                              : (_profile?.username ?? ''),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        if (_profile?.email != null)
                          Text(_profile!.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Divider(),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 8), Text('My Profile')],
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
                    _logout();
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

