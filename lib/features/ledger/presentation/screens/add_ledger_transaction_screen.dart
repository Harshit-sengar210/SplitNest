import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/ledger_provider.dart';
import '../../domain/models/ledger_transaction.dart';

class AddLedgerTransactionScreen extends ConsumerStatefulWidget {
  final String? editId;
  const AddLedgerTransactionScreen({super.key, this.editId});

  @override
  ConsumerState<AddLedgerTransactionScreen> createState() => _AddLedgerTransactionScreenState();
}

class _AddLedgerTransactionScreenState extends ConsumerState<AddLedgerTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _personNameController = TextEditingController();
  final _paymentMethodController = TextEditingController(text: 'UPI');

  String _selectedType = 'expense'; // 'expense', 'income', 'lend', 'borrow'
  String _selectedCategory = 'Food';
  String _selectedDateString = '';
  DateTime _selectedDate = DateTime.now();
  String _status = 'completed';
  bool _isLoading = false;

  final List<String> _categories = [
    'Food',
    'Shopping',
    'Transport',
    'Bills',
    'Entertainment',
    'Salary',
    'Lend/Borrow',
    'Other'
  ];

  final List<String> _paymentMethods = [
    'UPI',
    'Cash',
    'Card',
    'Bank Transfer'
  ];

  LedgerTransaction? _editingTx;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set type from query parameter if present
      final uri = GoRouterState.of(context).uri;
      final typeParam = uri.queryParameters['type'];
      if (typeParam != null && ['expense', 'income', 'lend', 'borrow'].contains(typeParam)) {
        setState(() {
          _selectedType = typeParam;
          if (typeParam == 'income') {
            _selectedCategory = 'Salary';
          } else if (typeParam == 'lend' || typeParam == 'borrow') {
            _selectedCategory = 'Lend/Borrow';
          }
        });
      }

      if (widget.editId != null) {
        ref.read(ledgerTransactionsProvider).whenData((transactions) {
          final tx = transactions.firstWhere((t) => t.transactionId == widget.editId);
          setState(() {
            _editingTx = tx;
            _titleController.text = tx.title;
            _amountController.text = tx.amount.toString();
            _noteController.text = tx.description;
            _selectedType = tx.type;
            _selectedCategory = tx.categoryName;
            _selectedDate = tx.date;
            _paymentMethodController.text = tx.paymentMethod;
            _personNameController.text = tx.personName ?? '';
            _status = tx.status;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _personNameController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.colors.primaryGold,
              onPrimary: Colors.white,
              surface: context.colors.card,
              onSurface: context.colors.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final controller = ref.read(ledgerControllerProvider);
        if (_editingTx != null) {
          final updated = _editingTx!.copyWith(
            title: _titleController.text.trim(),
            description: _noteController.text.trim(),
            amount: double.parse(_amountController.text),
            type: _selectedType,
            categoryId: _selectedCategory,
            categoryName: _selectedCategory,
            paymentMethod: _paymentMethodController.text,
            date: _selectedDate,
            personName: (_selectedType == 'lend' || _selectedType == 'borrow') ? _personNameController.text.trim() : null,
            status: _status,
          );
          await controller.updateTransaction(updated);
        } else {
          await controller.addTransaction(
            title: _titleController.text.trim(),
            description: _noteController.text.trim(),
            amount: double.parse(_amountController.text),
            type: _selectedType,
            categoryId: _selectedCategory,
            categoryName: _selectedCategory,
            paymentMethod: _paymentMethodController.text,
            date: _selectedDate,
            personName: (_selectedType == 'lend' || _selectedType == 'borrow') ? _personNameController.text.trim() : null,
            status: _status,
          );
        }
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving transaction: $e', style: TextStyle(color: context.colors.textWhite)), backgroundColor: context.colors.error),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.editId != null ? 'Edit Transaction' : 'Add Transaction';

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(titleText, style: GoogleFonts.outfit(color: context.colors.textWhite, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textWhite),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type selection segmented controller
                    Row(
                      children: ['expense', 'income', 'lend', 'borrow'].map((type) {
                        final isSelected = _selectedType == type;
                        Color chipColor;
                        if (type == 'income') chipColor = const Color(0xFF2DC88A);
                        else if (type == 'expense') chipColor = const Color(0xFFEF4444);
                        else if (type == 'lend') chipColor = const Color(0xFF3B82F6);
                        else chipColor = const Color(0xFFFF8C42);

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = type;
                                if (type == 'income') {
                                  _selectedCategory = 'Salary';
                                } else if (type == 'lend' || type == 'borrow') {
                                  _selectedCategory = 'Lend/Borrow';
                                } else {
                                  _selectedCategory = 'Food';
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? chipColor : context.colors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? chipColor : context.colors.accentBrown.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                type.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? Colors.white : context.colors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: context.colors.textWhite),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: context.colors.textSecondary),
                        filled: true,
                        fillColor: context.colors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      style: TextStyle(color: context.colors.textWhite),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount (₹)',
                        labelStyle: TextStyle(color: context.colors.textSecondary),
                        filled: true,
                        fillColor: context.colors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter an amount';
                        final double? amt = double.tryParse(val);
                        if (amt == null || amt <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Conditional Person Name for Lend / Borrow
                    if (_selectedType == 'lend' || _selectedType == 'borrow') ...[
                      TextFormField(
                        controller: _personNameController,
                        style: TextStyle(color: context.colors.textWhite),
                        decoration: InputDecoration(
                          labelText: 'Person Name',
                          labelStyle: TextStyle(color: context.colors.textSecondary),
                          filled: true,
                          fillColor: context.colors.card,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter the person\'s name' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Category selection dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: context.colors.card,
                      style: TextStyle(color: context.colors.textWhite),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: context.colors.textSecondary),
                        filled: true,
                        fillColor: context.colors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Dropdown
                    DropdownButtonFormField<String>(
                      value: _paymentMethodController.text,
                      dropdownColor: context.colors.card,
                      style: TextStyle(color: context.colors.textWhite),
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        labelStyle: TextStyle(color: context.colors.textSecondary),
                        filled: true,
                        fillColor: context.colors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _paymentMethodController.text = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Box
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: context.colors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                              style: TextStyle(color: context.colors.textWhite),
                            ),
                            Icon(Icons.calendar_today_rounded, color: context.colors.primaryGold),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes / Description
                    TextFormField(
                      controller: _noteController,
                      style: TextStyle(color: context.colors.textWhite),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        labelStyle: TextStyle(color: context.colors.textSecondary),
                        filled: true,
                        fillColor: context.colors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _saveTransaction,
                      child: Text(
                        'SAVE TRANSACTION',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
