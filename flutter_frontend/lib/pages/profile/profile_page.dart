import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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
      print('Loading profile...');
      final profile = await getUserProfile();
      print('Profile loaded: $profile');
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 5),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Profile not found",
                style: TextStyle(
                  color: isDark ? AppColors.gray100 : AppColors.gray800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.gray100 : AppColors.gray800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Main Content Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.gray200,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.gray100 : AppColors.gray800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Profile Card
                  _buildProfileCard(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.gray200,
        ),
        color: isDark ? AppColors.darkBg : AppColors.gray50,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.gray100 : AppColors.gray800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.md,
                      children: [
                        Text(
                          _profile!.username,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.gray400 : AppColors.gray500,
                          ),
                        ),
                        Container(
                          height: 14,
                          width: 1,
                          color: isDark ? AppColors.gray700 : AppColors.gray300,
                        ),
                        Text(
                          _profile!.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.gray400 : AppColors.gray500,
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
                  foregroundColor: isDark ? AppColors.gray400 : AppColors.gray700,
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.gray300,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ],
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
      );
      
      try {
        final result = await updateUserProfile(updatedData);
        widget.onSave(result);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: Colors.green[600],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.gray100 : AppColors.gray800,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? AppColors.gray400 : AppColors.gray500,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Update your details to keep your profile up-to-date.',
                  style: TextStyle(
                    color: isDark ? AppColors.gray400 : AppColors.gray500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.gray100 : AppColors.gray800,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // First Name and Last Name Row
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        label: 'First Name',
                        controller: _firstNameController,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _buildFormField(
                        label: 'Last Name',
                        controller: _lastNameController,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Email and Username Row
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        label: 'Email Address',
                        controller: _emailController,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _buildFormField(
                        label: 'Username',
                        controller: _usernameController,
                        isDark: isDark,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(height: AppSpacing.lg),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.gray300,
                        ),
                        foregroundColor: isDark ? AppColors.gray400 : AppColors.gray700,
                      ),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton(
                      onPressed: _saving ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.gray300 : AppColors.gray700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: label,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            filled: readOnly,
            fillColor: readOnly
              ? (isDark ? AppColors.darkBg : AppColors.gray50)
              : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.gray200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.gray200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.gray100 : AppColors.gray900,
          ),
        ),
      ],
    );
  }
}

