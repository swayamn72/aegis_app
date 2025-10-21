import 'package:flutter/material.dart';
import 'services/api_service.dart';

class AegisSignupPage extends StatefulWidget {
  const AegisSignupPage({super.key});

  @override
  State<AegisSignupPage> createState() => _AegisSignupPageState();
}

class _AegisSignupPageState extends State<AegisSignupPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;
  Map<String, String> _errors = {};

  late AnimationController _particleController;
  late AnimationController _mascotController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _particleController.dispose();
    _mascotController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() {
      _errors = {};
    });

    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _errors['username'] = 'Username is required';
      });
      return false;
    } else if (_usernameController.text.trim().length < 3) {
      setState(() {
        _errors['username'] = 'Username must be at least 3 characters';
      });
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errors['email'] = 'Email is required';
      });
      return false;
    } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(_emailController.text)) {
      setState(() {
        _errors['email'] = 'Please enter a valid email';
      });
      return false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errors['password'] = 'Password is required';
      });
      return false;
    } else if (_passwordController.text.length < 8) {
      setState(() {
        _errors['password'] = 'Password must be at least 8 characters';
      });
      return false;
    }

    return true;
  }

  void _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.signup(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['error'] == true) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Signup failed'),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate to login page
        Navigator.pushReplacementNamed(context, '/login');
        // Or pop back to login: Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: const Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF78350f), // amber-950
              Color(0xFF7c2d12), // orange-950
              Color(0xFF7f1d1d), // red-950
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(80, (index) {
              return AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return Positioned(
                    left: (index * 47.3) % MediaQuery.of(context).size.width,
                    top: ((index * 31.7) % MediaQuery.of(context).size.height +
                        _particleController.value * 50) %
                        MediaQuery.of(context).size.height,
                    child: Opacity(
                      opacity: 0.3,
                      child: Container(
                        width: 2,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFFfbbf24), // amber-400
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFfbbf24).withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Animated gradient blobs
            Positioned(
              top: -100,
              left: -100,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.3 + (_glowController.value * 0.2),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFf97316).withOpacity(0.3),
                            const Color(0xFFef4444).withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 900;

                  if (isWideScreen) {
                    return Row(
                      children: [
                        Expanded(child: _buildLeftColumn()),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildSignupForm(),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            _buildMascot(size: 60),
                            const SizedBox(height: 24),
                            _buildSignupForm(),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMascot(size: 80),
            const SizedBox(height: 40),
            const Text(
              'Join the',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFfb923c), // orange-400
                  Color(0xFFef4444), // red-500
                  Color(0xFFf59e0b), // amber-500
                ],
              ).createShader(bounds),
              child: const Text(
                'Elite',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Create your Aegis profile and compete with the world's best gamers. Your legendary journey starts here.",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFFd1d5db),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeature(Icons.check_circle, 'Free Forever', Colors.green),
                const SizedBox(width: 16),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                _buildFeature(Icons.shield, 'Secure & Private', const Color(0xFF60a5fa)),
                const SizedBox(width: 16),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                _buildFeature(Icons.games, 'All Games', const Color(0xFFf97316)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMascot({required double size}) {
    return AnimatedBuilder(
      animation: _mascotController,
      builder: (context, child) {
        final float = _mascotController.value * 10;
        return Transform.translate(
          offset: Offset(0, float - 5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: size * 1.5,
                height: size * 1.8,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFfb923c).withOpacity(0.4),
                      const Color(0xFFef4444).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
              // Main body
              Container(
                width: size,
                height: size * 1.25,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFfb923c), // orange-400
                      Color(0xFFef4444), // red-500
                      Color(0xFFd97706), // amber-600
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(size / 2),
                    bottom: Radius.circular(size / 5),
                  ),
                  border: Border.all(
                    color: const Color(0xFFfdba74), // orange-300
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFf97316).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Inner glow effects
                    Positioned(
                      top: size * 0.1,
                      left: size * 0.2,
                      child: Container(
                        width: size * 0.5,
                        height: size * 0.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFfde047).withOpacity(0.3),
                        ),
                      ),
                    ),
                    // Eyes
                    Positioned(
                      top: size * 0.35,
                      left: size * 0.2,
                      child: _buildEye(size * 0.12),
                    ),
                    Positioned(
                      top: size * 0.35,
                      right: size * 0.2,
                      child: _buildEye(size * 0.12),
                    ),
                    // Mouth
                    Positioned(
                      top: size * 0.55,
                      left: size * 0.3,
                      child: Container(
                        width: size * 0.4,
                        height: size * 0.08,
                        decoration: BoxDecoration(
                          color: const Color(0xFFfef3c7).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(size),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Left antenna
              Positioned(
                top: size * 0.3,
                left: -size * 0.15,
                child: Transform.rotate(
                  angle: 0.8,
                  child: Container(
                    width: size * 0.15,
                    height: size * 0.4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFfdba74),
                          Color(0xFFfca5a5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                ),
              ),
              // Right antenna
              Positioned(
                top: size * 0.4,
                right: -size * 0.15,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Container(
                    width: size * 0.15,
                    height: size * 0.4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFfdba74),
                          Color(0xFFfca5a5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEye(double size) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFfde047), // yellow-300
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFfbbf24).withOpacity(0.8),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignupForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ready to dominate the leaderboards?',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Username Field
            _buildTextField(
              controller: _usernameController,
              icon: Icons.person,
              hintText: 'Choose a username',
              error: _errors['username'],
            ),
            const SizedBox(height: 20),

            // Email Field
            _buildTextField(
              controller: _emailController,
              icon: Icons.email,
              hintText: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              error: _errors['email'],
            ),
            const SizedBox(height: 20),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              icon: Icons.lock,
              hintText: 'Create a strong password',
              isPassword: true,
              showPassword: _showPassword,
              onTogglePassword: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
              error: _errors['password'],
            ),
            const SizedBox(height: 24),

            // Create Account Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? null
                        : const LinearGradient(
                      colors: [
                        Color(0xFFf97316), // orange-500
                        Color(0xFFef4444), // red-500
                        Color(0xFFf59e0b), // amber-500
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.grey.shade700.withOpacity(0.5),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or continue with',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.grey.shade700.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Social Login Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF5865F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Discord',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Login Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      color: Color(0xFFfb923c),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Footer
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade700.withOpacity(0.3),
                  ),
                ),
              ),
              child: const Text(
                '🔒 Your data is encrypted and secure • Join 10,000+ gamers',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !showPassword,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF111827).withOpacity(0.3),
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(icon, color: Colors.grey, size: 24),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: onTogglePassword,
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: error != null
                      ? const Color(0xFFef4444).withOpacity(0.5)
                      : Colors.grey.shade600.withOpacity(0.5),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: error != null
                      ? const Color(0xFFef4444).withOpacity(0.5)
                      : Colors.grey.shade600.withOpacity(0.5),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: error != null
                      ? const Color(0xFFef4444)
                      : const Color(0xFFf97316),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),
        ),
        if (error != null) _buildErrorMessage(error),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFef4444).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFFef4444).withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFef4444),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFef4444),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}