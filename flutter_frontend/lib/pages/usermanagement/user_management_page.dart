import 'package:flutter/material.dart';
import '../../theme/responsive_helper.dart';
import '../../theme/app_theme.dart';
import 'user_api.dart';
import 'add_edit_user_dialog.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final List<UserRegister> _allUsers = [];
  List<UserRegister> _filteredUsers = []; // All matching users
  List<UserRegister> _currentPageUsers = []; // Users on current page
  bool _loading = true;
  String? _error;

  final ScrollController _horizontalScrollController = ScrollController();

  // Filters
  String _searchQuery = '';
  String _roleFilter = 'all'; 
  String _statusFilter = 'all';

  // Sorting
  String _sortField = 'username';
  bool _isAscending = true;

  // Pagination
  int _pageSize = 10;
  int _currentPage = 1; // 1-indexed to match React logic

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final users = await getUserList(); 
      if (mounted) {
        setState(() {
          _allUsers.clear();
          _allUsers.addAll(users);
          _applyFilters();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<UserRegister> temp = List.from(_allUsers);

    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((user) {
        return user.username.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.firstName?.toLowerCase().contains(query) ?? false) ||
            (user.lastName?.toLowerCase().contains(query) ?? false) ||
            user.role.toLowerCase().contains(query);
      }).toList();
    }

    // Role Filter
    if (_roleFilter != 'all') {
      temp = temp.where((user) => user.role.toLowerCase() == _roleFilter.toLowerCase()).toList();
    }

    // Status Filter
    if (_statusFilter != 'all') {
      final isActive = _statusFilter == 'active';
      temp = temp.where((user) => user.isActive == isActive).toList();
    }

    // Sorting
    temp.sort((a, b) {
      dynamic aVal, bVal;
      switch (_sortField) {
        case 'username': aVal = a.username; bVal = b.username; break;
        case 'email': aVal = a.email; bVal = b.email; break;
        case 'first_name': aVal = a.firstName ?? ''; bVal = b.firstName ?? ''; break;
        case 'last_name': aVal = a.lastName ?? ''; bVal = b.lastName ?? ''; break;
        case 'role': aVal = a.role; bVal = b.role; break;
        default: aVal = ''; bVal = '';
      }
      int cmp = aVal.compareTo(bVal);
      return _isAscending ? cmp : -cmp;
    });

    _filteredUsers = temp;
    _updatePageUsers();
  }

  void _updatePageUsers() {
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    
    if (startIndex >= _filteredUsers.length) {
      _currentPageUsers = [];
    } else {
      _currentPageUsers = _filteredUsers.sublist(
        startIndex, 
        endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex
      );
    }
    setState(() {});
  }

  int get _totalPages => (_filteredUsers.length / _pageSize).ceil();

  void _handleSort(String field) {
    if (_sortField == field) {
      _isAscending = !_isAscending;
    } else {
      _sortField = field;
      _isAscending = true;
    }
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          _buildBreadcrumb(context, isDark),
          const SizedBox(height: 24),

          // Filters & Controls Section
          _buildControls(context, isDark),
          const SizedBox(height: 20),

          // Table Section
          _buildTableCard(isDark),
          const SizedBox(height: 20),

          // Pagination Section
          if (_totalPages > 1) _buildPagination(isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "User Management",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (ResponsiveHelper.isDesktop(context))
          Row(
            children: [
              Text(
                "Home",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ),
              Text(
                "User Management",
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.gray900),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, bool isDark) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search
        SizedBox(
          width: isDesktop ? 300 : double.infinity,
          height: 44,
          child: TextField(
            onChanged: (val) {
              _searchQuery = val;
              _currentPage = 1;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),

        // Filters Group
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildDropdown(
              label: 'Role:',
              value: _roleFilter,
              items: ['all', 'admin', 'master'],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _roleFilter = val);
                  _currentPage = 1;
                  _applyFilters();
                }
              },
            ),
            _buildDropdown(
              label: 'Status:',
              value: _statusFilter,
              items: ['all', 'active', 'inactive'],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _statusFilter = val);
                  _currentPage = 1;
                  _applyFilters();
                }
              },
            ),
            
            _buildPageSizeSelector(),

            ElevatedButton.icon(
              onPressed: () => _openAddEditDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1), style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageSizeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Show:', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _pageSize,
              items: [5, 10, 25, 50].map((e) => DropdownMenuItem(value: e, child: Text('$e', style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _pageSize = val;
                    _currentPage = 1;
                    _applyFilters();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Scrollbar(
            controller: _horizontalScrollController,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - (ResponsiveHelper.isDesktop(context) ? 350 : 64)),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF9FAFB)),
                  horizontalMargin: 24,
                  columnSpacing: 32,
                  dataRowMaxHeight: 64,
                  columns: [
                    const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black))),
                    _buildSortableColumn('User Name', 'username'),
                    _buildSortableColumn('Email', 'email'),
                    _buildSortableColumn('First Name', 'first_name'),
                    _buildSortableColumn('Last Name', 'last_name'),
                    _buildSortableColumn('Role', 'role'),
                    const DataColumn(label: Text('Is Active?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black))),
                    const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black))),
                  ],
                  rows: List.generate(_currentPageUsers.length, (index) {
                    final user = _currentPageUsers[index];
                    final globalIndex = (_currentPage - 1) * _pageSize + index + 1;
                    return DataRow(
                      cells: [
                        DataCell(Text('$globalIndex', style: const TextStyle(color: Colors.grey))),
                        DataCell(Text(user.username, style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(user.email)),
                        DataCell(Text(user.firstName ?? '-')),
                        DataCell(Text(user.lastName ?? '-')),
                        DataCell(Text(user.role, style: const TextStyle(fontSize: 13))),
                        DataCell(
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: user.isActive,
                              onChanged: null,
                              fillColor: WidgetStateProperty.all(const Color(0xFF10B981)),
                              checkColor: Colors.white,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                onPressed: () => _openAddEditDialog(user),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit',
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                onPressed: () => _deleteUser(user.id!),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          if (_currentPageUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(60.0),
              child: Center(
                child: Text(
                  _searchQuery.isNotEmpty ? 'No users match your search' : 'No users found',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataColumn _buildSortableColumn(String label, String field) {
    final isActive = _sortField == field;
    return DataColumn(
      label: InkWell(
        onTap: () => _handleSort(field),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 6),
            Icon(
              isActive ? (_isAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
              size: 14,
              color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Showing ${(_filteredUsers.isEmpty ? 0 : (_currentPage - 1) * _pageSize + 1)} to ${(_currentPage * _pageSize > _filteredUsers.length ? _filteredUsers.length : _currentPage * _pageSize)} of ${_filteredUsers.length} entries",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              _PaginationButton(
                label: "Previous",
                onPressed: _currentPage > 1 ? () => setState(() { _currentPage--; _updatePageUsers(); }) : null,
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(),
              const SizedBox(width: 8),
              _PaginationButton(
                label: "Next",
                onPressed: _currentPage < _totalPages ? () => setState(() { _currentPage++; _updatePageUsers(); }) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> buttons = [];
    int start = _currentPage - 2;
    if (start < 1) start = 1;
    int end = start + 4;
    if (end > _totalPages) {
      end = _totalPages;
      start = end - 4;
      if (start < 1) start = 1;
    }

    for (int i = start; i <= end; i++) {
       final isCurrent = i == _currentPage;
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: () => setState(() { _currentPage = i; _updatePageUsers(); }),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF6366F1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCurrent ? const Color(0xFF6366F1) : Colors.grey.shade200),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return buttons;
  }

  void _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteUser(id);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
           _fetchUsers();
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _openAddEditDialog([UserRegister? user]) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditUserDialog(
        user: user,
        onSuccess: _fetchUsers,
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PaginationButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: onPressed == null ? Colors.grey : Colors.grey.shade700,
        ),
      ),
    );
  }
}
