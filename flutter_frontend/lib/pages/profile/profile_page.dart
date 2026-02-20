import 'package:flutter/material.dart';
import 'profile_api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfileData? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await getUserProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _showEditDialog() {
    if (_profile == null) return;

    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        currentProfile: _profile!,
        onSave: (updatedProfile) async {
          setState(() => _profile = updatedProfile);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        body: Center(child: Text("Profile not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Breadcrumb Area could be here
            
            // Profile Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_profile!.firstName.isEmpty ? _profile!.username : _profile!.firstName} ${_profile!.lastName}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _profile!.username,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Container(
                                    height: 14,
                                    width: 1,
                                    color: Colors.grey[400],
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  Text(
                                    _profile!.email,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showEditDialog,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final UserProfileData currentProfile;
  final Function(UserProfileData) onSave;

  const EditProfileDialog({
    super.key,
    required this.currentProfile,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.currentProfile.firstName);
    _lastNameController = TextEditingController(text: widget.currentProfile.lastName);
    _emailController = TextEditingController(text: widget.currentProfile.email);
    _usernameController = TextEditingController(text: widget.currentProfile.username);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);
      
      final updatedData = widget.currentProfile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        // Username usually read-only in this context based on frontend
      );
      
      try {
        final result = await updateUserProfile(updatedData);
        widget.onSave(result);
        if (mounted) {
           Navigator.of(context).pop();
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Profile updated successfully')),
           );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: Container(
         width: 600,
         padding: const EdgeInsets.all(24),
         child: Form(
           key: _formKey,
           child: SingleChildScrollView(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(
                       'Edit Profile',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     IconButton(
                       icon: const Icon(Icons.close),
                       onPressed: () => Navigator.of(context).pop(),
                     ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Text(
                   'Update your details to keep your profile up-to-date.',
                   style: TextStyle(color: Colors.grey[600]),
                 ),
                 const SizedBox(height: 24),
                 
                 const Text('Personal Information', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
                 
                 Row(
                   children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('First Name'),
                           const SizedBox(height: 8),
                           TextFormField(
                             controller: _firstNameController,
                             decoration: const InputDecoration(border: OutlineInputBorder()),
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Last Name'),
                           const SizedBox(height: 8),
                           TextFormField(
                             controller: _lastNameController,
                             decoration: const InputDecoration(border: OutlineInputBorder()),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 Row(
                   children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Email Address'),
                           const SizedBox(height: 8),
                           TextFormField(
                             controller: _emailController,
                             decoration: const InputDecoration(border: OutlineInputBorder()),
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Username'),
                           const SizedBox(height: 8),
                           TextFormField(
                             controller: _usernameController,
                             readOnly: true,
                             decoration: const InputDecoration(
                               border: OutlineInputBorder(),
                               fillColor: Color(0xFFF3F4F6),
                               filled: true,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
                 
                 const SizedBox(height: 32),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     OutlinedButton(
                       onPressed: () => Navigator.of(context).pop(),
                       child: const Text('Close'),
                     ),
                     const SizedBox(width: 12),
                     ElevatedButton(
                       onPressed: _saving ? null : _handleSubmit,
                       child: _saving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save Changes'),
                     ),
                   ],
                 ),
               ],
             ),
           ),
         ),
       ),
    );
  }
}
