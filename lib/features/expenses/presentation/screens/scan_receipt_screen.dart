import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../groups/domain/models/group.dart';
import '../providers/expenses_provider.dart';
import '../../domain/models/expense.dart';
import '../../../activity/data/services/notification_writer.dart';
import '../../../../core/services/cloudinary_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kPurple = Color(0xFF7B61FF);
const _kPurpleDark = Color(0xFF5A3FD6);
const _kPurpleLight = Color(0xFFF5F3FF);
const _kBlue = Color(0xFF4F8EF7);
const _kCard = Colors.white;
const _kText = Color(0xFF1A1A2E);
const _kSub = Color(0xFF6B7280);
const _kSuccess = Color(0xFF22C55E);
const _kError = Color(0xFFEF4444);

class ScanReceiptScreen extends ConsumerStatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  ConsumerState<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends ConsumerState<ScanReceiptScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0: Pick, 1: Scanning, 2: Items, 3: Group, 4: Split

  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;

  // Mock OCR Items
  final List<Map<String, dynamic>> _extractedItems = [
    {'name': 'Tomato', 'amount': 45.0},
    {'name': 'Potato', 'amount': 75.0},
    {'name': 'Milk', 'amount': 120.0},
  ];

  double get _totalAmount =>
      _extractedItems.fold(0.0, (sum, item) => sum + item['amount']);

  Group? _selectedGroup;
  String _paidByUserId = 'user_me';
  String _splitMethod = 'Equal';
  final Map<String, bool> _selectedMembers = {};
  final Map<String, TextEditingController> _customAmountsControllers = {};
  bool _isCreating = false;

  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    for (var c in _customAmountsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final base64String = 'data:image/png;base64,${base64.encode(bytes)}';
      setState(() {
        _selectedImagePath = base64String;
        _currentStep = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _startScan() {
    setState(() => _currentStep = 1);
    _scannerController.repeat(reverse: true);
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _scannerController.stop();
        setState(() => _currentStep = 2);
        NotificationWriter.sendToUser(
          targetUserId: 'user_me',
          title: 'Receipt Scanned',
          description:
              'Successfully extracted ₹${_totalAmount.toStringAsFixed(2)} from receipt.',
          type: 'receipt_scanned',
        );
      }
    });
  }

  void _onGroupSelected(Group group) {
    setState(() {
      _selectedGroup = group;
      _selectedMembers.clear();
      for (var c in _customAmountsControllers.values) {
        c.dispose();
      }
      _customAmountsControllers.clear();
      for (var member in group.members) {
        _selectedMembers[member.id] = true;
        _customAmountsControllers[member.id] =
            TextEditingController(text: '0');
      }
      if (group.members.any((m) => m.id == 'user_me')) {
        _paidByUserId = 'user_me';
      } else if (group.members.isNotEmpty) {
        _paidByUserId = group.members.first.id;
      }
      _currentStep = 4;
    });
  }

  double get _customTotalSum {
    double sum = 0.0;
    _selectedMembers.forEach((memberId, isSelected) {
      if (isSelected) {
        final val = double.tryParse(
                _customAmountsControllers[memberId]?.text ?? '0') ??
            0.0;
        sum += val;
      }
    });
    return sum;
  }

  int get _selectedMembersCount =>
      _selectedMembers.values.where((v) => v).length;

  void _submitExpense() async {
    if (_selectedGroup == null) return;
    if (_selectedMembersCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select at least one member to split with'),
        backgroundColor: _kError,
      ));
      return;
    }
    final total = _totalAmount;
    final splits = <ExpenseSplit>[];
    final selectedMember = _selectedGroup!.members.firstWhere(
        (m) => m.id == _paidByUserId,
        orElse: () => _selectedGroup!.members.first);
    final paidByName = selectedMember.id == 'user_me' ? 'You' : selectedMember.name;

    String getMemberName(String id) {
      final m = _selectedGroup!.members.firstWhere((m) => m.id == id, orElse: () => _selectedGroup!.members.first);
      return m.id == 'user_me' ? 'You' : m.name;
    }

    if (_splitMethod == 'Equal') {
      final share = total / _selectedMembersCount;
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) splits.add(ExpenseSplit(userId: memberId, memberName: getMemberName(memberId), amount: share, paidBy: _paidByUserId, paidByName: paidByName));
      });
    } else {
      final sum = _customTotalSum;
      if ((total - sum).abs() >= 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Custom split amounts must add up exactly to ₹$total'),
          backgroundColor: _kError,
        ));
        return;
      }
      _selectedMembers.forEach((memberId, isSelected) {
        if (isSelected) {
          final amt = double.tryParse(
                  _customAmountsControllers[memberId]?.text ?? '0') ??
              0.0;
          splits.add(ExpenseSplit(userId: memberId, memberName: getMemberName(memberId), amount: amt, paidBy: _paidByUserId, paidByName: paidByName));
        }
      });
    }
    setState(() => _isCreating = true);
    try {
      String? uploadedUrl;
      if (_selectedImagePath != null) {
        uploadedUrl = await CloudinaryService.uploadImage(_selectedImagePath!);
      }

      await ref
          .read(expensesProvider(_selectedGroup!.id).notifier)
          .createExpense(
            title: 'Scan Receipt: Groceries',
            amount: total,
            category: 'Groceries',
            groupId: _selectedGroup!.id,
            paidByUserId: _paidByUserId,
            splits: splits,
            splitMethod: _splitMethod,
            paidByName: paidByName,
            imageUrl: uploadedUrl,
          );
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showSuccessDialog() {
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
                    colors: [_kSuccess, Color(0xFF16A34A)],
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
                'Expense Logged!',
                style: TextStyle(
                    color: _kText, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Receipt scanned and split successfully.',
                style: TextStyle(color: _kSub, fontSize: 14),
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
                        colors: [_kPurpleDark, _kPurple]),
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
                    child: Text('DONE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (path.startsWith('data:image')) {
      final base64Str = path.contains(',') ? path.split(',')[1] : path;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(path);
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
            // Background shapes
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
              bottom: 80,
              left: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBlue.withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          _buildStepIndicator(),
                          const SizedBox(height: 28),
                          if (_currentStep == 0)
                            _buildImagePicker()
                          else if (_currentStep == 1)
                            _buildScanningState()
                          else if (_currentStep == 2)
                            _buildExtractedItems()
                          else if (_currentStep == 3)
                            _buildGroupSelection(groupsState.groups)
                          else if (_currentStep == 4)
                            _buildSplitAndCreate(),
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
      'Scan Slip',
      'Scanning...',
      'Review Items',
      'Select Group',
      'Split & Create'
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep > 0 && _currentStep != 1) {
                setState(() =>
                    _currentStep = _currentStep == 4 ? 3 : _currentStep - 1);
              } else if (_currentStep == 0) {
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
                  'Step ${_currentStep + 1} of 5',
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
      children: List.generate(5, (index) {
        final isDone = index < _currentStep;
        final isActive = index == _currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
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

  // ── Step 0: Image Picker ─────────────────────────────────────────────────────
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Receipt preview or placeholder
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _selectedImagePath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPurpleDark, _kPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _kPurple.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.document_scanner_rounded,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ready to Scan',
                        style: TextStyle(
                            color: _kText,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pick a receipt image to get started',
                        style: TextStyle(color: _kSub, fontSize: 13),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(
                        image: _getImageProvider(_selectedImagePath!),
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 16,
                        right: 16,
                        child: Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),

        if (_selectedImagePath == null) ...[
          const Text(
            'Choose Source',
            style: TextStyle(
                color: _kText, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  subtitle: 'Take a photo',
                  gradient: const LinearGradient(
                      colors: [_kPurpleDark, _kPurple]),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  subtitle: 'From album',
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4F8EF7), Color(0xFF3B7DE0)]),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ] else ...[
          _buildPurpleButton('PROCEED TO SCAN', _startScan, false),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedImagePath = null),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _kPurpleLight,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _kPurple.withValues(alpha: 0.2),
                ),
              ),
              child: const Center(
                child: Text(
                  'CHOOSE DIFFERENT IMAGE',
                  style: TextStyle(
                    color: _kPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Scanning Animation ───────────────────────────────────────────────
  Widget _buildScanningState() {
    return Column(
      children: [
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_selectedImagePath != null)
                  Image(
                    image: _getImageProvider(_selectedImagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                // Scanning line
                AnimatedBuilder(
                  animation: _scannerAnimation,
                  builder: (context, child) => Positioned(
                    top: _scannerAnimation.value * 330,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            _kPurple,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kPurple.withValues(alpha: 0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Overlay
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _kPurple.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            color: _kPurple,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Reading receipt...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Extracting items & amounts',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Extracted Items ──────────────────────────────────────────────────
  Widget _buildExtractedItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Extracted Items',
          style: TextStyle(
              color: _kText, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Review items detected from the receipt',
          style: TextStyle(color: _kSub, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              ..._extractedItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _kPurpleLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: _kPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                  color: _kText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                            ),
                          ),
                          Text(
                            '₹${(item['amount'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: _kPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < _extractedItems.length - 1)
                      Divider(
                          height: 1,
                          color: _kPurple.withValues(alpha: 0.08)),
                  ],
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kPurpleDark, _kPurple]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Text(
                      '₹${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildPurpleButton(
          'PROCEED TO GROUP',
          () => setState(() => _currentStep = 3),
          false,
        ),
      ],
    );
  }

  // ── Step 3: Group Selection ──────────────────────────────────────────────────
  Widget _buildGroupSelection(List<Group> groups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select Nest Group',
          style: TextStyle(
              color: _kText, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose which group to add this expense to',
          style: TextStyle(color: _kSub, fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (groups.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.group_off_rounded, color: _kSub, size: 44),
                SizedBox(height: 12),
                Text('No active groups found',
                    style: TextStyle(color: _kSub, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        else
          ...groups.map((group) => GestureDetector(
                onTap: () => _onGroupSelected(group),
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
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_kPurpleDark, _kPurple]),
                          borderRadius: BorderRadius.circular(13),
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
                            Text(
                                '${group.membersCount} members • ${group.type}',
                                style: const TextStyle(
                                    color: _kSub, fontSize: 12)),
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
              )),
      ],
    );
  }

  // ── Step 4: Split & Create ───────────────────────────────────────────────────
  Widget _buildSplitAndCreate() {
    if (_selectedGroup == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPurpleDark, _kPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SCAN EXPENSE: GROCERIES',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nest',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13)),
                  Text(_selectedGroup!.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Bill',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13)),
                  Text('₹${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Paid By
        const Text('Paid By',
            style: TextStyle(
                color: _kText, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _paidByUserId,
              dropdownColor: _kCard,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _kPurple),
              items: _selectedGroup!.members.map((m) {
                return DropdownMenuItem(
                  value: m.id,
                  child: Text(
                    m.id == 'user_me' ? 'You' : m.name,
                    style: const TextStyle(color: _kText),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _paidByUserId = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Split Method
        const Text('Split Method',
            style: TextStyle(
                color: _kText, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
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
              _buildMethodChip('Equal'),
              _buildMethodChip('Custom'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Split With
        const Text('Split With',
            style: TextStyle(
                color: _kText, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ..._selectedGroup!.members.map((member) {
          final isSelected = _selectedMembers[member.id] ?? false;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _kPurpleLight : _kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? _kPurple.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    activeColor: _kPurple,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    value: isSelected,
                    onChanged: (val) {
                      setState(
                          () => _selectedMembers[member.id] = val ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.id == 'user_me' ? 'You' : member.name,
                        style: TextStyle(
                          color: isSelected ? _kPurple : _kText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        member.email,
                        style: const TextStyle(color: _kSub, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (_splitMethod == 'Custom' && isSelected)
                  SizedBox(
                    width: 90,
                    height: 36,
                    child: TextField(
                      controller: _customAmountsControllers[member.id],
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          color: _kPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: '0',
                        hintStyle: const TextStyle(color: _kSub),
                        prefixText: '₹',
                        prefixStyle: const TextStyle(
                            color: _kPurple, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: _kPurple.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _kPurple, width: 1.5),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  )
                else if (_splitMethod == 'Equal' &&
                    isSelected &&
                    _totalAmount > 0 &&
                    _selectedMembersCount > 0)
                  Text(
                    '₹${(_totalAmount / _selectedMembersCount).toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: _kPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
              ],
            ),
          );
        }),

        if (_splitMethod == 'Custom' && _totalAmount > 0) ...[
          const SizedBox(height: 12),
          _buildCustomSumStatus(),
        ],

        const SizedBox(height: 32),
        _buildPurpleButton(
          _isCreating ? 'CREATING EXPENSE...' : 'CREATE EXPENSE',
          _isCreating ? null : _submitExpense,
          _isCreating,
        ),
      ],
    );
  }

  Widget _buildMethodChip(String label) {
    final active = _splitMethod == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _splitMethod = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [_kPurpleDark, _kPurple])
                : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : _kSub,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSumStatus() {
    final sum = _customTotalSum;
    final diff = _totalAmount - sum;
    final isMatched = diff.abs() < 0.01;
    final text = isMatched
        ? 'Perfect! Split sum matches total.'
        : diff > 0
            ? '₹${diff.toStringAsFixed(2)} remaining to assign'
            : '₹${(-diff).toStringAsFixed(2)} over allocated';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isMatched ? _kSuccess : _kError).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isMatched ? _kSuccess : _kError).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isMatched
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: isMatched ? _kSuccess : _kError,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMatched ? _kSuccess : _kError,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
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
