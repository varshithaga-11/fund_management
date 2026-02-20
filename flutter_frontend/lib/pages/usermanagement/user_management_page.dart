import 'package:flutter/material.dart';
import '../../layout/master_layout.dart';
import 'user_api.dart';
import 'add_edit_user_dialog.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<UserRegister> _allUsers = [];
  List<UserRegister> _filteredUsers = [];
  bool _loading = true;
  String? _error;

  // Filters
  String _searchQuery = '';
  String _roleFilter = 'all'; // all, master, admin, employee
  String _statusFilter = 'all'; // all, active, inactive

  // Sorting
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  // Pagination
  int _rowsPerPage = 10;
  int _currentPage = 0; // 0-indexed

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      // React code passes userId to getUserList, but the API impl seems to handle filtering by created_by optionally.
      // If we want to see ALL users, we might not need to pass createdBy unless backend restricts it.
      // Let's first try fetching all.
      final users = await getUserList(); 
      setState(() {
        _allUsers = users;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
            (user.lastName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Role Filter
    if (_roleFilter != 'all') {
      temp = temp.where((user) => user.role == _roleFilter).toList();
    }

    // Status Filter
    if (_statusFilter != 'all') {
      final isActive = _statusFilter == 'active';
      temp = temp.where((user) => user.isActive == isActive).toList();
    }

    // Sorting
    temp.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0: // Username
          cmp = a.username.compareTo(b.username);
          break;
        case 1: // Email
          cmp = a.email.compareTo(b.email);
          break;
        case 2: // First Name
          cmp = (a.firstName ?? '').compareTo(b.firstName ?? '');
          break;
        case 3: // Last Name
          cmp = (a.lastName ?? '').compareTo(b.lastName ?? '');
          break;
        case 4: // Role
          cmp = a.role.compareTo(b.role);
          break;
        default:
          cmp = 0;
      }
      return _isAscending ? cmp : -cmp;
    });

    setState(() {
      _filteredUsers = temp;
      _currentPage = 0; // Reset to first page on filter change
    });
  }

// Methods moved below build


  @override
  Widget build(BuildContext context) {
    // Client-side pagination logic
    final totalRows = _filteredUsers.length;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage < totalRows) ? start + _rowsPerPage : totalRows;
    final pageUsers = _filteredUsers.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Controls
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Search
                          SizedBox(
                            width: 250,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Search...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (val) {
                                _searchQuery = val;
                                _applyFilters();
                              },
                            ),
                          ),
                          
                          // Role Filter
                          DropdownButton<String>(
                            value: _roleFilter,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Roles')),
                              DropdownMenuItem(value: 'admin', child: Text('Admin')),
                              DropdownMenuItem(value: 'master', child: Text('Master')),
                              DropdownMenuItem(value: 'employee', child: Text('Employee')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _roleFilter = val;
                                _applyFilters();
                              }
                            },
                          ),

                          // Status Filter
                          DropdownButton<String>(
                            value: _statusFilter,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Status')),
                              DropdownMenuItem(value: 'active', child: Text('Active')),
                              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _statusFilter = val;
                                _applyFilters();
                              }
                            },
                          ),

                          const Spacer(),

                          ElevatedButton.icon(
                            onPressed: () => _openAddEditDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, 
                              foregroundColor: Colors.white
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      // Table
                      Expanded(
                        child: SingleChildScrollView(
                          child: Theme(
                             data: Theme.of(context).copyWith(cardColor: Theme.of(context).canvasColor),
                             child: PaginatedDataTable(
                              header: const Text('Users List'),
                              columns: [
                                DataColumn(
                                  label: const Text('Username'),
                                  onSort: (idx, asc) {
                                    setState(() {
                                      _sortColumnIndex = idx;
                                      _isAscending = asc;
                                      _applyFilters();
                                    });
                                  }
                                ),
                                DataColumn(
                                  label: const Text('Email'),
                                  onSort: (idx, asc) {
                                    setState(() {
                                      _sortColumnIndex = idx;
                                      _isAscending = asc;
                                      _applyFilters();
                                    });
                                  }
                                ),
                                DataColumn(
                                  label: const Text('First Name'),
                                  onSort: (idx, asc) {
                                    setState(() {
                                      _sortColumnIndex = idx;
                                      _isAscending = asc;
                                      _applyFilters();
                                    });
                                  }
                                ),
                                DataColumn(
                                  label: const Text('Last Name'),
                                  onSort: (idx, asc) {
                                    setState(() {
                                      _sortColumnIndex = idx;
                                      _isAscending = asc;
                                      _applyFilters();
                                    });
                                  }
                                ),
                                DataColumn(
                                  label: const Text('Role'),
                                  onSort: (idx, asc) {
                                    setState(() {
                                      _sortColumnIndex = idx;
                                      _isAscending = asc;
                                      _applyFilters();
                                    });
                                  }
                                ),
                                const DataColumn(label: Text('Active')),
                                const DataColumn(label: Text('Actions')),
                              ],
                              source: _UserDataSource(
                                users: _filteredUsers,
                                onDelete: (id) => _deleteUser(id),
                                onEdit: (user) => _openAddEditDialog(user),
                                context: context,
                              ),
                              rowsPerPage: _rowsPerPage,
                              availableRowsPerPage: const [5, 10, 25, 50],
                              onRowsPerPageChanged: (val) {
                                setState(() {
                                  _rowsPerPage = val ?? 10;
                                  _currentPage = 0;
                                });
                              },
                              initialFirstRowIndex: _currentPage * _rowsPerPage,
                              onPageChanged: (rowIndex) {
                                setState(() {
                                  _currentPage = rowIndex ~/ _rowsPerPage;
                                });
                              },
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _isAscending,
                              showCheckboxColumn: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
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

// DataTable Source
class _UserDataSource extends DataTableSource {
  final List<UserRegister> users;
  final Function(int) onDelete;
  final Function(UserRegister) onEdit;
  final BuildContext context;

  _UserDataSource({
    required this.users,
    required this.onDelete,
    required this.onEdit,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;
    final user = users[index];

    return DataRow(
      cells: [
        DataCell(Text(user.username)),
        DataCell(Text(user.email)),
        DataCell(Text(user.firstName ?? '')),
        DataCell(Text(user.lastName ?? '')),
        DataCell(Text(user.role)),
        DataCell(
          Icon(
            user.isActive ? Icons.check_circle : Icons.cancel,
            color: user.isActive ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => onEdit(user),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(user.id!),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}
