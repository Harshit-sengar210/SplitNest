import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/success_animation.dart';
import '../../../../core/widgets/premium_image_selector.dart';
import '../../domain/models/group.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../nests/presentation/providers/nest_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens (lavender-purple palette from reference)
// ─────────────────────────────────────────────────────────────────────────────
const _kBg = Color(0xFFEAE6F8);
const _kCard = Colors.white;
const _kPurple = Color(0xFF7C5CBF);
const _kPurpleLight = Color(0xFFEDE9FA);
const _kPurpleDark = Color(0xFF5B3FA6);
const _kText = Color(0xFF1A1A2E);
const _kSub = Color(0xFF6B7280);

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _uploadedImageUrl;

  InviteMethod _selectedInviteMethod = InviteMethod.email;
  final List<PendingInvite> _pendingInvites = [];
  bool _isCreating = false;
  bool _showSuccess = false;
  String? _createdGroupId;
  
  // Tracks current step: 0 to 3
  int _currentStep = 0;
  
  // Auto Monthly cycle day selector
  int _selectedCycleDate = 1;
  
  // Custom range flag and dates (Step 2 Option B)
  bool _useCustomRange = false;
  DateTime _customRangeStart = DateTime.now();
  DateTime _customRangeEnd = DateTime.now().add(const Duration(days: 15));

  // Selected Nest type
  late NestTypeOption _selectedNestType;

  late AnimationController _pageController;
  late Animation<double> _fadeAnim;

  // ── 3D Type Options data ──────────────────────────────────────────────────
  static final List<NestTypeOption> _nestTypes = [
    const NestTypeOption(
      label: 'Home',
      emoji: '🏠',
      asset: 'assets/images/3d_house.png',
      typeName: 'Home',
    ),
    const NestTypeOption(
      label: 'Flat',
      emoji: '🏢',
      asset: 'assets/images/3d_apartment.png',
      typeName: 'Flatmates',
    ),
    const NestTypeOption(
      label: 'Office',
      emoji: '💼',
      asset: 'assets/images/3d_office.png',
      typeName: 'Office',
    ),
    const NestTypeOption(
      label: 'Travel',
      emoji: '✈️',
      asset: 'assets/images/3d_airplane.png',
      typeName: 'Travel',
    ),
    const NestTypeOption(
      label: 'Family',
      emoji: '👨👩👧',
      asset: 'assets/images/3d_people.png',
      typeName: 'Family',
    ),
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _selectedNestType = _nestTypes[0]; // Default selection to Home
    
    _pageController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim =
        CurvedAnimation(parent: _pageController, curve: Curves.easeInOut);
    _pageController.value = 1.0;
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _animateToStep(int step) async {
    await _pageController.reverse();
    setState(() => _currentStep = step);
    await _pageController.forward();
  }

  void _addInvite() {
    String value = '';
    bool isValid = false;
    switch (_selectedInviteMethod) {
      case InviteMethod.email:
        value = _emailController.text.trim();
        isValid = value.isNotEmpty && value.contains('@') && value.contains('.');
        if (!isValid && value.isNotEmpty) {
          _showError('Please enter a valid email address.');
          return;
        }
        break;
      case InviteMethod.phone:
        value = _phoneController.text.trim();
        isValid = value.isNotEmpty && value.length >= 8;
        if (!isValid && value.isNotEmpty) {
          _showError('Please enter a valid phone number.');
          return;
        }
        break;
      case InviteMethod.username:
        value = _usernameController.text.trim();
        isValid = value.isNotEmpty && value.length >= 3;
        if (!isValid && value.isNotEmpty) {
          _showError('Username must be at least 3 characters.');
          return;
        }
        break;
      case InviteMethod.inviteCode:
      case InviteMethod.shareLink:
        return;
    }
    if (value.isEmpty) return;
    if (_pendingInvites.any((inv) => inv.value == value)) {
      _showError('This member has already been invited.');
      return;
    }
    setState(() {
      _pendingInvites
          .add(PendingInvite(value: value, method: _selectedInviteMethod));
      _emailController.clear();
      _phoneController.clear();
      _usernameController.clear();
    });
  }

  void _removeInvite(int index) =>
      setState(() => _pendingInvites.removeAt(index));

  Future<void> _onSubmit() async {
    setState(() => _isCreating = true);
    try {
      final nestRepository = ref.read(nestRepositoryProvider);

      final inviteEmails = _pendingInvites
          .where((inv) => inv.method == InviteMethod.email)
          .map((inv) => inv.value)
          .toList();
      final inviteUsernames = _pendingInvites
          .where((inv) => inv.method == InviteMethod.username)
          .map((inv) => inv.value)
          .toList();
      final invitePhones = _pendingInvites
          .where((inv) => inv.method == InviteMethod.phone)
          .map((inv) => inv.value)
          .toList();

      final newNest = await nestRepository.createNest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedNestType.typeName,
        currency: 'INR',
        coverImage: _uploadedImageUrl ?? _selectedNestType.asset,
        inviteEmails: inviteEmails,
        inviteUsernames: inviteUsernames,
        invitePhones: invitePhones,
        settlementCycleDate: _selectedCycleDate,
        customStartDate: _useCustomRange ? _customRangeStart : null,
        customEndDate: _useCustomRange ? _customRangeEnd : null,
      );

      // Update the activeNestId in the auth notifier
      await ref.read(authNotifierProvider.notifier).updateActiveNestId(newNest.nestId);
      
      if (mounted) {
        setState(() {
          _isCreating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Nest Created Successfully',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );

        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to create nest: $e');
        setState(() => _isCreating = false);
      }
    }
  }

  void _onSuccessComplete() {
    context.go('/dashboard');
  }

  bool get _hasUnsavedChanges =>
      _nameController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty ||
      _pendingInvites.isNotEmpty;

  // Day suffix calculator
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  // Premium calendar picker launcher
  Future<void> _pickCustomDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _customRangeStart : _customRangeEnd,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7B61FF), // premium purple
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A2E),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7B61FF),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _customRangeStart = picked;
          if (_customRangeEnd.isBefore(_customRangeStart)) {
            _customRangeEnd = _customRangeStart.add(const Duration(days: 1));
          }
        } else {
          _customRangeEnd = picked;
          if (_customRangeEnd.isBefore(_customRangeStart)) {
            _customRangeStart = _customRangeEnd.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return SuccessAnimation(
        title: 'Nest Created!',
        subtitle:
            '${_nameController.text.trim()} is ready.\nStart adding expenses!',
        onComplete: _onSuccessComplete,
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      if (_currentStep > 0) {
                        _animateToStep(_currentStep - 1);
                      } else if (_hasUnsavedChanges) {
                        _confirmDiscard();
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
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _kText, size: 18),
                    ),
                  ),
                  const Spacer(),
                  // Step badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kPurpleLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Step ${_currentStep + 1} of 4',
                      style: const TextStyle(
                        color: _kPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Title ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStepTitle(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _kText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStepSubtitle(),
                    style: const TextStyle(fontSize: 13, color: _kSub),
                  ),
                ],
              ),
            ),

            // ── Progress bar (4 segments) ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 3 ? 6.0 : 0.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _currentStep >= index ? 1.0 : 0.0,
                          minHeight: 5,
                          backgroundColor: _kPurple.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(_kPurple),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildStepContent(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottom(),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Nest Information';
      case 1:
        return 'How do you want to track this Nest?';
      case 2:
        return 'Add Members';
      case 3:
        return 'Review Nest';
      default:
        return 'Create Nest';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Setup your group information';
      case 1:
        return 'Define the recurring cycle or calendar range';
      case 2:
        return 'Add roommate, trip mate, or family members';
      case 3:
        return 'Check details before final submission';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Nest Information ───────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        // Upload Cover Image
        Center(
          child: GestureDetector(
            onTap: () async {
              if (_isCreating) return;
              final url = await PremiumImageSelector.show(context, title: 'Nest Cover');
              if (url != null && mounted) {
                setState(() {
                  _uploadedImageUrl = url;
                });
              }
            },
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: _kCard,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: _uploadedImageUrl != null 
                    ? DecorationImage(image: NetworkImage(_uploadedImageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: _uploadedImageUrl == null 
                  ? const Icon(Icons.add_a_photo_rounded, color: _kPurple, size: 28)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text('Upload Cover', style: TextStyle(color: _kSub, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),

        // Input card for name & description
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _PurpleTextField(
                controller: _nameController,
                hint: 'Nest Name *',
                prefixIcon: Icons.people_alt_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nest name is required';
                  }
                  if (val.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
                enabled: !_isCreating,
              ),
              Divider(height: 1, color: _kBg),
              _PurpleTextField(
                controller: _descriptionController,
                hint: 'Description',
                prefixIcon: Icons.description_outlined,
                enabled: !_isCreating,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Nest Type selection
        const Text(
          'Nest Type',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _kText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select the type that best fits this nest space (Only one can be selected)',
          style: TextStyle(fontSize: 13, color: _kSub),
        ),
        const SizedBox(height: 18),

        // Grid of 3D selectable cards (🏠 Home, 🏢 Flat, 💼 Office, ✈️ Travel, 👨‍👩‍👧 Family)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _nestTypes.map((option) {
            final isSelected = _selectedNestType == option;
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 40 - 24) / 3, // Fits 3 in a row
              height: 110,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _3DNestTypeCard(
                  option: option,
                  isSelected: isSelected,
                  onTap: () {
                    if (!_isCreating) {
                      setState(() {
                        _selectedNestType = option;
                      });
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Step 2: Settlement Cycle ───────────────────────────────────────────────
  Widget _buildStep2() {
    final now = DateTime.now();
    final currentMonthName = DateFormat('MMM').format(now);
    
    // Auto Monthly next month preview
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final nextMonthName = DateFormat('MMM').format(nextMonth);
    
    final nextMonthPlusOne = DateTime(now.year, now.month + 2, 1);
    final nextMonthPlusOneName = DateFormat('MMM').format(nextMonthPlusOne);

    final day = _selectedCycleDate;
    final suffix = _getDaySuffix(day);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        
        // Option A: Auto Monthly Selectable Header Card
        GestureDetector(
          onTap: () => setState(() => _useCustomRange = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: !_useCustomRange ? const Color(0xFFEDE9FA) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: !_useCustomRange ? _kPurple : const Color(0xFFE5E7EB),
                width: !_useCustomRange ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.autorenew_rounded,
                      color: !_useCustomRange ? _kPurple : _kSub,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Auto Monthly',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: !_useCustomRange ? _kPurpleDark : _kText,
                      ),
                    ),
                    const Spacer(),
                    Radio<bool>(
                      value: false,
                      groupValue: _useCustomRange,
                      onChanged: (val) {
                        setState(() => _useCustomRange = val!);
                      },
                      activeColor: _kPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Automatically generates billing cycles every month on your chosen day.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: _kSub,
                  ),
                ),
                if (!_useCustomRange) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Select Day of Month: $day$suffix',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _kPurpleDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Day Selector 1-31
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 31,
                      itemBuilder: (context, index) {
                        final d = index + 1;
                        final isSelected = _selectedCycleDate == d;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCycleDate = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? _kPurple : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$d',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : _kText,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System automatically creates:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.date_range_rounded, size: 14, color: _kPurple),
                            const SizedBox(width: 6),
                            Text(
                              '$day $currentMonthName → $day $nextMonthName',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _kText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.date_range_rounded, size: 14, color: _kPurple),
                            const SizedBox(width: 6),
                            Text(
                              '$day $nextMonthName → $day $nextMonthPlusOneName',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _kText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 18),
        
        // Option B: Custom Range Selectable Header Card
        GestureDetector(
          onTap: () => setState(() => _useCustomRange = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _useCustomRange ? const Color(0xFFEDE9FA) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _useCustomRange ? _kPurple : const Color(0xFFE5E7EB),
                width: _useCustomRange ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      color: _useCustomRange ? _kPurple : _kSub,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Custom Range',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _useCustomRange ? _kPurpleDark : _kText,
                      ),
                    ),
                    const Spacer(),
                    Radio<bool>(
                      value: true,
                      groupValue: _useCustomRange,
                      onChanged: (val) {
                        setState(() => _useCustomRange = val!);
                      },
                      activeColor: _kPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a specific start and end date for a unique billing event (e.g. temporary trips).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: _kSub,
                  ),
                ),
                if (_useCustomRange) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickCustomDate(true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: _kSub,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('d MMM yyyy').format(_customRangeStart),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _kText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickCustomDate(false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: _kSub,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('d MMM yyyy').format(_customRangeEnd),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _kText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: _kPurple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active Range: ${DateFormat('d MMM').format(_customRangeStart)} → ${DateFormat('d MMM').format(_customRangeEnd)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _kText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Add Members ────────────────────────────────────────────────────
  Widget _buildStep3() {
    final displayInvites = [InviteMethod.email, InviteMethod.phone, InviteMethod.shareLink];
    final memberCount = _pendingInvites.length + 1;
    final memberText = memberCount == 1 ? '1 Member (You)' : '$memberCount Members (You + ${_pendingInvites.length} Invited)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        // Premium 3D members illustration banner
        Center(
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD8B4FE).withOpacity(0.35),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: _FloatingAnimationWrapper(
              child: Image.asset(
                'assets/images/3d_people.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Member Count Badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _kPurpleLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPurple.withOpacity(0.2)),
            ),
            child: Text(
              memberText,
              style: GoogleFonts.plusJakartaSans(
                color: _kPurpleDark,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Invite method tabs
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: displayInvites.map((method) {
              final isActive = _selectedInviteMethod == method;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedInviteMethod = method),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? _kPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _inviteMethodLabel(method),
                        style: TextStyle(
                          color: isActive ? Colors.white : _kSub,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Invite input details
        _buildInviteInput(),
        const SizedBox(height: 20),

        // Invited members chips list
        if (_pendingInvites.isNotEmpty) ...[
          const Row(
            children: [
              Text(
                'Invited Members',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMemberChip('You (Admin)', 'Creator',
              Icons.star_rounded, true, null),
          const SizedBox(height: 8),
          ...List.generate(_pendingInvites.length, (i) {
            final inv = _pendingInvites[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildMemberChip(
                inv.value,
                _inviteMethodLabel(inv.method),
                _inviteMethodIcon(inv.method),
                false,
                () => _removeInvite(i),
              ),
            );
          }),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.group_add_outlined, color: _kSub, size: 44),
                const SizedBox(height: 12),
                Text('No members invited yet',
                    style: GoogleFonts.plusJakartaSans(
                        color: _kText,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text('Add members or share link to start splitting',
                    style: GoogleFonts.plusJakartaSans(color: _kSub, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInviteInput() {
    switch (_selectedInviteMethod) {
      case InviteMethod.email:
        return _InviteRow(
          controller: _emailController,
          hint: 'Member Email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          enabled: !_isCreating,
          onAdd: _addInvite,
        );
      case InviteMethod.phone:
        return _InviteRow(
          controller: _phoneController,
          hint: 'Member Phone Number',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_android_rounded,
          enabled: !_isCreating,
          onAdd: _addInvite,
        );
      case InviteMethod.shareLink:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPurpleLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.link_rounded, color: _kPurple, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Invite Link',
                      style: GoogleFonts.plusJakartaSans(
                        color: _kText,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'https://splitnest.app/join/split-${_nameController.text.isNotEmpty ? _nameController.text.trim().toLowerCase().replaceAll(' ', '-') : 'nest'}',
                      style: GoogleFonts.plusJakartaSans(
                        color: _kPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: _kPurple, size: 20),
                onPressed: () {
                  final link = 'https://splitnest.app/join/split-${_nameController.text.isNotEmpty ? _nameController.text.trim().toLowerCase().replaceAll(' ', '-') : 'nest'}';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite link copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: _kPurple,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMemberChip(String name, String subtitle, IconData icon,
      bool isCreator, VoidCallback? onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCreator ? _kPurpleLight : _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCreator
              ? _kPurple.withOpacity(0.3)
              : _kBg,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                isCreator ? _kPurple.withOpacity(0.15) : _kBg,
            child: isCreator
                ? Icon(icon, color: _kPurple, size: 18)
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: _kPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                      color: isCreator ? _kPurple : _kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style:
                        const TextStyle(color: _kSub, fontSize: 11)),
              ],
            ),
          ),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFFEF4444), size: 15),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 4: Review Nest ────────────────────────────────────────────────────
  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kPurpleLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kPurple.withOpacity(0.15)),
            ),
            child: Icon(icon, color: _kPurple, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: _kSub,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Review Nest ────────────────────────────────────────────────────
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        
        // High fidelity 3D Summary Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C5CBF).withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFEDE9FA),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header banner with gradient, backdropped orbs, and selected 3D image in micro-animation
              Container(
                height: 90,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFEDE9FA),
                      Color(0xFFF3EFFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Backdropped Orbs
                    Positioned(
                      left: -10,
                      top: -10,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      bottom: -5,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7C5CBF).withOpacity(0.06),
                        ),
                      ),
                    ),
                    // White floating backdrop circle
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C5CBF).withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    // Floating 3D image
                    _FloatingAnimationWrapper(
                      child: Image.asset(
                        _selectedNestType.asset,
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Nest Name
                    _buildSummaryItem(
                      icon: Icons.people_alt_outlined,
                      label: 'NEST NAME',
                      content: Text(
                        _nameController.text.trim(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _kText,
                        ),
                      ),
                    ),
                    
                    // 2. Description (optional)
                    if (_descriptionController.text.trim().isNotEmpty)
                      _buildSummaryItem(
                        icon: Icons.description_outlined,
                        label: 'DESCRIPTION',
                        content: Text(
                          _descriptionController.text.trim(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: _kText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    
                    // 3. Nest Type
                    _buildSummaryItem(
                      icon: Icons.category_outlined,
                      label: 'NEST TYPE',
                      content: Row(
                        children: [
                          Text(
                            _selectedNestType.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedNestType.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _kText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 4. Settlement Cycle
                    _buildSummaryItem(
                      icon: _useCustomRange ? Icons.date_range_rounded : Icons.autorenew_rounded,
                      label: 'SETTLEMENT CYCLE',
                      content: Text(
                        _useCustomRange
                            ? 'Custom: ${DateFormat('d MMM').format(_customRangeStart)} → ${DateFormat('d MMM yyyy').format(_customRangeEnd)}'
                            : 'Auto Monthly (on the ${_selectedCycleDate}${_getDaySuffix(_selectedCycleDate)})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _kText,
                        ),
                      ),
                    ),
                    
                    // 5. Members Count & Member Details
                    _buildSummaryItem(
                      icon: Icons.group_outlined,
                      label: 'MEMBERS',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kPurpleLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kPurple.withOpacity(0.2)),
                            ),
                            child: Text(
                              '${_pendingInvites.length + 1} Members',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _kPurpleDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildMemberRow('You', 'Admin', true),
                          ..._pendingInvites.take(2).map((m) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: _buildMemberRow(
                                  m.value,
                                  _inviteMethodLabel(m.method),
                                  false,
                                ),
                              )),
                          if (_pendingInvites.length > 2)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '+ ${_pendingInvites.length - 2} more members',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: _kSub,
                                  fontWeight: FontWeight.w600,
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
      ],
    );
  }

  Widget _buildMemberRow(String name, String subtitle, bool isAdmin) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isAdmin ? _kPurpleLight : const Color(0xFFF3F4F6),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isAdmin ? _kPurple : const Color(0xFF4B5563),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kText,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: _kSub,
                ),
              ),
            ],
          ),
        ),
        if (isAdmin)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kPurpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Admin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: _kPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ── Bottom action ─────────────────────────────────────────────────────────
  Widget _buildBottom() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: _kBg,
      child: _currentStep == 0
          ? _PurpleButton(
              label: '→  CONTINUE TO CYCLE',
              isLoading: false,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _animateToStep(1);
                }
              },
            )
          : _currentStep == 1
              ? _PurpleButton(
                  label: '→  CONTINUE TO INVITES',
                  isLoading: false,
                  onPressed: () {
                    _animateToStep(2);
                  },
                )
              : _currentStep == 2
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PurpleButton(
                          label: '→  CONTINUE TO REVIEW',
                          isLoading: false,
                          onPressed: () {
                            _animateToStep(3);
                          },
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _pendingInvites.clear();
                            });
                            _animateToStep(3);
                          },
                          child: Text(
                            'Skip For Now',
                            style: GoogleFonts.plusJakartaSans(
                              color: _kPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_pendingInvites.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${_pendingInvites.length + 1} members will be in this nest',
                              style: const TextStyle(color: _kSub, fontSize: 13),
                            ),
                          ),
                        _PurpleButton(
                          label: _isCreating ? '' : 'Create Nest',
                          isLoading: _isCreating,
                          onPressed: _onSubmit,
                        ),
                      ],
                    ),
    );
  }

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard changes?',
            style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        content: const Text('Your unsaved data will be lost.',
            style: TextStyle(color: _kSub)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep', style: TextStyle(color: _kPurple))),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('Discard',
                  style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
  }

  String _inviteMethodLabel(InviteMethod m) {
    switch (m) {
      case InviteMethod.email:
        return 'Email';
      case InviteMethod.phone:
        return 'Phone';
      case InviteMethod.username:
        return 'Username';
      case InviteMethod.inviteCode:
        return 'Code';
      case InviteMethod.shareLink:
        return 'Link';
    }
  }

  IconData _inviteMethodIcon(InviteMethod m) {
    switch (m) {
      case InviteMethod.email:
        return Icons.email_outlined;
      case InviteMethod.phone:
        return Icons.phone_android_rounded;
      case InviteMethod.username:
        return Icons.alternate_email_rounded;
      case InviteMethod.inviteCode:
        return Icons.qr_code_rounded;
      case InviteMethod.shareLink:
        return Icons.link_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting data class
// ─────────────────────────────────────────────────────────────────────────────
class NestTypeOption {
  final String label;
  final String emoji;
  final String asset;
  final String typeName;

  const NestTypeOption({
    required this.label,
    required this.emoji,
    required this.asset,
    required this.typeName,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card widget
// ─────────────────────────────────────────────────────────────────────────────
class _3DNestTypeCard extends StatefulWidget {
  final NestTypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _3DNestTypeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_3DNestTypeCard> createState() => _3DNestTypeCardState();
}

class _3DNestTypeCardState extends State<_3DNestTypeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(widget.isSelected ? 1.04 : (_isHovered ? 1.02 : 1.0)),
          decoration: BoxDecoration(
            color: widget.isSelected ? _kPurpleLight : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected ? _kPurple : const Color(0xFFE5E7EB),
              width: widget.isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? _kPurple.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: widget.isSelected ? 16 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3D image illustration
              Expanded(
                child: Center(
                  child: Image.asset(
                    widget.option.asset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.option.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.option.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected ? _kPurpleDark : _kText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purple text field
// ─────────────────────────────────────────────────────────────────────────────
class _PurpleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  const _PurpleTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      style: const TextStyle(color: _kText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSub, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: _kPurple, size: 20),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invite row (input + add button)
// ─────────────────────────────────────────────────────────────────────────────
class _InviteRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool enabled;
  final VoidCallback onAdd;
  final TextInputType? keyboardType;

  const _InviteRow({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.enabled,
    required this.onAdd,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onAdd(),
              style: const TextStyle(color: _kText, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _kSub, fontSize: 14),
                prefixIcon: Icon(prefixIcon, color: _kPurple, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: enabled ? onAdd : null,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kPurple,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info box (for code/link invite methods)
// ─────────────────────────────────────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoBox(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPurpleLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _kPurple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _kText,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 3),
                Text(body,
                    style: const TextStyle(color: _kSub, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purple CTA button
// ─────────────────────────────────────────────────────────────────────────────
class _PurpleButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PurpleButton(
      {required this.label,
      required this.isLoading,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPurpleDark, _kPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _kPurple.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating micro-animation wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingAnimationWrapper extends StatefulWidget {
  final Widget child;
  const _FloatingAnimationWrapper({required this.child});

  @override
  State<_FloatingAnimationWrapper> createState() => _FloatingAnimationWrapperState();
}

class _FloatingAnimationWrapperState extends State<_FloatingAnimationWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}
