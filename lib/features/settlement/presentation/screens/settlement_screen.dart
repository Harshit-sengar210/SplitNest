import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../groups/domain/models/group.dart';
import '../providers/settlement_provider.dart';
import '../../domain/models/balance.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kPurple = Color(0xFF7B61FF);
const _kPurpleDark = Color(0xFF5A3FD6);
const _kPurpleLight = Color(0xFFF5F3FF);
const _kCard = Colors.white;
const _kText = Color(0xFF1A1A2E);
const _kSub = Color(0xFF6B7280);
const _kSuccess = Color(0xFF22C55E);
const _kError = Color(0xFFEF4444);

class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({super.key});

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;

  Group? _selectedGroup;
  GroupMember? _selectedMember;
  double _balanceAmount = 0.0;
  bool _youOwe = false;

  bool _isFullSettlement = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSettling = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onGroupSelected(Group group) {
    setState(() {
      _selectedGroup = group;
      _selectedMember = null;
      _currentStep = 1;
    });
  }

  void _onMemberSelected(GroupMember member, List<Balance> balances) {
    double balVal = 0.0;
    for (final b in balances) {
      if (b.fromUserId == 'user_me' && b.toUserId == member.id) {
        balVal += b.amount;
      } else if (b.fromUserId == member.id && b.toUserId == 'user_me') {
        balVal -= b.amount;
      }
    }
    setState(() {
      _selectedMember = member;
      _balanceAmount = balVal.abs();
      _youOwe = balVal > 0;
      _isFullSettlement = true;
      _amountController.text = _balanceAmount.toStringAsFixed(0);
      _currentStep = 2;
    });
  }

  void _confirmSelection() {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _currentStep = 3);
  }

  void _submitSettlement() async {
    if (_selectedGroup == null || _selectedMember == null) return;
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0) return;

    if (_youOwe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Only the receiver can confirm this settlement. Please ask ${_selectedMember!.name} to confirm receipt.'),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSettling = true);

    try {
      await ref.read(settlementRepositoryProvider).settleDebt(
            groupId: _selectedGroup!.id,
            debtorId: _selectedMember!.id,
            creditorId: 'user_me',
            amount: amt,
          );

      if (mounted) {
        _showSuccessDialog(amt);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: _kError,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSettling = false);
    }
  }

  void _showSuccessDialog(double amt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kSuccess.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Settlement Confirmed!',
                style: TextStyle(
                    color: _kText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${amt.toInt()} settled with ${_selectedMember!.name}',
                style: const TextStyle(color: _kSub, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPurpleDark, _kPurple],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _kPurple.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'DONE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsListProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPurple.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4F8EF7).withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: groupsState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: _kPurple, strokeWidth: 2))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                _buildStepIndicator(),
                                const SizedBox(height: 28),
                                if (_currentStep == 0)
                                  _buildGroupSelection(groupsState.groups)
                                else if (_currentStep == 1)
                                  _buildMemberSelection()
                                else if (_currentStep == 2)
                                  _buildAmountSelection()
                                else if (_currentStep == 3)
                                  _buildConfirmation(),
                              ],
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

  Widget _buildAppBar() {
    final stepTitles = [
      'Settle Up',
      'Select Member',
      'Choose Amount',
      'Confirm'
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                context.pop();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kText, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepTitles[_currentStep],
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of 4',
                  style: const TextStyle(color: _kSub, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(4, (index) {
        final isDone = index < _currentStep;
        final isActive = index == _currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 5,
            decoration: BoxDecoration(
              gradient: (isDone || isActive)
                  ? const LinearGradient(
                      colors: [_kPurpleDark, _kPurple],
                    )
                  : null,
              color: (isDone || isActive)
                  ? null
                  : _kPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGroupSelection(List<Group> groups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Select Nest Group', 'Choose which nest to settle in'),
        const SizedBox(height: 16),
        if (groups.isEmpty)
          _buildEmptyCard(
              icon: Icons.group_off_rounded,
              message: 'No active groups found')
        else
          ...groups.map((group) => _buildGroupCard(group)),
      ],
    );
  }

  Widget _buildGroupCard(Group group) {
    return GestureDetector(
      onTap: () => _onGroupSelected(group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPurpleDark, _kPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.group_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('${group.membersCount} members • ${group.type}',
                      style:
                          const TextStyle(color: _kSub, fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kPurpleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: _kPurple, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelection() {
    if (_selectedGroup == null) return const SizedBox();
    final balancesAsync = ref.watch(groupBalancesProvider(_selectedGroup!.id));

    return balancesAsync.when(
      data: (balances) {
        final members = _selectedGroup!.members
            .where((m) => m.id != 'user_me')
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Settle with Member',
              'From ${_selectedGroup!.name}',
            ),
            const SizedBox(height: 16),
            if (members.isEmpty)
              _buildEmptyCard(
                  icon: Icons.person_off_rounded,
                  message: 'No other members in this group')
            else
              ...members.map((member) {
                double balVal = 0.0;
                for (final b in balances) {
                  if (b.fromUserId == 'user_me' &&
                      b.toUserId == member.id) {
                    balVal += b.amount;
                  } else if (b.fromUserId == member.id &&
                      b.toUserId == 'user_me') {
                    balVal -= b.amount;
                  }
                }
                final isSettled = balVal.abs() < 0.01;
                final youOweThisMember = balVal > 0;
                final statusText = isSettled
                    ? 'Settled up ✓'
                    : youOweThisMember
                        ? 'You owe ₹${balVal.toStringAsFixed(0)}'
                        : 'Owes you ₹${balVal.abs().toStringAsFixed(0)}';

                return GestureDetector(
                  onTap: () => _onMemberSelected(member, balances),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _kPurpleLight,
                          backgroundImage: member.photoUrl != null
                              ? NetworkImage(member.photoUrl!)
                              : null,
                          child: member.photoUrl == null
                              ? Text(member.name[0],
                                  style: const TextStyle(
                                      color: _kPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16))
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.name,
                                  style: const TextStyle(
                                      color: _kText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: isSettled
                                      ? _kSub
                                      : youOweThisMember
                                          ? _kError
                                          : _kSuccess,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _kPurpleLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded,
                              color: _kPurple, size: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: _kPurple, strokeWidth: 2)),
      error: (e, _) =>
          Center(child: Text(e.toString(), style: const TextStyle(color: _kError))),
    );
  }

  Widget _buildAmountSelection() {
    if (_selectedMember == null) return const SizedBox();

    final statusText = _balanceAmount < 0.01
        ? 'Settled up ✓'
        : _youOwe
            ? 'You owe ${_selectedMember!.name} ₹${_balanceAmount.toStringAsFixed(2)}'
            : '${_selectedMember!.name} owes you ₹${_balanceAmount.toStringAsFixed(2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Balance status card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _youOwe
                  ? [_kError, const Color(0xFFC21414)]
                  : [_kSuccess, const Color(0xFF16A34A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (_youOwe ? _kError : _kSuccess).withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'BALANCE STATUS',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(
            'Settlement Type & Amount', 'Choose how much to settle'),
        const SizedBox(height: 16),

        // Type selector
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildTypeChip('Full Settlement', _isFullSettlement, () {
                setState(() {
                  _isFullSettlement = true;
                  _amountController.text =
                      _balanceAmount.toStringAsFixed(0);
                });
              }),
              _buildTypeChip('Partial', !_isFullSettlement, () {
                setState(() => _isFullSettlement = false);
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Amount input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _amountController,
            enabled: !_isFullSettlement,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                color: _kText, fontWeight: FontWeight.bold, fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              labelStyle: TextStyle(color: _kSub),
              border: InputBorder.none,
              prefixIcon:
                  Icon(Icons.currency_rupee_rounded, color: _kPurple),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Note input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _noteController,
            style: const TextStyle(color: _kText, fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Note (Optional)',
              hintText: 'e.g., Cash, GPay, etc.',
              labelStyle: TextStyle(color: _kSub),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.notes_rounded, color: _kPurple),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildPurpleButton('CONTINUE', _confirmSelection, false),
      ],
    );
  }

  Widget _buildTypeChip(
      String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [_kPurpleDark, _kPurple])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : _kSub,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmation() {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text(
            'Confirm Settlement',
            style: TextStyle(
                color: _kText,
                fontWeight: FontWeight.bold,
                fontSize: 22),
          ),
        ),
        const SizedBox(height: 24),

        // Amount hero
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPurpleDark, _kPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '₹${amt.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Settlement Amount',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Details card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildConfirmRow(
                  'Nest Group', _selectedGroup!.name),
              const Divider(height: 20, color: Color(0xFFF3F4F6)),
              _buildConfirmRow('Settle With', _selectedMember!.name),
              const Divider(height: 20, color: Color(0xFFF3F4F6)),
              _buildConfirmRow(
                'Transaction',
                _youOwe
                    ? 'You pay ${_selectedMember!.name}'
                    : 'You receive from ${_selectedMember!.name}',
              ),
              if (_noteController.text.trim().isNotEmpty) ...[
                const Divider(height: 20, color: Color(0xFFF3F4F6)),
                _buildConfirmRow(
                    'Note', _noteController.text.trim()),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildPurpleButton(
          _isSettling ? 'CONFIRMING...' : 'CONFIRM SETTLEMENT',
          _isSettling ? null : _submitSettlement,
          _isSettling,
        ),
      ],
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: _kSub, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: _kText, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(color: _kSub, fontSize: 13)),
      ],
    );
  }

  Widget _buildEmptyCard(
      {required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kSub, size: 44),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: _kSub, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPurpleButton(
      String label, VoidCallback? onPressed, bool isLoading) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? const LinearGradient(
                  colors: [_kPurpleDark, _kPurple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: onPressed == null ? _kPurple.withValues(alpha: 0.5) : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: _kPurple.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
        ),
      ),
    );
  }
}
