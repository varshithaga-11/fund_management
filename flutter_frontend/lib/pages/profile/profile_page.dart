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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title (Breadcrumb equivalent)
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Main Content Area (Matches the white container in UserProfiles.tsx)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // UserMetaCard equivalent
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_profile!.firstName.isEmpty ? _profile!.username : _profile!.firstName} ${_profile!.lastName}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 12,
                                    children: [
                                      Text(
                                        _profile!.username,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Container(
                                        height: 14,
                                        width: 1,
                                        color: Colors.grey[300],
                                      ),
                                      Text(
                                        _profile!.email,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Edit Button
                            OutlinedButton.icon(
                              onPressed: _showEditDialog,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
       backgroundColor: Colors.white,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
       child: Container(
         width: 600,
         constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
         padding: const EdgeInsets.all(32),
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
                       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: Colors.black,
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
                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
                 ),
                 const SizedBox(height: 32),
                 
                 const Text('Personal Information', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                 const SizedBox(height: 24),
                 
                 Row(
                   children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('First Name', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                           const SizedBox(height: 8),
                           TextFormField(
                             controller: _firstNameController,
                             decoration: InputDecoration(
                               hintText: 'First Name',
                               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                               enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                             ),
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Last Name', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                           const SizedBox(height: 8),
                           TextFormField(
                             controller: _lastNameController,
                             decoration: InputDecoration(
                               hintText: 'Last Name',
                               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                               enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 20),
                 Row(
                   children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                           const SizedBox(height: 8),
                           TextFormField(
                             controller: _emailController,
                             decoration: InputDecoration(
                               hintText: 'Email Address',
                               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                               enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                             ),
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Username', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                           const SizedBox(height: 8),
                           TextFormField(
                             controller: _usernameController,
                             readOnly: true,
                             decoration: InputDecoration(
                               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                               fillColor: const Color(0xFFF9FAFB),
                               filled: true,
                               enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
                 
                 const SizedBox(height: 48),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     TextButton(
                       onPressed: () => Navigator.of(context).pop(),
                       style: TextButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                         foregroundColor: Colors.grey[700],
                       ),
                       child: const Text('Close'),
                     ),
                     const SizedBox(width: 12),
                     ElevatedButton(
                       onPressed: _saving ? null : _handleSubmit,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blue[600],
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         elevation: 0,
                       ),
                       child: _saving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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

