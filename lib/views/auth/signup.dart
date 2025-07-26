import 'package:flutter/material.dart';
import 'package:brevity/controller/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.goToLoginPage});
  final void Function() goToLoginPage;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;
  late AnimationController _strengthController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _strengthAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _strengthController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _strengthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _strengthController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();

    // Start floating animation and repeat
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    _strengthController.dispose();
    _floatingController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Password strength checker with animation
  void _checkPasswordStrength(String value) {
    PasswordStrength newStrength;

    if (value.length < 6) {
      newStrength = PasswordStrength.weak;
    } else if (value.length < 8) {
      newStrength = PasswordStrength.medium;
    } else {
      bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
      bool hasDigits = value.contains(RegExp(r'[0-9]'));
      bool hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      newStrength =
          (hasUppercase && hasDigits && hasSpecial)
              ? PasswordStrength.strong
              : PasswordStrength.medium;
    }

    if (newStrength != _passwordStrength) {
      setState(() => _passwordStrength = newStrength);
      _strengthController.reset();
      _strengthController.forward();
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      await AuthService.register(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
      );
      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // Handle error with animated snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Signup failed: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 4, 16, 54),
            Color.fromARGB(255, 20, 25, 78),
            Color.fromARGB(255, 27, 52, 105),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Animated Logo with floating effect
                  AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: AnimatedBuilder(
                          animation: _floatingAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatingAnimation.value),
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(
                                        255,
                                        26,
                                        175,
                                        255,
                                      ).withOpacity(0.4),
                                      blurRadius: 25,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 70,
                                  backgroundColor: Colors.transparent,
                                  child: Image.asset('assets/logos/logo.png'),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Animated Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 26, 167, 255),
                                Colors.white,
                              ],
                            ).createShader(bounds),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Animated Name Field
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedTextFormField(
                        controller: _nameController,
                        hintText: 'Full Name',
                        icon: Icons.person,
                        delay: 200,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          if (value.length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Animated Email Field
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedTextFormField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        icon: Icons.email,
                        delay: 400,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Animated Password Field
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedTextFormField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock,
                        obscureText: _obscurePassword,
                        delay: 600,
                        onChanged: _checkPasswordStrength,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Animated Password Strength Indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedPasswordStrengthIndicator(
                      strength: _passwordStrength,
                      animation: _strengthAnimation,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Animated Sign Up Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        isLoading: _isLoading,
                        text: 'SIGN UP',
                        delay: 800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Animated Google Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedGoogleButton(
                        onPressed: () {},
                        delay: 1000,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Animated Login Link
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: TextButton(
                        onPressed: widget.goToLoginPage,
                        child: const Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Poppins',
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 26, 167, 255),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum PasswordStrength { weak, medium, strong }

// Enhanced animated password strength indicator
class AnimatedPasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  final Animation<double> animation;

  const AnimatedPasswordStrengthIndicator({
    super.key,
    required this.strength,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    String strengthText;
    Color textColor;
    Color barColor;
    double strengthLevel;

    switch (strength) {
      case PasswordStrength.weak:
        strengthText = 'Weak';
        textColor = Colors.red;
        barColor = Colors.red;
        strengthLevel = 0.33;
        break;
      case PasswordStrength.medium:
        strengthText = 'Medium';
        textColor = Colors.orange;
        barColor = Colors.orange;
        strengthLevel = 0.66;
        break;
      case PasswordStrength.strong:
        strengthText = 'Strong';
        textColor = const Color(0xFF00F5D4);
        barColor = const Color(0xFF00F5D4);
        strengthLevel = 1.0;
        break;
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text indicator
            Transform.scale(
              scale: 1.0 + (animation.value * 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Strength: ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    strengthText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Animated progress bar
            Container(
              width: 150,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white24,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: strengthLevel * animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: barColor,
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Reuse the same AnimatedTextFormField, AnimatedButton, and AnimatedGoogleButton
// from the login screen (they're identical)

// Custom animated text form field widget
class AnimatedTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final int delay;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;

  const AnimatedTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    required this.delay,
    this.validator,
    this.onChanged,
  });

  @override
  State<AnimatedTextFormField> createState() => _AnimatedTextFormFieldState();
}

class _AnimatedTextFormFieldState extends State<AnimatedTextFormField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Delayed animation start
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(10),
             boxShadow:
                 _isFocused
                      ? [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            26,
                            175,
                            255,
                          ).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
           ),
            child: Focus(
              onFocusChange: (focused) {
                setState(() => _isFocused = focused);
              },
              child: TextFormField(
                controller: widget.controller,
                obscureText: widget.obscureText,
                onChanged: widget.onChanged,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Poppins',
                  ),
                  prefixIcon: Icon(widget.icon, color: Colors.white54),
                  suffixIcon: widget.suffixIcon,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 26, 175, 255),
                      width: 2,
                    ),
                  ),
                ),
                validator: widget.validator,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom animated button widget
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final int delay;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.text,
    required this.delay,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(10),
             gradient: const LinearGradient(
               colors: [
                Color.fromARGB(255, 9, 121, 232),
                Color.fromARGB(255, 26, 175, 255),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(
                  255,
                  26,
                  175,
                  255,
                ).withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
             backgroundColor: Colors.transparent,
             shadowColor: Colors.transparent,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(10),
             ),
             minimumSize: const Size(double.infinity, 50),
           ),
            child:
                widget.isLoading
                   ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                         width: 20,
                         height: 20,
                         child: CircularProgressIndicator(
                           color: Colors.white,
                           strokeWidth: 2,
                         ),
                       ),
                        const SizedBox(width: 12),
                        Text(
                          'Creating Account...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                     ],
                   )
                   : Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

// Custom animated Google button
class AnimatedGoogleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final int delay;

  const AnimatedGoogleButton({
    super.key,
    required this.onPressed,
    required this.delay,
  });

  @override
  State<AnimatedGoogleButton> createState() => _AnimatedGoogleButtonState();
}

class _AnimatedGoogleButtonState extends State<AnimatedGoogleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: OutlinedButton.icon(
            icon: Image.asset('assets/logos/google.png', width: 24),
            label: const Text(
              'Continue with Google',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color.fromARGB(255, 26, 175, 255)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: widget.onPressed,
          ),
        );
      },
    );
  }
}