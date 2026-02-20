import 'package:flutter/material.dart';
import 'master_sidebar.dart';
import 'master_header.dart'; // Import the newly created header

class MasterLayout extends StatefulWidget {
  final Widget child;
  final String title;

  const MasterLayout({
    super.key, 
    required this.child, 
    this.title = 'Fund Management',
  });

  @override
  State<MasterLayout> createState() => _MasterLayoutState();
}

class _MasterLayoutState extends State<MasterLayout> {
  // Sidebar states
  bool _isSidebarExpanded = true;
  bool _isSidebarHovered = false;
  bool _isMobileSidebarOpen = false;

  void _toggleSidebar() {
    setState(() {
      if (MediaQuery.of(context).size.width >= 1024) {
        _isSidebarExpanded = !_isSidebarExpanded;
      } else {
        _isMobileSidebarOpen = !_isMobileSidebarOpen;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    
    // Sidebar width logic
    double sidebarWidth = 0;
    if (isDesktop) {
       sidebarWidth = (_isSidebarExpanded || _isSidebarHovered) ? 290 : 90;
    } else {
      // Mobile: sidebar is overlay (drawer), so layout width is 0 effectively for main content shift
       sidebarWidth = 0; 
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main Content Area
          Positioned(
            left: sidebarWidth,
            right: 0,
            top: 0,
            bottom: 0,
            child: Column(
              children: [
                // Header
                MasterHeader(
                  onToggleSidebar: _toggleSidebar,
                  isMobileOpen: _isMobileSidebarOpen,
                ),
                
                // Page Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),

          // Sidebar (Desktop: Fixed / Mobile: Drawer-like)
          if (isDesktop) 
             Positioned(
               left: 0,
               top: 0,
               bottom: 0,
               width: sidebarWidth,
               child: MasterSidebar(
                 isExpanded: _isSidebarExpanded,
                 isMobileOpen: false,
                 isHovered: _isSidebarHovered,
                 onHover: (val) => setState(() => _isSidebarHovered = val),
               ),
             ),
          
          // Mobile Sidebar Overlay
          if (!isDesktop && _isMobileSidebarOpen) ...[
             // Backdrop
             Positioned.fill(
               child: GestureDetector(
                 onTap: () => setState(() => _isMobileSidebarOpen = false),
                 child: Container(color: Colors.black54),
               ),
             ),
             // Drawer Sidebar
             Positioned(
               left: 0,
               top: 0,
               bottom: 0,
               width: 290,
               child: MasterSidebar(
                 isExpanded: true, // Always expanded on mobile drawer
                 isMobileOpen: true,
                 isHovered: false,
                 onHover: (_) {}, 
               ),
             ),
          ],
        ],
      ),
    );
  }
}
