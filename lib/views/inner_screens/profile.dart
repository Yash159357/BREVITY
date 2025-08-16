import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brevity/controller/cubit/theme/theme_cubit.dart';
import 'package:brevity/controller/cubit/user_profile/user_profile_cubit.dart';
import 'package:brevity/controller/cubit/user_profile/user_profile_state.dart';
import 'package:brevity/views/common_widgets/common_appbar.dart';
import 'package:brevity/models/theme_model.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleAnimationController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();

    _particleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    context.read<UserProfileCubit>().loadUserProfile();
  }

  @override
  void dispose() {
    _particleAnimationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final userProfileCubit = context.read<UserProfileCubit>();
    userProfileCubit
        .updateProfile(
      displayName: _nameController.text,
      profileImage: _selectedImage, // Pass the selected image
    )
        .then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $error')),
      );
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, state) {
            final user = state.user;
            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Take Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Choose from Gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  if (_selectedImage != null || _hasProfileImage(state, user))
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Remove Photo'),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedImage = null;
                        });
                        // Remove the profile picture completely
                        final userProfileCubit = context.read<UserProfileCubit>();
                        userProfileCubit.removeProfileImage().then((_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile photo removed successfully')),
                          );
                        }).catchError((error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error removing photo: $error')),
                          );
                        });
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.watch<ThemeCubit>().currentTheme;
    final theme = Theme.of(context);

    return BlocConsumer<UserProfileCubit, UserProfileState>(
      listener: (context, state) {
        if (state.status == UserProfileStatus.loaded && state.user != null) {
          _nameController.text = state.user!.displayName;
          _emailController.text = state.user!.email;
        }
      },
      builder: (context, state) {
        if (state.status == UserProfileStatus.loading) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Center(
              child: CircularProgressIndicator(
                color: currentTheme.primaryColor,
              ),
            ),
          );
        }

        if (state.status == UserProfileStatus.error) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Center(child: Text('Error: ${state.errorMessage}')),
          );
        }

        final user = state.user;
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: theme.colorScheme.surface.withAlpha((0.85 * 255).toInt()),
                expandedHeight: 90,
                pinned: true,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: ParticlesHeader(
                    title: "Profile Settings",
                    themeColor: currentTheme.primaryColor,
                    particleAnimation: _particleAnimationController,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            GestureDetector(
                              onTap: _showImageOptions,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: _hasProfileImage(state, user)
                                        ? Colors.transparent
                                        : currentTheme.primaryColor.withAlpha((0.2 * 255).toInt()),
                                    backgroundImage: _getProfileImage(state, user),
                                    child: !_hasProfileImage(state, user)
                                        ? Text(
                                      user?.displayName.isNotEmpty == true
                                          ? user!.displayName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: currentTheme.primaryColor,
                                      ),
                                    )
                                        : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: currentTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: theme.colorScheme.surface, width: 2)
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        _buildProfileField(
                          icon: Icons.person,
                          label: 'Full Name',
                          controller: _nameController,
                          currentTheme: currentTheme,
                        ),
                        const SizedBox(height: 20),
                        _buildProfileField(
                          icon: Icons.email,
                          label: 'Email Address',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: false,
                          currentTheme: currentTheme,
                        ),
                        const SizedBox(height: 30),
                        _buildProfileOption(
                          icon: Icons.verified_user,
                          title: 'Email Verified',
                          subtitle: user?.emailVerified == true ? 'Yes' : 'No',
                          onTap: () {},
                          currentTheme: currentTheme,
                        ),
                        _buildProfileOption(
                          icon: Icons.calendar_today,
                          title: 'Account Created',
                          subtitle: user?.createdAt != null
                              ? '${user!.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                              : 'Unknown',
                          onTap: () {},
                          currentTheme: currentTheme,
                        ),
                        _buildProfileOption(
                          icon: Icons.update,
                          title: 'Last Updated',
                          subtitle: user?.updatedAt != null
                              ? '${user!.updatedAt!.day}/${user.updatedAt!.month}/${user.updatedAt!.year}'
                              : 'Never',
                          onTap: () {},
                          currentTheme: currentTheme,
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentTheme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasProfileImage(UserProfileState state, user) {
    return _selectedImage != null ||
        state.localProfileImage != null ||
        (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty);
  }

  ImageProvider? _getProfileImage(UserProfileState state, user) {
    // Priority: selected image -> local image -> network image
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    if (state.localProfileImage != null) {
      return FileImage(state.localProfileImage!);
    }
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      return NetworkImage(user.profileImageUrl!);
    }
    return null;
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required AppTheme currentTheme,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: currentTheme.primaryColor),
          labelText: label,
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppTheme currentTheme,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: currentTheme.primaryColor),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()))),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: currentTheme.primaryColor,
        ),
        onTap: onTap,
      ),
    );
  }
}
