import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/invite_repository.dart';
import '../../domain/models/invite.dart';
import '../../../../core/services/pending_invite_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class NestInvitationScreen extends ConsumerStatefulWidget {
  final String inviteToken;
  
  const NestInvitationScreen({super.key, required this.inviteToken});

  @override
  ConsumerState<NestInvitationScreen> createState() => _NestInvitationScreenState();
}

class _NestInvitationScreenState extends ConsumerState<NestInvitationScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  Invite? _invite;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvite();
  }

  Future<void> _loadInvite() async {
    try {
      final repo = ref.read(inviteRepositoryProvider);
      final invite = await repo.getInvite(widget.inviteToken);
      
      if (invite != null) {
        final user = fb.FirebaseAuth.instance.currentUser;
        if (user != null) {
          final nestDoc = await FirebaseFirestore.instance.collection('nests').doc(invite.nestId).get();
          if (nestDoc.exists) {
            final memberIds = List<dynamic>.from(nestDoc.data()!['memberIds'] ?? []);
            if (memberIds.contains(user.uid)) {
              if (mounted) {
                context.go('/groups/${invite.nestId}');
                return;
              }
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _invite = invite;
          _isLoading = false;
          if (invite == null) {
            _error = 'This invitation is no longer available.';
          } else if (invite.status == InviteStatus.expired || invite.expiresAt.isBefore(DateTime.now())) {
            _error = 'This invitation has expired.';
          } else if (invite.status == InviteStatus.revoked) {
            _error = 'This invitation is no longer available.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Couldn\'t verify this invitation. Check your connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleJoinPressed() async {
    final authState = ref.read(authNotifierProvider);
    
    // If not logged in, save token and redirect to login
    if (authState.user == null) {
      final pendingInviteService = ref.read(pendingInviteServiceProvider);
      await pendingInviteService.savePendingInvite(widget.inviteToken);
      
      if (mounted) {
        context.push('/login');
      }
      return;
    }

    // User is logged in, try to join
    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final repo = ref.read(inviteRepositoryProvider);
      await repo.joinNestFromInvite(widget.inviteToken);
      
      // Clear pending invite
      final pendingInviteService = ref.read(pendingInviteServiceProvider);
      await pendingInviteService.clearPendingInvite();

      // Refresh auth state so activeNestId reflects the new nest in memory
      await ref.read(authNotifierProvider.notifier).refreshUser();

      if (mounted && _invite != null) {
        // Navigate directly to the specific Nest that was just joined
        context.go('/groups/${_invite!.nestId}');
      } else if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _error = msg;
          _isJoining = false;
        });
        
        // Already a member → just go to that nest
        if (msg == 'You are already a member of this Nest.' && _invite != null) {
          context.go('/groups/${_invite!.nestId}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.user != null;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/splitnest_logo_final.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                
                // Content Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 3D Illustration
                      Image.asset(
                        'assets/icons/icon_house_3d.png',
                        height: 120,
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        "You're invited to join",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryGold),
                          ),
                        )
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                               Icon(Icons.error_outline, color: colors.error, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: colors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_invite != null) ...[
                        Text(
                          _invite!.nestName,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.textWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.primaryGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               Icon(
                                Icons.people_alt_rounded,
                                size: 16,
                                color: colors.primaryGold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_invite!.memberCount ?? 1} members',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primaryGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isJoining ? null : _handleJoinPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isJoining
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    isAuthenticated ? 'Join Nest' : 'Login to Join',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        
                        if (!isAuthenticated) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: TextButton(
                              onPressed: () {
                                final pendingInviteService = ref.read(pendingInviteServiceProvider);
                                pendingInviteService.savePendingInvite(widget.inviteToken);
                                context.push('/register');
                              },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Create Account',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primaryGold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                TextButton(
                  onPressed: () {
                    // Cancel invitation flow
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/welcome');
                    }
                  },
                  child: Text(
                    'Not Now',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
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
}
