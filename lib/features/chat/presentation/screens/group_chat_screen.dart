import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../widgets/chat_tab.dart';
import '../../../../core/theme/app_colors.dart';

class GroupChatScreen extends ConsumerWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final colors = context.colors;

    return groupAsync.when(
      data: (group) => Scaffold(
        backgroundColor: colors.background,
        body: ChatTab(
          group: group,
          showAppBar: true,
        ),
      ),
      loading: () => Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: colors.primaryGold,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to load Nest details: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.error, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
