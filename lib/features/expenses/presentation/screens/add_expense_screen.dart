import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../providers/expenses_provider.dart';
import '../../domain/models/expense.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../groups/domain/models/group.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> with TickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedGroupId;
  String _selectedCategory = 'Groceries';
  String _splitMethod = 'Equal'; // 'Equal', 'Exact Amount', 'Percentage', 'Shares'
  String _paidByUserId = 'user_me';

  // State to track selected members for split
  final Map<String, bool> _selectedMembers = {};
  // State to track custom split inputs
  final Map<String, TextEditingController> _exactAmountsControllers = {};
  final Map<String, TextEditingController> _percentagesControllers = {};
  final Map<String, TextEditingController> _sharesControllers = {};

  final List<String> _categories = [
    'Groceries', 'Rent', 'Utilities', 'Travel', 'Party', 'Food', 'Shopping', 'Other'
  ];

  // Success animation state
  bool _showSuccessOverlay = false;
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _descriptionTextController.addListener(() => setState(() {}));
    
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  void _disposeControllers() {
    for (var controller in _exactAmountsControllers.values) {
      controller.dispose();
    }
    _exactAmountsControllers.clear();
    for (var controller in _percentagesControllers.values) {
      controller.dispose();
    }
    _percentagesControllers.clear();
    for (var controller in _sharesControllers.values) {
      controller.dispose();
    }
    _sharesControllers.clear();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _descriptionTextController.dispose();
    _successController.dispose();
    _floatController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _onGroupChanged(String? groupId, List<Group> groups) {
    if (groupId == null) return;
    setState(() {
      _selectedGroupId = groupId;
      
      // Initialize selected members map for the new group
      final group = groups.firstWhere((g) => g.id == groupId);
      _selectedMembers.clear();
      _disposeControllers();

      for (var member in group.members) {
        _selectedMembers[member.id] = true; // Default check all
        _exactAmountsControllers[member.id] = TextEditingController(text: '0');
        _percentagesControllers[member.id] = TextEditingController(text: '0');
        _sharesControllers[member.id] = TextEditingController(text: '1'); // Default 1 share
      }

      // Default paidBy to current user if in group, else first member
      if (group.members.any((m) => m.id == 'user_me')) {
        _paidByUserId = 'user_me';
      } else if (group.members.isNotEmpty) {
        _paidByUserId = group.members.first.id;
      }
    });
  }

  double get _totalAmount {
    return double.tryParse(_amountController.text.trim()) ?? 0.0;
  }

  int get _selectedMembersCount {
    return _selectedMembers.values.where((v) => v).length;
  }

  bool get _hasUnsavedChanges {
    return _amountController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _descriptionTextController.text.trim().isNotEmpty ||
        _selectedGroupId != null;
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsListProvider);

    // Filter out groups that have no members just in case
    final validGroups = groupsState.groups.where((g) => g.members.isNotEmpty).toList();

    // Find the currently selected group data
    Group? selectedGroup;
    if (_selectedGroupId != null) {
      try {
        selectedGroup = validGroups.firstWhere((g) => g.id == _selectedGroupId);
      } catch (_) {
        selectedGroup = null;
      }
    }

    return Stack(
      children: [
        Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppHeader(
            title: 'Add Expense',
            hasUnsavedChanges: _hasUnsavedChanges,
          ),
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
                _BackgroundShapes(floatAnimation: _floatAnimation),
                SafeArea(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0, bottom: 40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Record a bill and split with your nest instantly.',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Form Card (Premium White Card)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B61FF).withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Group Selector
                                Text(
                                  'Select Nest Group',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF1F2937),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDropdownWrapper(
                                  icon: Icons.group_work_rounded,
                                  iconColor: const Color(0xFF7B61FF),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedGroupId,
                                      hint: Text('Choose a group', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 14)),
                                      dropdownColor: Colors.white,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7B61FF)),
                                      items: validGroups.map((group) {
                                        return DropdownMenuItem(
                                          value: group.id,
                                          child: Text(group.name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontSize: 14)),
                                        );
                                      }).toList(),
                                      onChanged: (val) => _onGroupChanged(val, validGroups),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Title Input
                                PremiumTextField(
                                  controller: _descriptionController,
                                  labelText: 'Expense Title',
                                  hintText: 'Vegetables, Wifi, rent, drinks...',
                                  prefixIcon: Icons.description_outlined,
                                  iconColor: const Color(0xFF6CA8FF),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Amount Input
                                PremiumTextField(
                                  controller: _amountController,
                                  labelText: 'Total Amount (₹)',
                                  hintText: '0.00',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  prefixIcon: Icons.currency_rupee_rounded,
                                  iconColor: const Color(0xFF10B981),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter an amount';
                                    }
                                    final numVal = double.tryParse(val);
                                    if (numVal == null || numVal <= 0) {
                                      return 'Please enter a valid amount greater than 0';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Category Selector
                                Text(
                                  'Category',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF1F2937),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDropdownWrapper(
                                  icon: Icons.category_rounded,
                                  iconColor: const Color(0xFFA78BFA),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      dropdownColor: Colors.white,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7B61FF)),
                                      items: _categories.map((cat) {
                                        return DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontSize: 14)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedCategory = val);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Description Input
                                PremiumTextField(
                                  controller: _descriptionTextController,
                                  labelText: 'Description (Optional)',
                                  hintText: 'Add details or notes...',
                                  prefixIcon: Icons.notes_rounded,
                                  iconColor: const Color(0xFF9CA3AF),
                                ),
                                
                                if (selectedGroup != null) ...[
                                  const SizedBox(height: 20),
                                  // Paid By dropdown
                                  Text(
                                    'Paid By',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF1F2937),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDropdownWrapper(
                                    icon: Icons.person_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _paidByUserId,
                                        dropdownColor: Colors.white,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7B61FF)),
                                        items: selectedGroup.members.map((m) {
                                          return DropdownMenuItem(
                                            value: m.id,
                                            child: Text(m.id == 'user_me' ? 'You' : m.name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontSize: 14)),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _paidByUserId = val);
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),
                                  // Split Type dropdown
                                  Text(
                                    'Split Type',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF1F2937),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDropdownWrapper(
                                    icon: Icons.call_split_rounded,
                                    iconColor: const Color(0xFF7B61FF),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _splitMethod,
                                        dropdownColor: Colors.white,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7B61FF)),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Equal',
                                            child: Text('Equal', style: TextStyle(color: Color(0xFF1F2937), fontSize: 14)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Exact Amount',
                                            child: Text('Exact Amount', style: TextStyle(color: Color(0xFF1F2937), fontSize: 14)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Percentage',
                                            child: Text('Percentage', style: TextStyle(color: Color(0xFF1F2937), fontSize: 14)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Shares',
                                            child: Text('Shares', style: TextStyle(color: Color(0xFF1F2937), fontSize: 14)),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _splitMethod = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),
                                  // Split With Checklist
                                  Text(
                                    'Split With',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF1F2937),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: selectedGroup.members.length,
                                    itemBuilder: (context, index) {
                                      final member = selectedGroup!.members[index];
                                      final isSelected = _selectedMembers[member.id] ?? false;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFF9FAFB) : Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFF7B61FF).withOpacity(0.15) : const Color(0xFFE5E7EB),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isSelected 
                                                    ? const Color(0xFF7B61FF).withOpacity(0.04) 
                                                    : Colors.transparent,
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            leading: Checkbox(
                                              activeColor: const Color(0xFF7B61FF),
                                              checkColor: Colors.white,
                                              value: isSelected,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              onChanged: (val) {
                                                setState(() {
                                                  _selectedMembers[member.id] = val ?? false;
                                                });
                                              },
                                            ),
                                            title: Text(
                                              member.id == 'user_me' ? 'You (${member.email})' : '${member.name} (${member.email})',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 14,
                                              ),
                                            ),
                                            trailing: _buildMemberTrailing(member, isSelected),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Display split math details / validation status
                                  if (_totalAmount > 0) ...[
                                    const SizedBox(height: 16),
                                    _buildSplitStatus(),
                                  ],
                                ],

                                const SizedBox(height: 32),
                                // Submit button
                                PremiumButton(
                                  text: 'CREATE EXPENSE',
                                  isLoading: false,
                                  onPressed: _submitExpense,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Success Overlay Screen (Premium 3D glow theme)
        if (_showSuccessOverlay)
          _buildSuccessOverlay(),
      ],
    );
  }

  Widget _buildDropdownWrapper({
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          _build3DIcon(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _build3DIcon(IconData icon, Color primaryColor) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.85),
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
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

  Widget _buildSplitOptionChip({
    required String label,
    required bool active,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _splitMethod = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : Colors.transparent,
          border: Border.all(
            color: active ? Colors.transparent : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B61FF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: active ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget? _buildMemberTrailing(dynamic member, bool isSelected) {
    if (!isSelected) return null;

    final total = _totalAmount;

    if (_splitMethod == 'Equal') {
      if (total <= 0 || _selectedMembersCount == 0) return null;
      final share = total / _selectedMembersCount;
      return Text(
        '₹${share.toStringAsFixed(2)}',
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF7B61FF),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    if (_splitMethod == 'Exact Amount') {
      return SizedBox(
        width: 110,
        height: 38,
        child: TextField(
          controller: _exactAmountsControllers[member.id],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          cursorColor: const Color(0xFF7B61FF),
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF7B61FF),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: Colors.white,
            hintText: '0',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF)),
            prefixText: '₹ ',
            prefixStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF7B61FF),
              fontWeight: FontWeight.bold,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      );
    }

    if (_splitMethod == 'Percentage') {
      final pct = double.tryParse(_percentagesControllers[member.id]?.text ?? '0') ?? 0.0;
      final calculatedAmount = total > 0 ? (pct / 100.0) * total : 0.0;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (total > 0) ...[
            Text(
              '₹${calculatedAmount.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 80,
            height: 38,
            child: TextField(
              controller: _percentagesControllers[member.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              cursorColor: const Color(0xFF7B61FF),
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF7B61FF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: Colors.white,
                hintText: '0',
                hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF)),
                suffixText: '%',
                suffixStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF7B61FF),
                  fontWeight: FontWeight.bold,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      );
    }

    if (_splitMethod == 'Shares') {
      double totalShares = 0.0;
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          totalShares += double.tryParse(_sharesControllers[memberId]?.text ?? '0') ?? 0.0;
        }
      });
      final shares = double.tryParse(_sharesControllers[member.id]?.text ?? '0') ?? 0.0;
      final calculatedAmount = (total > 0 && totalShares > 0) ? (shares / totalShares) * total : 0.0;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (total > 0) ...[
            Text(
              '₹${calculatedAmount.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 80,
            height: 38,
            child: TextField(
              controller: _sharesControllers[member.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              cursorColor: const Color(0xFF7B61FF),
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF7B61FF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: Colors.white,
                hintText: '1',
                hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF)),
                suffixText: 'share',
                suffixStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF7B61FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      );
    }

    return null;
  }

  Widget _buildSplitStatus() {
    final total = _totalAmount;
    if (total <= 0) return const SizedBox.shrink();

    if (_splitMethod == 'Equal') {
      if (_selectedMembersCount == 0) {
        return _buildStatusBox(
          text: 'Select at least one member to split with.',
          isError: true,
        );
      }
      final share = total / _selectedMembersCount;
      return _buildStatusBox(
        text: 'Each selected member pays ₹${share.toStringAsFixed(2)}.',
        isError: false,
      );
    } else if (_splitMethod == 'Exact Amount') {
      double sum = 0.0;
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          sum += double.tryParse(_exactAmountsControllers[memberId]?.text ?? '0') ?? 0.0;
        }
      });
      final diff = total - sum;
      final isMatched = diff.abs() < 0.01;
      final text = isMatched
          ? 'Perfect! Split sum matches total expense.'
          : diff > 0
              ? '₹${diff.toStringAsFixed(2)} remaining to assign'
              : '₹${(-diff).toStringAsFixed(2)} over allocated';
      return _buildStatusBox(
        text: text,
        isError: !isMatched,
      );
    } else if (_splitMethod == 'Percentage') {
      double sum = 0.0;
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          sum += double.tryParse(_percentagesControllers[memberId]?.text ?? '0') ?? 0.0;
        }
      });
      final diff = 100.0 - sum;
      final isMatched = diff.abs() < 0.01;
      final text = isMatched
          ? 'Perfect! Percentages sum up to 100%.'
          : diff > 0
              ? '${diff.toStringAsFixed(1)}% remaining to assign'
              : '${(-diff).toStringAsFixed(1)}% over allocated';
      return _buildStatusBox(
        text: text,
        isError: !isMatched,
      );
    } else if (_splitMethod == 'Shares') {
      double totalShares = 0.0;
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          totalShares += double.tryParse(_sharesControllers[memberId]?.text ?? '0') ?? 0.0;
        }
      });
      if (totalShares <= 0) {
        return _buildStatusBox(
          text: 'Total shares must be greater than 0.',
          isError: true,
        );
      }
      final shareValue = total / totalShares;
      return _buildStatusBox(
        text: 'Total shares: ${totalShares.toStringAsFixed(1)}. 1 share = ₹${shareValue.toStringAsFixed(2)}.',
        isError: false,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusBox({required String text, required bool isError}) {
    final color = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final bgColor = isError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitExpense() {
    if (_selectedGroupId == null) {
      _showSnackBarError('Please select a group');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMembersCount == 0) {
      _showSnackBarError('Please select at least one member to split with');
      return;
    }

    final total = _totalAmount;

    // Build splits list
    final splits = <ExpenseSplit>[];
    if (_splitMethod == 'Equal') {
      final share = total / _selectedMembersCount;
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          splits.add(ExpenseSplit(userId: memberId, amount: share));
        }
      });
    } else if (_splitMethod == 'Exact Amount') {
      double sum = 0.0;
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          sum += double.tryParse(_exactAmountsControllers[memberId]?.text ?? '0') ?? 0.0;
        }
      });
      if ((total - sum).abs() >= 0.01) {
        _showSnackBarError('Exact split amounts must add up exactly to the total expense (₹$total)');
        return;
      }
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          final amt = double.tryParse(_exactAmountsControllers[memberId]?.text ?? '0') ?? 0.0;
          splits.add(ExpenseSplit(userId: memberId, amount: amt));
        }
      });
    } else if (_splitMethod == 'Percentage') {
      double sum = 0.0;
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          sum += double.tryParse(_percentagesControllers[memberId]?.text ?? '0') ?? 0.0;
        }
      });
      if ((100.0 - sum).abs() >= 0.01) {
        _showSnackBarError('Percentages must add up exactly to 100%');
        return;
      }
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          final pct = double.tryParse(_percentagesControllers[memberId]?.text ?? '0') ?? 0.0;
          final amt = (pct / 100.0) * total;
          splits.add(ExpenseSplit(userId: memberId, amount: amt, percentage: pct));
        }
      });
    } else if (_splitMethod == 'Shares') {
      double totalShares = 0.0;
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          totalShares += double.tryParse(_sharesControllers[memberId]?.text ?? '0') ?? 0.0;
        }
      });
      if (totalShares <= 0) {
        _showSnackBarError('Total shares must be greater than 0');
        return;
      }
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          final shares = double.tryParse(_sharesControllers[memberId]?.text ?? '0') ?? 0.0;
          final amt = (shares / totalShares) * total;
          splits.add(ExpenseSplit(userId: memberId, amount: amt, shares: shares));
        }
      });
    }

    final groups = ref.read(groupsListProvider).groups;
    final selectedGroup = groups.firstWhere((g) => g.id == _selectedGroupId, orElse: () => throw Exception('Group not found'));
    final selectedMember = selectedGroup.members.firstWhere((m) => m.id == _paidByUserId, orElse: () => selectedGroup.members.first);
    final paidByName = selectedMember.id == 'user_me' ? 'You' : selectedMember.name;

    // Call provider to create expense
    final notifier = ref.read(expensesProvider(_selectedGroupId!).notifier);
    notifier.createExpense(
      title: _descriptionController.text.trim(),
      amount: total,
      category: _selectedCategory,
      groupId: _selectedGroupId!,
      paidByUserId: _paidByUserId,
      splits: splits,
      splitMethod: _splitMethod,
      description: _descriptionTextController.text.trim().isEmpty ? null : _descriptionTextController.text.trim(),
      paidByName: paidByName,
    ).then((_) {
      // Trigger Success Animation overlay
      setState(() {
        _showSuccessOverlay = true;
      });
      _successController.forward();

      // Delay then navigate back/reset
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _showSuccessOverlay = false;
            _amountController.clear();
            _descriptionController.clear();
            _descriptionTextController.clear();
            _selectedGroupId = null;
            _disposeControllers();
            _selectedMembers.clear();
            _splitMethod = 'Equal';
          });
          _successController.reset();
        }
      });
    }).catchError((e) {
      _showSnackBarError(e.toString());
    });
  }

  void _showSnackBarError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      alignment: Alignment.center,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium 3D Glow Ring and Checkmark
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B61FF).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Expense Logged!',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1F2937),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Balances calculated and timelines updated.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// LOCAL WIDGETS
// ==========================================

class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final Color iconColor;
  final bool isPassword;
  final FormFieldValidator<String>? validator;
  final TextInputType keyboardType;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

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
    this.onChanged,
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
            onChanged: widget.onChanged,
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

  Widget _build3DIcon(IconData icon, Color primaryColor) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.85),
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
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

class _PremiumButtonState extends State<PremiumButton> with TickerProviderStateMixin {
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
        Positioned(
          top: 100,
          left: -40,
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
                    const Color(0xFFA78BFA).withOpacity(0.18),
                    const Color(0xFFA78BFA).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -50,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -floatAnimation.value * 15),
                child: child,
              );
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6CA8FF).withOpacity(0.18),
                    const Color(0xFF6CA8FF).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
