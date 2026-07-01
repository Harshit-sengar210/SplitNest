import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settlement/presentation/providers/settlement_provider.dart';
import '../../../expenses/domain/models/expense.dart';

class SettlementBottomSheet extends ConsumerStatefulWidget {
  final String groupId;
  final Expense expense;
  final ExpenseSplit split;

  const SettlementBottomSheet({
    super.key,
    required this.groupId,
    required this.expense,
    required this.split,
  });

  @override
  ConsumerState<SettlementBottomSheet> createState() => _SettlementBottomSheetState();
}

class _SettlementBottomSheetState extends ConsumerState<SettlementBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default to the full remaining amount
    _amountController.text = widget.split.pendingAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyPercentage(double percentage) {
    final amount = widget.split.pendingAmount * percentage;
    setState(() {
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  Future<void> _submitSettlement() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (enteredAmount <= 0) {
      setState(() {
        _errorMessage = 'Amount must be greater than 0';
      });
      return;
    }

    if (enteredAmount > widget.split.pendingAmount + 0.01) {
      setState(() {
        _errorMessage = 'Amount cannot exceed the remaining debt';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(settlementRepositoryProvider);
      await repo.createSettlement(
        groupId: widget.groupId,
        expenseId: widget.expense.id,
        splitId: widget.split.splitId,
        amount: enteredAmount,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully settled ₹${enteredAmount.toStringAsFixed(2)}!',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = widget.split.pendingAmount;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: colors.accentBrown.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settle Up',
                      style: GoogleFonts.plusJakartaSans(
                        color: colors.textWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: colors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Debtor Profile
                Row(
                  children: [
                    _buildAvatar(widget.split.memberName, colors),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.split.memberName,
                            style: GoogleFonts.plusJakartaSans(
                              color: colors.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paid by you for "${widget.expense.title}"',
                            style: GoogleFonts.plusJakartaSans(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount summary cards
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.accentBrown.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryColumn(
                        'Total Owed',
                        '₹${widget.split.originalShare.toStringAsFixed(1)}',
                        colors.textSecondary,
                        colors,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: colors.textMuted.withOpacity(0.2),
                      ),
                      _buildSummaryColumn(
                        'Settled',
                        '₹${widget.split.settledAmount.toStringAsFixed(1)}',
                        colors.success,
                        colors,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: colors.textMuted.withOpacity(0.2),
                      ),
                      _buildSummaryColumn(
                        'Remaining',
                        '₹${remaining.toStringAsFixed(1)}',
                        colors.primaryGold,
                        colors,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Enter Received Amount
                Text(
                  'Enter Received Amount',
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.currency_rupee, color: colors.primaryGold, size: 20),
                    filled: true,
                    fillColor: colors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.accentBrown.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.primaryGold, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.error, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final val = double.tryParse(value);
                    if (val == null) {
                      return 'Please enter a valid number';
                    }
                    if (val <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    if (val > remaining + 0.01) {
                      return 'Amount cannot exceed ₹${remaining.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quick Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickChip('25%', () => _applyPercentage(0.25), remaining * 0.25, colors),
                      const SizedBox(width: 8),
                      _buildQuickChip('50%', () => _applyPercentage(0.50), remaining * 0.50, colors),
                      const SizedBox(width: 8),
                      _buildQuickChip('75%', () => _applyPercentage(0.75), remaining * 0.75, colors),
                      const SizedBox(width: 8),
                      _buildQuickChip('100%', () => _applyPercentage(1.0), remaining, colors),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: colors.error,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitSettlement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryGold,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.primaryGold.withOpacity(0.5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm Settlement',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String label, String value, Color valueColor, AppColorsExtension colors) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: colors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, double value, AppColorsExtension colors) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: colors.accentBrown.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: colors.primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(₹${value.toStringAsFixed(0)})',
              style: GoogleFonts.plusJakartaSans(
                color: colors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, AppColorsExtension colors) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors.primaryGold.withOpacity(0.8),
            colors.primaryGold,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
