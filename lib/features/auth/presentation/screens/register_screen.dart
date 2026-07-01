import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/validation_utils.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState!.validate()) {
      ref.read(authNotifierProvider.notifier).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
    }
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

            // Main Content Area
            SafeArea(
              child: Column(
                children: [
                  // Custom App Bar with back button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Register Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Header Title & Subtitle
                            Text(
                              'Create Account 🚀',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join SplitNest to start splitting expenses easily.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 36),

                            // 2. Input Fields
                            PremiumTextField(
                              controller: _nameController,
                              labelText: 'Full Name',
                              hintText: 'John Doe',
                              prefixIcon: Icons.person_rounded,
                              iconColor: const Color(0xFF7B61FF), // Purple
                              validator: ValidationUtils.validateDisplayName,
                              enabled: !authState.isLoading,
                            ),
                            const SizedBox(height: 20),
                            PremiumTextField(
                              controller: _emailController,
                              labelText: 'Email Address',
                              hintText: 'name@example.com',
                              prefixIcon: Icons.email_rounded,
                              iconColor: const Color(0xFF6CA8FF), // Blue
                              keyboardType: TextInputType.emailAddress,
                              validator: ValidationUtils.validateEmail,
                              enabled: !authState.isLoading,
                            ),
                            const SizedBox(height: 20),
                            PremiumTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              hintText: 'Min 6 characters',
                              prefixIcon: Icons.lock_rounded,
                              iconColor: const Color(0xFFA78BFA), // Lavender
                              isPassword: true,
                              validator: ValidationUtils.validatePassword,
                              enabled: !authState.isLoading,
                            ),
                            const SizedBox(height: 20),
                            PremiumTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              prefixIcon: Icons.lock_clock_rounded,
                              iconColor: const Color(0xFF10B981), // Green
                              isPassword: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              enabled: !authState.isLoading,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _onRegisterPressed(),
                            ),
                            const SizedBox(height: 36),

                            // 3. Register Button
                            PremiumButton(
                              text: 'SIGN UP',
                              isLoading: authState.isLoading,
                              onPressed: _onRegisterPressed,
                            ),
                            const SizedBox(height: 32),

                            // 4. Footer link to sign in
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: authState.isLoading ? null : () => context.pop(),
                                  child: Text(
                                    'Sign In',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF7B61FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
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

// ==========================================
// LOCAL CUSTOM PREMIUM WIDGETS
// ==========================================

Widget _build3DIcon(IconData icon, Color primaryColor) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.9),
          primaryColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.35),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.4),
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
                    ? Colors.red.shade100.withValues(alpha: 0.5)
                    : (_hasFocus 
                        ? const Color(0xFF7B61FF).withValues(alpha: 0.08) 
                        : Colors.black.withValues(alpha: 0.03)),
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
              errorStyle: const TextStyle(height: 0.1, color: Colors.transparent),
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
                Color(0xFF7B61FF),
                Color(0xFF6CA8FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B61FF).withValues(alpha: 0.35),
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
          top: 100,
          left: -30,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, floatAnimation.value * 12),
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA78BFA).withValues(alpha: 0.22),
                    const Color(0xFFA78BFA).withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Floating Sphere 2 (Bottom Right)
        Positioned(
          bottom: 120,
          right: -40,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -floatAnimation.value * 15),
                child: child,
              );
            },
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6CA8FF).withValues(alpha: 0.18),
                    const Color(0xFF6CA8FF).withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Floating Dot
        Positioned(
          top: 250,
          right: 40,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(floatAnimation.value * 5, -floatAnimation.value * 8),
                child: child,
              );
            },
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B61FF).withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
