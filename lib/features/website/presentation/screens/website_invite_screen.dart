import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../groups/domain/repositories/invite_repository.dart';
import '../../../groups/domain/models/invite.dart';

class WebsiteInviteScreen extends ConsumerStatefulWidget {
  final String inviteToken;
  
  const WebsiteInviteScreen({super.key, required this.inviteToken});

  @override
  ConsumerState<WebsiteInviteScreen> createState() => _WebsiteInviteScreenState();
}

class _WebsiteInviteScreenState extends ConsumerState<WebsiteInviteScreen> {
  bool _isLoading = true;
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
          _error = 'Couldn\'t verify this invitation.';
          _isLoading = false;
        });
      }
    }
  }

  void _downloadApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download SplitNest'),
        content: const Text('In production, this will take you to the App Store or Google Play.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/splitnest_logo_final.png',
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 48),
                
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "You're invited!",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Image.asset(
                        'assets/icons/icon_house_3d.png',
                        height: 140,
                      ),
                      const SizedBox(height: 32),
                      
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
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: colors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (_invite != null) ...[
                        Text(
                          'Join ${_invite!.nestName}',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colors.textWhite,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          '${_invite!.memberCount ?? 1} Members',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _downloadApp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Download SplitNest',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        
                      ],
                    ],
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
