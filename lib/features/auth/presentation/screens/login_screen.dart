import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validation_utils.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_signin_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animController;
  late AnimationController _floatController;
  late Animation<double> _bgFade;
  late Animation<Offset> _panelSlide;
  late List<Animation<double>> _staggeredFades;
  late List<Animation<Offset>> _staggeredSlides;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    _panelSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    _staggeredFades = [];
    _staggeredSlides = [];
    for (int i = 0; i < 7; i++) {
      final start = 0.2 + (i * 0.08);
      final end = (start + 0.25).clamp(0.0, 1.0);
      _staggeredFades.add(Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Interval(start, end, curve: Curves.easeOut)),
      ));
      _staggeredSlides.add(Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Interval(start, end, curve: Curves.easeOutCubic)),
      ));
    }

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _floatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      ref.read(authNotifierProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _onGoogleLoginPressed() {
    ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  Widget _buildStaggeredItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _staggeredFades[index].value,
          child: SlideTransition(
            position: _staggeredSlides[index],
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen to error notifications
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F3FF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Background Floating Shapes
            _BackgroundShapes(floatAnimation: _floatAnimation),
            
            // Scrollable Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Index 0: Hero Illustration
                      _buildStaggeredItem(0, _HeroIllustration(floatAnimation: _floatAnimation)),
                      const SizedBox(height: 24),
                      
                      // Index 1: Welcome Text
                      _buildStaggeredItem(1, Column(
                        children: [
                          Text(
                            'Welcome Back 👋',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1F2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Split expenses. Live easy.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )),
                      const SizedBox(height: 32),
                      
                      // Index 2: Email Field
                      _buildStaggeredItem(2, PremiumTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: Icons.email_rounded,
                        iconColor: const Color(0xFF7B61FF), // Purple
                        keyboardType: TextInputType.emailAddress,
                        validator: ValidationUtils.validateEmail,
                        enabled: !authState.isLoading,
                      )),
                      const SizedBox(height: 20),
                      
                      // Index 3: Password Field
                      _buildStaggeredItem(3, Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PremiumTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icons.lock_rounded,
                            iconColor: const Color(0xFF6CA8FF), // Blue
                            isPassword: true,
                            validator: ValidationUtils.validatePassword,
                            enabled: !authState.isLoading,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _onLoginPressed(),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: authState.isLoading ? null : () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF7B61FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(height: 12),
                      
                      // Index 4: Sign In Button
                      _buildStaggeredItem(4, PremiumButton(
                        text: 'SIGN IN',
                        isLoading: authState.isLoading,
                        onPressed: _onLoginPressed,
                      )),
                      const SizedBox(height: 28),
                      
                      // Index 5: OR Separator
                      _buildStaggeredItem(5, Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1.5)),
                        ],
                      )),
                      const SizedBox(height: 24),
                      
                      // Index 6: Google Button & Footer
                      _buildStaggeredItem(6, Column(
                        children: [
                          GoogleSignInButton(
                            isLoading: authState.isLoading,
                            onPressed: _onGoogleLoginPressed,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: authState.isLoading ? null : () => context.push('/register'),
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF7B61FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM PREMIUM WIDGETS
// ==========================================

Widget _build3DIcon(IconData icon, Color primaryColor) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        colors: [
          primaryColor.withOpacity(0.9),
          primaryColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.35),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.35),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
      border: Border.all(
        color: Colors.white.withOpacity(0.4),
        width: 1,
      ),
    ),
    child: Center(
      child: Icon(
        icon,
        color: Colors.white,
        size: 18,
      ),
    ),
  );
}

class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final Color iconColor;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool enabled;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    required this.iconColor,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _obscureText = true;
  bool _hasFocus = false;
  String? _errorText;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasError
                  ? Colors.red.shade400
                  : (_hasFocus ? const Color(0xFF7B61FF) : const Color(0xFFE5E7EB)),
              width: _hasFocus || hasError ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: hasError
                    ? Colors.red.shade100.withOpacity(0.5)
                    : (_hasFocus 
                        ? const Color(0xFF7B61FF).withOpacity(0.08) 
                        : Colors.black.withOpacity(0.03)),
                blurRadius: _hasFocus || hasError ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 4),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.isPassword ? _obscureText : false,
            enabled: widget.enabled,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            cursorColor: const Color(0xFF7B61FF),
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            validator: (value) {
              if (widget.validator != null) {
                final result = widget.validator!(value);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _errorText != result) {
                    setState(() {
                      _errorText = result;
                    });
                  }
                });
                return result;
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: widget.labelText,
              labelStyle: GoogleFonts.plusJakartaSans(
                color: hasError
                    ? Colors.red.shade400
                    : (_hasFocus ? const Color(0xFF7B61FF) : const Color(0xFF9CA3AF)),
                fontWeight: FontWeight.w600,
              ),
              hintText: widget.hintText,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: const TextStyle(height: 0.1, color: Colors.transparent), // hide default error UI
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _build3DIcon(widget.prefixIcon, widget.iconColor),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              _errorText!,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PremiumButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  const PremiumButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> with SingleTickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.isLoading ? null : _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _buttonController.reverse(),
      child: ScaleTransition(
        scale: _buttonScale,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7B61FF), // #7B61FF
                Color(0xFF6CA8FF), // #6CA8FF
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B61FF).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.text,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundShapes extends StatelessWidget {
  final Animation<double> floatAnimation;

  const _BackgroundShapes({required this.floatAnimation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating Sphere 1 (Top Left)
        Positioned(
          top: 80,
          left: -20,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, floatAnimation.value * 12),
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA78BFA).withOpacity(0.25),
                    const Color(0xFFA78BFA).withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Floating Sphere 2 (Middle Right)
        Positioned(
          top: 350,
          right: -30,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -floatAnimation.value * 15),
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6CA8FF).withOpacity(0.2),
                    const Color(0xFF6CA8FF).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Floating Dot 1
        Positioned(
          top: 220,
          right: 60,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(floatAnimation.value * 6, floatAnimation.value * 8),
                child: child,
              );
            },
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B61FF).withOpacity(0.15),
              ),
            ),
          ),
        ),
        // Floating Dot 2
        Positioned(
          bottom: 150,
          left: 40,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-floatAnimation.value * 8, floatAnimation.value * 5),
                child: child,
              );
            },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6CA8FF).withOpacity(0.2),
              ),
            ),
          ),
        ),
        // Floating Coin 1 (Top Right)
        Positioned(
          top: 120,
          right: 30,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -floatAnimation.value * 10),
                child: child,
              );
            },
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/3d_coins.png',
                width: 50,
                height: 50,
              ),
            ),
          ),
        ),
        // Floating Coin 2 (Bottom Left)
        Positioned(
          bottom: 240,
          left: -10,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, floatAnimation.value * 14),
                child: child,
              );
            },
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/3d_coins.png',
                width: 60,
                height: 60,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  final Animation<double> floatAnimation;

  const _HeroIllustration({required this.floatAnimation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Glow Blob Behind (Purple)
          Positioned(
            top: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7B61FF).withOpacity(0.3),
                    const Color(0xFF7B61FF).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Glow Blob Behind (Blue)
          Positioned(
            top: 40,
            left: 100,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6CA8FF).withOpacity(0.25),
                    const Color(0xFF6CA8FF).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // Coin Stack (Left/Bottom)
          Positioned(
            left: 40,
            bottom: 20,
            child: AnimatedBuilder(
              animation: floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, floatAnimation.value * 12),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/3d_coins.png',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Blue Wallet (Right/Bottom)
          Positioned(
            right: 50,
            bottom: 10,
            child: AnimatedBuilder(
              animation: floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -floatAnimation.value * 10),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/3d_blue_wallet.png',
                width: 75,
                height: 75,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Main Center Piece: People Sharing Expenses (Central/Top)
          AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, floatAnimation.value * -6),
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/3d_people.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
