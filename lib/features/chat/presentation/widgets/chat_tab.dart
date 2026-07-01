import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../groups/domain/models/group.dart';
import '../providers/chat_provider.dart';
import '../../../../core/widgets/premium_image_selector.dart';
import '../widgets/chat_bubble.dart';
import '../../domain/models/message.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Scroll threshold: only auto-scroll when user is this many pixels from bottom
// ─────────────────────────────────────────────────────────────────────────────
const double _kScrollThreshold = 120.0;

class ChatTab extends ConsumerStatefulWidget {
  final Group group;
  final bool showAppBar;

  const ChatTab({
    super.key,
    required this.group,
    this.showAppBar = false,
  });

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Used to detect "new message arrived while user is near bottom"
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // chatMessagesProvider (StreamProvider) disposes its subscription
    // automatically when this widget leaves the tree — no manual cancel needed.
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Scroll helpers
  // ───────────────────────────────────────────────────────────────────────────

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    // With reverse:true, position 0 is the "bottom" (newest messages).
    return _scrollController.offset <= _kScrollThreshold;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0.0);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Send / attach
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Guard: ignore tap if already sending (notifier has its own lock too)
    final sendState = ref.read(chatSendProvider);
    if (sendState.isSending) return;

    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    final senderId = currentUser?.id ?? 'user_me';
    final senderName = currentUser?.displayName ?? 'You';
    final senderPhoto = currentUser?.photoUrl;

    final message = Message(
      // messageId intentionally left empty — Firestore generates the doc ID
      // in FirebaseChatRepository to prevent any risk of duplication.
      messageId: '',
      groupId: widget.group.id,
      senderId: senderId,
      senderName: senderName,
      senderPhoto: senderPhoto,
      message: text,
      messageType: 'text',
      createdAt: DateTime.now(),
    );

    // Optimistic scroll before the write so the UI feels instant
    _scrollToBottom();

    final success =
        await ref.read(chatSendProvider.notifier).sendMessage(message);

    if (success) {
      // Clear ONLY after the Firestore batch write succeeds
      _messageController.clear();
    } else {
      // Surface the error so the user knows the message was NOT sent
      if (mounted) {
        final err = ref.read(chatSendProvider).error ?? 'Failed to send message';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _sendImageMessage(String imageUrl) async {
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    final senderId = currentUser?.id ?? 'user_me';
    final senderName = currentUser?.displayName ?? 'You';
    final senderPhoto = currentUser?.photoUrl;

    final message = Message(
      messageId: '',
      groupId: widget.group.id,
      senderId: senderId,
      senderName: senderName,
      senderPhoto: senderPhoto,
      message: imageUrl,
      messageType: 'image',
      createdAt: DateTime.now(),
    );

    _scrollToBottom();
    await ref.read(chatSendProvider.notifier).sendMessage(message);
  }

  void _handleAttachFile() async {
    final result = await PremiumImageSelector.show(
      context,
      title: 'SELECT IMAGE',
    );
    if (result != null) {
      _sendImageMessage(result);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Edit / Delete (long-press context menu for own messages)
  // ───────────────────────────────────────────────────────────────────────────

  void _showMessageOptions(BuildContext context, Message msg) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? colors.card : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.accentBrown.withOpacity(isDark ? 0.2 : 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit
            if (!msg.isDeleted)
              ListTile(
                leading: Icon(Icons.edit_rounded, color: colors.primaryGold, size: 20),
                title: Text('Edit message',
                    style: TextStyle(color: colors.textWhite, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(msg);
                },
              ),
            // Delete
            if (!msg.isDeleted)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: colors.error, size: 20),
                title: Text('Delete message',
                    style: TextStyle(color: colors.error, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(msg);
                },
              ),
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: colors.textSecondary, size: 20),
              title: Text('Cancel',
                  style: TextStyle(color: colors.textSecondary)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Message msg) {
    final editController = TextEditingController(text: msg.message);
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Message',
            style: TextStyle(color: colors.textWhite, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: TextStyle(color: colors.textWhite),
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Edit your message...',
            hintStyle: TextStyle(color: colors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.accentBrown.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primaryGold, width: 1.5),
            ),
            filled: true,
            fillColor: colors.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != msg.message) {
                ref
                    .read(chatEditDeleteProvider.notifier)
                    .editMessage(widget.group.id, msg.messageId, newText);
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Message msg) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Message',
            style: TextStyle(color: colors.textWhite, fontWeight: FontWeight.bold)),
        content: Text('This message will be deleted for everyone.',
            style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ref
                  .read(chatEditDeleteProvider.notifier)
                  .deleteMessage(widget.group.id, msg.messageId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Date grouping
  // ───────────────────────────────────────────────────────────────────────────

  List<dynamic> _groupMessagesWithSeparators(List<Message> messages) {
    if (messages.isEmpty) return [];

    final List<dynamic> items = [];
    DateTime? lastDate;

    // messages is sorted DESCENDING by createdAt (newest first).
    // Loop backwards (oldest → newest) to insert date separators correctly.
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      final msgDate =
          DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);

      if (lastDate == null || msgDate != lastDate) {
        lastDate = msgDate;
        items.add(msgDate); // date separator
      }
      items.add(msg);
    }

    // Reverse because ListView has reverse:true (index 0 = bottom / newest)
    return items.reversed.toList();
  }

  String _getDateHeaderString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.id ?? 'user_me';
    final sendState = ref.watch(chatSendProvider);
    final colors = context.colors;

    // ── Smart auto-scroll via ref.listen ────────────────────────────────────
    // We listen here instead of in the data builder so we can access the
    // previous count without causing an extra rebuild.
    ref.listen<AsyncValue<List<Message>>>(
      chatMessagesProvider(widget.group.id),
      (previous, next) {
        next.whenData((messages) {
          final newCount = messages.length;
          if (newCount > _lastMessageCount && _isNearBottom) {
            // New message arrived and user is near the bottom → auto-scroll
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          }
          _lastMessageCount = newCount;
        });
      },
    );

    return Column(
      children: [
        if (widget.showAppBar) _buildAppBar(context),
        Expanded(
          child: ref.watch(chatMessagesProvider(widget.group.id)).when(
                data: (messages) {
                  final groupedItems = _groupMessagesWithSeparators(messages);

                  if (groupedItems.isEmpty && !sendState.isSending) {
                    return Center(
                      child: Text(
                        'Start the conversation!',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    );
                  }

                  final itemCount =
                      groupedItems.length + (sendState.isSending ? 1 : 0);

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    reverse: true,
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      // Typing / sending indicator at top of reversed list
                      if (sendState.isSending && index == 0) {
                        return _buildTypingIndicator(context);
                      }

                      final itemIndex =
                          sendState.isSending ? index - 1 : index;
                      final item = groupedItems[itemIndex];

                      if (item is DateTime) {
                        return _buildDateSeparator(context, item);
                      }

                      final msg = item as Message;
                      final isMe = msg.senderId == currentUserId ||
                          msg.senderId == 'user_me';

                      if (msg.messageType == 'system') {
                        return AnimatedMessageItem(
                          key: ValueKey(msg.messageId),
                          child: _buildSystemMessage(context, msg),
                        );
                      }

                      return AnimatedMessageItem(
                        key: ValueKey(
                            '${msg.messageId}_${msg.isEdited}_${msg.isDeleted}'),
                        child: GestureDetector(
                          onLongPress: isMe && !msg.isDeleted
                              ? () => _showMessageOptions(context, msg)
                              : null,
                          child: ChatBubble(
                            message: msg,
                            isMe: isMe,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(
                    child: CircularProgressIndicator(
                        color: colors.primaryGold)),
                error: (e, _) => Center(
                    child: Text(e.toString(),
                        style: TextStyle(color: colors.error))),
              ),
        ),
        _buildChatInputArea(sendState),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Sub-widgets
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? colors.card.withOpacity(0.65)
            : Colors.white.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : colors.accentBrown.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : colors.accentBrown.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : colors.accentBrown.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: colors.textWhite, size: 15),
                ),
              ),
              const SizedBox(width: 12),
              // Nest info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.group.name,
                      style: TextStyle(
                        color: colors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const PulsingOnlineDot(),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.group.members.length} members • active',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildMemberAvatars(widget.group.members),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAvatars(List<GroupMember> members) {
    const maxToShow = 3;
    final displayMembers = members.take(maxToShow).toList();
    final remainingCount = members.length - maxToShow;
    final colors = context.colors;

    return SizedBox(
      height: 32,
      width: (displayMembers.length * 20.0) + (remainingCount > 0 ? 30.0 : 0.0),
      child: Stack(
        children: [
          for (int i = 0; i < displayMembers.length; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.card, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: displayMembers[i].photoUrl != null &&
                          displayMembers[i].photoUrl!.isNotEmpty
                      ? NetworkImage(displayMembers[i].photoUrl!)
                      : null,
                  backgroundColor: colors.accentBrown,
                  child: displayMembers[i].photoUrl == null ||
                          displayMembers[i].photoUrl!.isEmpty
                      ? Text(
                          displayMembers[i].name.isNotEmpty
                              ? displayMembers[i].name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colors.primaryGold),
                        )
                      : null,
                ),
              ),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * 20.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.card, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.accentBrown,
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
    final label = _getDateHeaderString(date);
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : colors.accentBrown.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : colors.accentBrown.withOpacity(0.6),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context, Message message) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData iconData = Icons.info_outline_rounded;
    Color accentColor = colors.primaryGold;

    final text = message.message.toLowerCase();
    if (text.contains('added') || text.contains('joined')) {
      iconData = Icons.person_add_alt_1_rounded;
      accentColor = colors.softBronze;
    } else if (text.contains('expense')) {
      iconData = Icons.receipt_long_rounded;
      accentColor = colors.primaryGold;
    } else if (text.contains('settlement') ||
        text.contains('settled') ||
        text.contains('completed')) {
      iconData = Icons.handshake_rounded;
      accentColor = colors.success;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(isDark ? 0.25 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: accentColor, size: 15),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.9)
                      : colors.textWhite.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.primaryGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: const Radius.circular(4),
              ),
              border: Border.all(color: colors.primaryGold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: colors.primaryGold),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sending...',
                  style: TextStyle(
                    color: colors.primaryGold,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputArea(ChatSendState sendState) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colors.card.withOpacity(0.6)
            : Colors.white.withOpacity(0.85),
        border: Border(
          top: BorderSide(
            color: colors.accentBrown.withOpacity(isDark ? 0.15 : 0.4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon:
                  Icon(Icons.emoji_emotions_outlined, color: colors.textSecondary),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded,
                  color: colors.textSecondary),
              onPressed: _handleAttachFile,
            ),
            IconButton(
              icon: Icon(Icons.camera_alt_outlined, color: colors.textSecondary),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : colors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color:
                          colors.accentBrown.withOpacity(isDark ? 0.2 : 0.6)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: colors.textWhite, fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle:
                        TextStyle(color: colors.textMuted, fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sendState.isSending ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: sendState.isSending
                      ? null
                      : LinearGradient(
                          colors: [
                            colors.primaryGold,
                            colors.primaryGold.withBlue(220),
                          ],
                        ),
                  color: sendState.isSending
                      ? colors.textMuted.withOpacity(0.3)
                      : null,
                  shape: BoxShape.circle,
                  boxShadow: sendState.isSending
                      ? null
                      : [
                          BoxShadow(
                            color: colors.primaryGold.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: sendState.isSending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textSecondary,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation widgets
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedMessageItem extends StatefulWidget {
  final Widget child;

  const AnimatedMessageItem({super.key, required this.child});

  @override
  State<AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}

class PulsingOnlineDot extends StatefulWidget {
  const PulsingOnlineDot({super.key});

  @override
  State<PulsingOnlineDot> createState() => _PulsingOnlineDotState();
}

class _PulsingOnlineDotState extends State<PulsingOnlineDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14 * _controller.value,
              height: 14 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green
                    .withOpacity((1 - _controller.value).clamp(0.0, 1.0)),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }
}
