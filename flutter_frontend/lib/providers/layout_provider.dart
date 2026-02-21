import 'package:flutter/material.dart';

class LayoutProvider extends ChangeNotifier {
  bool _isSidebarExpanded = true;
  bool _isMobileSidebarOpen = false;

  bool get isSidebarExpanded => _isSidebarExpanded;
  bool get isMobileSidebarOpen => _isMobileSidebarOpen;

  void toggleSidebar() {
    _isSidebarExpanded = !_isSidebarExpanded;
    notifyListeners();
  }

  void setMobileSidebarOpen(bool isOpen) {
    _isMobileSidebarOpen = isOpen;
    notifyListeners();
  }

  void toggleMobileSidebar() {
    _isMobileSidebarOpen = !_isMobileSidebarOpen;
    notifyListeners();
  }

  void closeMobileSidebar() {
    _isMobileSidebarOpen = false;
    notifyListeners();
  }
}
