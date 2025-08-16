import 'dart:io';
import 'dart:math' as math;

import 'package:brevity/controller/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../common_widgets/auth_header.dart';

// Enhanced Palette (same as login)
const Color bgStart = Color(0xFF070B14);
const Color bgEnd = Color(0xFF0E1624);

const Color primaryA = Color(0xFF3D4DFF);
const Color primaryB = Color(0xFF29C0FF);

const Color panelTop = Color(0xFF0F1724);
const Color panelBottom = Color(0xFF111827);
const Color mutedText = Color(0xFF9AA8BF);
const Color successColor = Color(0xFF10B981);
const Color warningColor = Color(0xFFF59E0B);
const Color errorColor = Color(0xFFEF4444);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.goToLoginPage});

  final VoidCallback goToLoginPage;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  // Form state
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Validation states
  bool _nameValid = false;
  bool _emailValid = false;
  bool _passwordValid = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  // Animations
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _shakeController;

  late final Animation<double> _floatAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
    _floatAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _floatController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);

    // Start entrance animations
    Future.delayed(
      const Duration(milliseconds: 160),
      () => _fadeController.forward(),
    );
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _slideController.forward(),
    );

    // Add listeners for real-time validation
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateName() {
    final name = _nameController.text;
    final isValid = name.isNotEmpty && name.length >= 2;
    if (_nameValid != isValid) {
      setState(() {
        _nameValid = isValid;
        _nameError =
            name.isEmpty
                ? null
                : (isValid ? null : 'Name must be at least 2 characters');
      });
    }
  }

  void _validateEmail() {
    final email = _emailController.text;
    final isValid =
        email.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    if (_emailValid != isValid) {
      setState(() {
        _emailValid = isValid;
        _emailError =
            email.isEmpty
                ? null
                : (isValid ? null : 'Please enter a valid email');
      });
    }
  }

  void _validatePassword() {
    final password = _passwordController.text;
    final isValid = password.length >= 8;

    // Password strength check
    PasswordStrength newStrength;
    if (password.length < 6) {
      newStrength = PasswordStrength.weak;
    } else if (password.length < 8) {
      newStrength = PasswordStrength.medium;
    } else {
      bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
      bool hasDigits = password.contains(RegExp(r'[0-9]'));
      bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      newStrength =
          (hasUppercase && hasDigits && hasSpecial)
              ? PasswordStrength.strong
              : PasswordStrength.medium;
    }

    if (_passwordValid != isValid || _passwordStrength != newStrength) {
      setState(() {
        _passwordValid = isValid;
        _passwordStrength = newStrength;
        _passwordError =
            password.isEmpty
                ? null
                : (isValid ? null : 'Password must be at least 8 characters');
      });
    }
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
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: errorColor,
        ),
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
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: panelBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.camera_alt, color: primaryB),
                      title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.photo_library, color: primaryB),
                      title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),
                    if (_selectedImage != null)
                      ListTile(
                        leading: Icon(Icons.delete, color: errorColor),
                        title: const Text('Remove Photo', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          _removeImage();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    HapticFeedback.lightImpact();
  }

  bool get _canSignup =>
      _nameValid && _emailValid && _passwordValid && !_isLoading;

  Future<void> _handleSignup() async {
    HapticFeedback.lightImpact();

    if (!_formKey.currentState!.validate()) {
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      await AuthService().signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        userName: _nameController.text,
        context: context,
        profileImage: _selectedImage, // Pass the selected image
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();

      // Show success state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: successColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Account created! Check your email to verify.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1F2937),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) => _shakeController.reset());

      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.split('Exception: ').last;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: errorColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signup failed: $errorMessage',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1F2937),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: bgStart,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(size)),
          SafeArea(child: _buildPortraitLayout(size)),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(Size size) {
    return Column(
      children: [
        AnimatedHeader(
          title: 'Create Account',
          subtitle: 'Join the Brevity community',
          logoAssetPath: 'assets/logos/Brevity_white.png',
          screenSize: size,
          isLandscape: false,
        ),
        _buildFormPanel(),
      ],
    );
  }

  Widget _buildBackground(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgStart, bgEnd],
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, _) {
              final t = _floatAnim.value;
              final yOsc = math.sin(t * 2 * math.pi) * 20;
              final xOsc = math.cos(t * 2 * math.pi) * 12;
              return Positioned(
                left: -40 + xOsc,
                top: 80 + yOsc,
                child: Transform.rotate(
                  angle: 0.15 * math.sin(t * 2 * math.pi),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.4),
                        radius: 1.2,
                        colors: [
                          primaryA.withAlpha((0.08 * 255).toInt()),
                          primaryB.withAlpha((0.02 * 255).toInt()),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_floatAnim, _pulseAnim]),
            builder: (context, _) {
              final f = _floatAnim.value;
              final p = _pulseAnim.value;
              final y = math.cos(f * 2 * math.pi + math.pi / 3) * 15;
              final x = math.sin(f * 2 * math.pi + math.pi / 3) * 10;
              return Positioned(
                right: -20 + x,
                top: 140 + y,
                child: Transform.scale(
                  scale: p,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(80),
                      gradient: RadialGradient(
                        center: const Alignment(0.4, -0.2),
                        radius: 1.0,
                        colors: [
                          primaryB.withAlpha((0.06 * 255).toInt()),
                          primaryA.withAlpha((0.01 * 255).toInt()),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ...List.generate(6, (i) {
            return AnimatedBuilder(
              animation: _floatAnim,
              builder: (context, _) {
                final offset = (i * math.pi / 3);
                final x =
                    50 + math.cos(_floatAnim.value * 2 * math.pi + offset) * 30;
                final y =
                    200 +
                    math.sin(_floatAnim.value * 2 * math.pi + offset) * 20;
                final opacity =
                    (math.sin(_floatAnim.value * 2 * math.pi + offset) + 1) *
                    0.02;

                return Positioned(
                  left: x,
                  top: y,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primaryB.withAlpha((opacity * 255).toInt()),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return Expanded(
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (context, child) {
          final shakeOffset = math.sin(_shakeAnim.value * math.pi * 8) * 2;
          return Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [panelTop, panelBottom],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, // was 24
                  vertical: 20, // was 24
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      LinearProgressIndicator(
                        value:
                            (_nameValid && _emailValid && _passwordValid)
                                ? 1.0
                                : ((_nameValid ? 1 : 0) +
                                        (_emailValid ? 1 : 0) +
                                        (_passwordValid ? 1 : 0)) /
                                    3,
                        backgroundColor: Colors.white.withAlpha(
                          (0.1 * 255).toInt(),
                        ),
                        valueColor: AlwaysStoppedAnimation(primaryB),
                        minHeight: 2,
                      ),

                      const SizedBox(height: 20), // was 24
                      // Profile Image Picker
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name field - takes remaining space
                          Expanded(
                            child: EnhancedTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              hintText: 'Enter your full name',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              isValid: _nameValid,
                              errorText: _nameError,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Name is required';
                                if (v.length < 2) return 'Name must be at least 2 characters';
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Profile picture
                          GestureDetector(
                            onTap: _showImageOptions,
                            child: Container(
                              margin: const EdgeInsets.only(top: 20),
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha((0.05 * 255).toInt()),
                                border: Border.all(
                                  color: _selectedImage != null ? primaryB : Colors.white.withAlpha((0.1 * 255).toInt()),
                                  width: 2,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? Stack(
                                children: [
                                  ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: GestureDetector(
                                      onTap: _removeImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: errorColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                                  : Icon(
                                Icons.add_a_photo_rounded,
                                color: primaryB,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14), // was 16

                      EnhancedTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hintText: 'Enter your email',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        isValid: _emailValid,
                        errorText: _emailError,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(v)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14), // was 16

                      EnhancedTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Create a strong password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        isValid: _passwordValid,
                        errorText: _passwordError,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              key: ValueKey(_obscurePassword),
                              color: _passwordValid ? successColor : primaryA,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12), // was 12
                      // Password strength indicator
                      PasswordStrengthIndicator(strength: _passwordStrength),

                      const SizedBox(height: 24), // was 24
                      // Signup button
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: EnhancedButton(
                            onPressed: _canSignup ? _handleSignup : null,
                            isLoading: _isLoading,
                            text: 'CREATE ACCOUNT',
                            enabled: _canSignup,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16), // was 20
                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withAlpha((0.1 * 255).toInt()),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ), // was 16
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withAlpha((0.1 * 255).toInt()),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14), // was 16
                      // Social login buttons
                      Row(
                        children: [
                          Expanded(
                            child: EnhancedSocialButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                // Google signup logic
                              },
                              icon: Icons.g_mobiledata_rounded,
                              text: 'Google',
                              iconColor: const Color(0xFFDB4437),
                              imagePath: 'assets/logos/google.png',
                            ),
                          ),
                          const SizedBox(width: 10), // was 12
                          Expanded(
                            child: EnhancedSocialButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                // Apple signup logic
                              },
                              icon: Icons.apple_rounded,
                              text: 'Apple',
                              iconColor: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20), // was 24
                      // Login link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.goToLoginPage();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ), // reduced
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: primaryB,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20), // was 24
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -------------------- Enhanced Components --------------------

enum PasswordStrength { weak, medium, strong }

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthIndicator({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    String strengthText;
    Color textColor;
    Color barColor;
    double strengthLevel;

    switch (strength) {
      case PasswordStrength.weak:
        strengthText = 'Weak';
        textColor = errorColor;
        barColor = errorColor;
        strengthLevel = 0.33;
        break;
      case PasswordStrength.medium:
        strengthText = 'Medium';
        textColor = warningColor;
        barColor = warningColor;
        strengthLevel = 0.66;
        break;
      case PasswordStrength.strong:
        strengthText = 'Strong';
        textColor = successColor;
        barColor = successColor;
        strengthLevel = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength:',
              style: TextStyle(
                color: mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withAlpha((0.1 * 255).toInt()),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: strengthLevel,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: barColor,
                boxShadow: [
                  BoxShadow(
                    color: barColor.withAlpha((0.3 * 255).toInt()),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Enhanced TextField (same as login)
class EnhancedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isValid;
  final String? errorText;

  const EnhancedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.isValid = false,
    this.errorText,
  });

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField>
    with SingleTickerProviderStateMixin {
  bool _focused = false;
  bool _hasContent = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasContent = widget.controller.text.isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() => _hasContent = hasContent);
      if (hasContent) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  Color get _getBorderColor {
    if (widget.errorText != null && _hasContent) return errorColor;
    if (widget.isValid && _hasContent) return successColor;
    if (_focused) return primaryA;
    if (_hasContent) return const Color(0xFF374151);
    return const Color(0xFF1F2937);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) {
            setState(() => _focused = focused);
            if (focused) {
              HapticFeedback.selectionClick();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF0B131A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor,
                width: _focused ? 2 : 1,
              ),
              boxShadow:
                  _focused
                      ? [
                        BoxShadow(
                          color: primaryA.withAlpha((0.1 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              validator: widget.validator,
              keyboardType: widget.keyboardType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withAlpha((0.4 * 255).toInt()),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Icon(
                      widget.icon,
                      color: Color.lerp(
                        _focused ? primaryA : Colors.white54,
                        widget.isValid && _hasContent
                            ? successColor
                            : (_focused ? primaryA : Colors.white54),
                        _animation.value,
                      ),
                      size: 20,
                    );
                  },
                ),
                suffixIcon:
                    widget.suffixIcon ??
                    (_hasContent && widget.isValid
                        ? Icon(
                          Icons.check_circle_rounded,
                          color: successColor,
                          size: 20,
                        )
                        : null),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        if (widget.errorText != null && _hasContent)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: errorColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// Enhanced Button (same as login)
class EnhancedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final bool enabled;

  const EnhancedButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.text,
    this.enabled = true,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.enabled && !widget.isLoading
              ? (_) => _animController.forward()
              : null,
      onTapUp:
          widget.enabled && !widget.isLoading
              ? (_) => _animController.reverse()
              : null,
      onTapCancel:
          widget.enabled && !widget.isLoading
              ? () => _animController.reverse()
              : null,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient:
                    widget.enabled && !widget.isLoading
                        ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryA, primaryB],
                        )
                        : LinearGradient(
                          colors: [
                            Colors.grey.withAlpha((0.3 * 255).toInt()),
                            Colors.grey.withAlpha((0.2 * 255).toInt()),
                          ],
                        ),
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    widget.enabled && !widget.isLoading
                        ? [
                          BoxShadow(
                            color: primaryA.withAlpha(
                              ((0.3 + (_glowAnim.value * 0.2)) * 255).toInt(),
                            ),
                            blurRadius: 12 + (_glowAnim.value * 8),
                            offset: const Offset(0, 6),
                          ),
                        ]
                        : null,
              ),
              child: ElevatedButton(
                onPressed:
                    widget.enabled && !widget.isLoading
                        ? widget.onPressed
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    widget.isLoading
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Creating Account...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        )
                        : Text(
                          widget.text,
                          style: TextStyle(
                            color:
                                widget.enabled ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Enhanced Social Button (same as login)
class EnhancedSocialButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String text;
  final Color iconColor;
  final String? imagePath;

  const EnhancedSocialButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
    required this.iconColor,
    this.imagePath,
  });

  @override
  State<EnhancedSocialButton> createState() => _EnhancedSocialButtonState();
}

class _EnhancedSocialButtonState extends State<EnhancedSocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnim = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onTapUp: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      onTapCancel: () {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_hoverAnim.value * 0.02),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF0D1117),
                  const Color(0xFF161B22),
                  _hoverAnim.value,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      Color.lerp(
                        Colors.white.withAlpha((0.08 * 255).toInt()),
                        Colors.white.withAlpha((0.15 * 255).toInt()),
                        _hoverAnim.value,
                      )!,
                  width: 1,
                ),
                boxShadow:
                    _isHovered
                        ? [
                          BoxShadow(
                            color: widget.iconColor.withAlpha(
                              (0.1 * 255).toInt(),
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.imagePath != null
                        ? Image.asset(
                          widget.imagePath!,
                          fit: BoxFit.contain,
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) {
                            return Icon(
                              widget.icon,
                              color: widget.iconColor,
                              size: 24,
                            );
                          },
                        )
                        : Icon(widget.icon, color: widget.iconColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
}
