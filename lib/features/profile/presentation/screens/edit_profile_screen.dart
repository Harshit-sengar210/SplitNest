import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/premium_image_selector.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  String? _selectedImage;
  bool _isUploadingImage = false;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    
    _nameController = TextEditingController(text: user?.displayName ?? 'SplitNester');
    _usernameController = TextEditingController(text: user?.username ?? '@splitnester');
    _emailController = TextEditingController(text: user?.email ?? 'contact@splitnester.app');
    _phoneController = TextEditingController(text: user?.phone ?? '+1 234 567 8900');
    _bioController = TextEditingController(text: user?.bio ?? 'Love traveling and splitting bills seamlessly.');
    _selectedImage = user?.photoUrl;

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    void listener() => setState(() {});
    _nameController.addListener(listener);
    _usernameController.addListener(listener);
    _emailController.addListener(listener);
    _phoneController.addListener(listener);
    _bioController.addListener(listener);
  }

  ImageProvider? _getImageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (path.startsWith('data:image')) {
      try {
        final base64Str = path.contains(',') ? path.split(',')[1] : path;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(path);
  }

  void _handleImageUpload() async {
    final result = await PremiumImageSelector.show(
      context,
      title: 'EDIT PROFILE PHOTO',
    );
    
    if (result != null) {
      setState(() => _isUploadingImage = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _selectedImage = result;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture selected successfully!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: const Color(0xFF7B61FF),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF))),
      );
      
      try {
        final user = ref.read(authNotifierProvider).user;
        if (user != null) {
          await ref.read(authNotifierProvider.notifier).updateProfile(
            userId: user.id,
            fullName: _nameController.text,
            username: _usernameController.text,
            phone: _phoneController.text,
            bio: _bioController.text,
            profileImage: _selectedImage,
          );
        } else {
          await Future.delayed(const Duration(milliseconds: 800));
        }
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          context.pop(); // Go back to profile
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final user = ref.read(authNotifierProvider).user;
    return _nameController.text != (user?.displayName ?? 'SplitNester') ||
           _usernameController.text != (user?.username ?? '@splitnester') ||
           _emailController.text != (user?.email ?? 'contact@splitnester.app') ||
           _phoneController.text != (user?.phone ?? '+1 234 567 8900') ||
           _bioController.text != (user?.bio ?? 'Love traveling and splitting bills seamlessly.') ||
           _selectedImage != user?.photoUrl;
  }

  @override
  Widget build(BuildContext context) {
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
                  // App Bar Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_hasUnsavedChanges) {
                              _confirmDiscard();
                            } else {
                              context.pop();
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
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
                        const SizedBox(width: 16),
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Inputs List
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Profile Picture Section
                            Center(
                              child: GestureDetector(
                                onTap: _handleImageUpload,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  transform: Matrix4.identity()..scale(_isUploadingImage ? 0.95 : 1.0),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(color: const Color(0xFF7B61FF), width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF7B61FF).withOpacity(0.15),
                                              blurRadius: 16,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 400),
                                            child: _isUploadingImage
                                                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF)))
                                                : _selectedImage != null
                                                    ? Image(
                                                        key: ValueKey(_selectedImage),
                                                        image: _getImageProvider(_selectedImage)!,
                                                        fit: BoxFit.cover,
                                                        width: 120,
                                                        height: 120,
                                                      )
                                                    : Container(
                                                        key: const ValueKey('fallback'),
                                                        color: const Color(0xFFEDE9FA),
                                                        child: Center(
                                                          child: Text(
                                                            _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'S',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              color: const Color(0xFF7B61FF),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 36,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                          ),
                                        ),
                                      ),
                                      if (!_isUploadingImage)
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF7B61FF),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2.5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Tap to change photo',
                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. Input Fields (22px card styling)
                            PremiumTextField(
                              controller: _nameController,
                              labelText: 'Full Name',
                              prefixIcon: Icons.person_rounded,
                              iconColor: const Color(0xFF7B61FF),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            PremiumTextField(
                              controller: _usernameController,
                              labelText: 'Username',
                              prefixIcon: Icons.alternate_email_rounded,
                              iconColor: const Color(0xFF6CA8FF),
                            ),
                            const SizedBox(height: 12),
                            PremiumTextField(
                              controller: _emailController,
                              labelText: 'Email Address',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_rounded,
                              iconColor: const Color(0xFFA78BFA),
                            ),
                            const SizedBox(height: 12),
                            PremiumTextField(
                              controller: _phoneController,
                              labelText: 'Phone Number',
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_rounded,
                              iconColor: const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 12),
                            PremiumTextField(
                              controller: _bioController,
                              labelText: 'Bio',
                              prefixIcon: Icons.info_rounded,
                              iconColor: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Pinned bottom actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        PremiumButton(
                          text: 'SAVE CHANGES',
                          isLoading: false,
                          onPressed: _handleSave,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              if (_hasUnsavedChanges) {
                                _confirmDiscard();
                              } else {
                                context.pop();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              foregroundColor: const Color(0xFF1F2937),
                            ),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2),
                            ),
                          ),
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

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Discard Changes?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
        content: Text('You have unsaved changes. Are you sure you want to go back?', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Editing', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7B61FF), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              context.pop(); // Go back
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: Text('Discard', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// LOCAL WIDGETS
// ==========================================

Widget _build3DIcon(IconData icon, Color primaryColor) {
  return Container(
    width: 38,
    height: 38,
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
    this.hintText = '',
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
      ],
    );
  }
}
