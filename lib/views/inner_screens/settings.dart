import 'dart:ui';


import 'package:brevity/views/inner_screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:brevity/controller/cubit/user_profile/user_profile_cubit.dart';
import 'package:brevity/controller/cubit/user_profile/user_profile_state.dart';
import 'package:brevity/controller/services/auth_service.dart';
import 'package:brevity/models/user_model.dart';
import 'package:brevity/views/common_widgets/common_appbar.dart';
import 'package:share_plus/share_plus.dart';
import '../../controller/cubit/theme/theme_cubit.dart';
import '../../controller/cubit/theme/theme_state.dart';
import '../../controller/services/notification_service.dart';
import '../../models/theme_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _particleAnimationController;
  final UserProfileCubit _userProfileCubit = UserProfileCubit();
  bool _reminderEnabled = false;
  String _reminderTime = '09:00';
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _particleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _particleAnimationController.addListener(() {
      setState(() {});
    });

    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    final enabled = await _notificationService.isReminderEnabled();
    final time = await _notificationService.getReminderTime();
    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = time;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleAnimationController.dispose();
    _userProfileCubit.close();
    super.dispose();
  }

  void _showLanguageDialog() {
    final themeCubit = context.read<ThemeCubit>();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeCubit.currentTheme.primaryColor.withAlpha(50),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Language',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 15),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLanguageOption('English'),
                        _buildLanguageOption('Spanish'),
                        _buildLanguageOption('French'),
                        _buildLanguageOption('German'),
                        _buildLanguageOption('Hindi'),
                        _buildLanguageOption('Chinese'),
                        _buildLanguageOption('Japanese'),
                        _buildLanguageOption('Russian'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    final isSelected = _selectedLanguage == language;
    final theme = Theme.of(context);
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? themeState.currentTheme.primaryColor.withAlpha((0.1 * 255).toInt())
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              language,
              style: TextStyle(
                color: isSelected
                    ? themeState.currentTheme.primaryColor
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? Icon(
              Icons.check_circle,
              color: themeState.currentTheme.primaryColor,
            )
                : null,
            onTap: () {
              setState(() => _selectedLanguage = language);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _showThemeColorPicker() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: themeState.currentTheme.primaryColor.withAlpha(50),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select Theme Color',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      alignment: WrapAlignment.center,
                      children: AppTheme.availableThemes.map((appTheme) {
                        final isSelected =
                            themeState.currentTheme.name == appTheme.name;
                        return GestureDetector(
                          onTap: () {
                            context.read<ThemeCubit>().changeTheme(
                              appTheme.copyWith(
                                isDarkMode:
                                themeState.currentTheme.isDarkMode,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: appTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: appTheme.primaryColor.withAlpha(100),
                                  blurRadius: isSelected ? 12 : 5,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? Icon(
                              Icons.check,
                              color: theme.colorScheme.onPrimary,
                            )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: themeState.currentTheme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteProfile() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withAlpha(50),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color.fromARGB(255, 198, 48, 37),
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Profile',
                  style: TextStyle(
                    color: Color.fromARGB(255, 198, 48, 37),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete your profile? This action cannot be undone.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 198, 48, 37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Delete'),
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

  void _showTimePickerDialog() {
    final theme = Theme.of(context);
    final themeCubit = context.read<ThemeCubit>();

    final timeParts = _reminderTime.split(':');
    final currentHour = int.parse(timeParts[0]);
    final currentMinute = int.parse(timeParts[1]);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeCubit.currentTheme.primaryColor.withAlpha(50),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set Reminder Time',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Container(
                  height: 200,
                  child: Row(
                    children: [
                      // Hour picker
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Hour',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 40,
                                diameterRatio: 1.5,
                                perspective: 0.003,
                                onSelectedItemChanged: (index) {
                                  final hour = index.toString().padLeft(2, '0');
                                  final minute = _reminderTime.split(':')[1];
                                  setState(() {
                                    _reminderTime = '$hour:$minute';
                                  });
                                },
                                controller: FixedExtentScrollController(
                                  initialItem: currentHour,
                                ),
                                childDelegate: ListWheelChildBuilderDelegate(
                                  builder: (context, index) {
                                    if (index < 0 || index > 23) return null;
                                    return Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        index.toString().padLeft(2, '0'),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: index == currentHour
                                              ? themeCubit.currentTheme.primaryColor
                                              : theme.colorScheme.onSurface,
                                          fontWeight: index == currentHour
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Minute picker
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Minute',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 40,
                                diameterRatio: 1.5,
                                perspective: 0.003,
                                onSelectedItemChanged: (index) {
                                  final minute = (index * 5).toString().padLeft(2, '0');
                                  final hour = _reminderTime.split(':')[0];
                                  setState(() {
                                    _reminderTime = '$hour:$minute';
                                  });
                                },
                                controller: FixedExtentScrollController(
                                  initialItem: (currentMinute / 5).round(),
                                ),
                                childDelegate: ListWheelChildBuilderDelegate(
                                  builder: (context, index) {
                                    if (index < 0 || index > 11) return null;
                                    final minute = index * 5;
                                    return Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        minute.toString().padLeft(2, '0'),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: minute == currentMinute
                                              ? themeCubit.currentTheme.primaryColor
                                              : theme.colorScheme.onSurface,
                                          fontWeight: minute == currentMinute
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _notificationService.setReminderTime(_reminderTime);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reminder time set to $_reminderTime'),
                              backgroundColor: themeCubit.currentTheme.primaryColor,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeCubit.currentTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save'),
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

  Future<void> _toggleReminderEnabled(bool enabled) async {
    if (enabled) {
      // Request permissions first
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission is required for reminders'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    await _notificationService.setReminderEnabled(enabled);
    setState(() {
      _reminderEnabled = enabled;
    });

    if (mounted) {
      final message = enabled
          ? 'Daily reminders enabled for $_reminderTime'
          : 'Daily reminders disabled';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: enabled ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => _userProfileCubit,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<UserProfileCubit, UserProfileState>(
              builder: (context, state) {
                if (state.status == UserProfileStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == UserProfileStatus.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.errorMessage}',
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: theme.colorScheme.surface.withAlpha((0.85 * 255).toInt()),
                      expandedHeight: 220,
                      pinned: true,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: ParticlesHeader(
                          title: "",
                          themeColor: themeState.currentTheme.primaryColor,
                          particleAnimation: _particleAnimationController,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      themeState.currentTheme.primaryColor,
                                      Colors.purpleAccent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeState
                                          .currentTheme.primaryColor
                                          .withAlpha(125),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                    'https://a0.anyrgb.com/pngimg/1140/162/user-profile-login-avatar-heroes-user-blue-icons-circle-symbol-logo-thumbnail.png',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.user?.displayName ?? 'User',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.user?.email ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        FadeTransition(
                          opacity: _animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(_animation),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding:
                                    const EdgeInsets.fromLTRB(20, 8, 0, 8),
                                    child: Text(
                                      'Settings',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildSectionHeader(
                                  'Profile',
                                  themeState.currentTheme.primaryColor,
                                ),
                                _buildAnimatedCard(
                                  child: _buildListTile(
                                    icon: Icons.person,
                                    title: 'Edit Profile',
                                    subtitle: 'Update your personal information',
                                    themeColor: themeState.currentTheme.primaryColor,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ProfileScreen(),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildSectionHeader(
                                  'Appearance',
                                  themeState.currentTheme.primaryColor,
                                ),
                                _buildAnimatedCard(
                                  child: _buildSwitchTile(
                                    icon: Icons.dark_mode,
                                    title: 'Dark Mode',
                                    value: themeState.currentTheme.isDarkMode,
                                    themeColor: themeState.currentTheme.primaryColor,
                                    onChanged: (val) => context
                                        .read<ThemeCubit>()
                                        .toggleDarkMode(val),
                                  ),
                                ),
                                _buildAnimatedCard(
                                  child: _buildListTile(
                                    icon: Icons.color_lens,
                                    title: 'App Theme',
                                    subtitle: 'Change app accent color',
                                    themeColor: themeState.currentTheme.primaryColor,
                                    trailingWidget: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: themeState.currentTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: themeState
                                                .currentTheme.primaryColor
                                                .withAlpha((0.4 * 255).toInt()),
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: _showThemeColorPicker,
                                  ),
                                ),
                                _buildSectionHeader(
                                  'Preferences',
                                  themeState.currentTheme.primaryColor,
                                ),
                                _buildAnimatedCard(
                                  child: _buildSwitchTile(
                                    icon: Icons.notifications_active,
                                    title: 'Push Notifications',
                                    themeColor: themeState.currentTheme.primaryColor,
                                    value: _notificationsEnabled,
                                    onChanged: (val) =>
                                        setState(() => _notificationsEnabled = val),
                                  ),
                                ),
                                _buildAnimatedCard(
                                  child: _buildSwitchTile(
                                    icon: Icons.bookmark_add_outlined,
                                    title: 'Daily Bookmark Reminder',
                                    themeColor: themeState.currentTheme.primaryColor,
                                    value: _reminderEnabled,
                                    onChanged: _toggleReminderEnabled,
                                  ),
                                ),
                                _buildAnimatedCard(
                                  child: _buildListTile(
                                    icon: Icons.schedule,
                                    title: 'Reminder Time',
                                    subtitle: _reminderTime,
                                    themeColor: themeState.currentTheme.primaryColor,
                                    onTap: _reminderEnabled ? _showTimePickerDialog : null,
                                  ),
                                ),
                                _buildAnimatedCard(
                                  child: _buildListTile(
                                    icon: Icons.language,
                                    title: 'Language',
                                    subtitle: _selectedLanguage,
                                    themeColor: themeState.currentTheme.primaryColor,
                                    onTap: _showLanguageDialog,
                                  ),
                                ),
                                _buildSectionHeader(
                                  'App',
                                  themeState.currentTheme.primaryColor,
                                ),
                                _buildAnimatedCard(
                                  child: _buildListTile(
                                    icon: Icons.share,
                                    title: 'Share App',
                                    subtitle: 'Tell your friends about us',
                                    themeColor: themeState.currentTheme.primaryColor,
                                    onTap: () => Share.share(
                                      'Hey! I\'m using this amazing app. You can try it too! 📲\n\nDownload here: https://play.google.com/store/apps/details?id=com.placeholder',
                                    ),
                                  ),
                                ),
                                _buildAnimatedCard(
                                  child: _buildListTile(
                                    icon: Icons.star_rate,
                                    title: 'Rate App',
                                    subtitle: 'Leave feedback on the store',
                                    themeColor: themeState.currentTheme.primaryColor,
                                    onTap: () {},
                                  ),
                                ),
                                _buildSectionHeader(
                                  'Contact',
                                  themeState.currentTheme.primaryColor,
                                ),
                                _buildAnimatedCard(
                                  child: _buildListTile(
                                    icon: Icons.contact_mail,
                                    title: 'Contact Us',
                                    subtitle: 'Get in touch with support',
                                    themeColor: themeState.currentTheme.primaryColor,
                                    onTap: () => context.push('/contactUs'),
                                  ),
                                ),
                                _buildAnimatedCard(
                                  child: _buildListTile(
                                    icon: Icons.info,
                                    title: 'About Us',
                                    subtitle: 'Learn more about us',
                                    themeColor: themeState.currentTheme.primaryColor,
                                    onTap: () {
                                      context.push('/aboutUs');
                                    },
                                  ),
                                ),
                                _buildSectionHeader(
                                  'Account',
                                  themeState.currentTheme.primaryColor,
                                ),
                                _buildAnimatedCard(
                                  child: _buildListTile(
                                    icon: Icons.logout,
                                    title: 'Log Out',
                                    subtitle: 'See you again soon',
                                    themeColor: themeState.currentTheme.primaryColor,
                                    titleColor: themeState.currentTheme.primaryColor,
                                    onTap: () {
                                      AuthService().signOut().then((value) {
                                        if (context.mounted) {
                                          context.go('/splash');
                                        }
                                      });
                                    },
                                  ),
                                ),
                                _buildAnimatedCard(
                                  color: Colors.red.withAlpha((0.1 * 255).toInt()),
                                  child: _buildListTile(
                                    icon: Icons.delete_forever,
                                    iconColor: Colors.red,
                                    title: 'Delete Profile',
                                    titleColor: Colors.red,
                                    subtitle: 'Permanently erase your data',
                                    themeColor: Colors.red,
                                    onTap: _confirmDeleteProfile,
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context,
      UserModel? user,
      Color themeColor,
      ) {
    if (user == null) return;
    final theme = Theme.of(context);

    final TextEditingController displayNameController =
    TextEditingController(text: user.displayName);

    showDialog(
      context: context,
      builder: (BuildContext context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withAlpha(50),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Profile',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: displayNameController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    labelStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.onSurface.withAlpha((0.3 * 255).toInt())),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: themeColor),
                    ),
                    prefixIcon: Icon(Icons.person, color: themeColor),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: themeColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: themeColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<UserProfileCubit>().updateProfile(
                            displayName: displayNameController.text,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Save'),
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

  Widget _buildAnimatedCard({required Widget child, Color? color}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: themeColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor.withAlpha((0.5 * 255).toInt()), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required Color themeColor,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    return SwitchListTile.adaptive(
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: themeColor.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: themeColor, size: 24),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium,
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Color themeColor,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? themeColor).withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? themeColor, size: 24),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(color: titleColor),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
        ),
      )
          : null,
      trailing: trailingWidget ??
          Icon(Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()), size: 16),
      onTap: onTap,
    );
  }
}
