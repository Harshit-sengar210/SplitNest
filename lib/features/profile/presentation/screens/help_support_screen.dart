import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock FAQ data
  final List<Map<String, String>> _allFaqs = [
    {
      'question': 'How do I split an expense unevenly?',
      'answer': 'When adding an expense, select "Split Members" to adjust the sharing split. You can split equally, by exact percentages, or by custom share amounts per person.',
    },
    {
      'question': 'How do I settle balances with a friend?',
      'answer': 'Go to the group, tap "Settle Up", select the friend, and record the payment method (cash, bank transfer, etc.). Once both approve, the balance updates immediately.',
    },
    {
      'question': 'Can I export group reports to PDF or CSV?',
      'answer': 'Yes! Open Group Details, navigate to the Settings tab of the group, and tap "Export Summary". You can download the report in either CSV or PDF formats.',
    },
    {
      'question': 'Is there a limit on group size or nests?',
      'answer': 'Standard accounts can have up to 5 active nests with 20 members each. Upgrade to SplitNest Gold for unlimited groups and advanced analytics.',
    },
    {
      'question': 'What should I do if a transaction is incorrect?',
      'answer': 'You can edit or delete an expense from the Expense Details screen. If there is a dispute, you can chat directly inside the group Nest to resolve it.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _allFaqs;
    return _allFaqs.where((faq) {
      final question = faq['question']!.toLowerCase();
      final answer = faq['answer']!.toLowerCase();
      return question.contains(_searchQuery.toLowerCase()) || answer.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Expanded state tracker for FAQs
  final Map<int, bool> _expandedFaqs = {};

  // Mock Feature Requests
  final List<Map<String, dynamic>> _featureRequests = [
    {'title': 'Automatic receipt scanning OCR', 'upvotes': 142, 'voted': false},
    {'title': 'Recurring subscription splitting', 'upvotes': 98, 'voted': false},
    {'title': 'Multi-currency conversion support', 'upvotes': 84, 'voted': false},
    {'title': 'Google Pay & Apple Pay integration', 'upvotes': 65, 'voted': false},
  ];

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _showReportProblemDialog() {
    final formKey = GlobalKey<FormState>();
    String category = 'Bug Report';
    String description = '';
    String email = '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Report a Problem',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF1F2937),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Let us know what went wrong. We will review your submission and follow up.',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280), fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        // Category Dropdown
                        Text(
                          'CATEGORY',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7B61FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: category,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7B61FF)),
                              items: ['Bug Report', 'Payment Issue', 'Account Access', 'Other']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => category = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Email Field
                        Text(
                          'YOUR EMAIL',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7B61FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter your email address',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 1),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Please enter your email';
                            if (!val.contains('@')) return 'Enter a valid email address';
                            return null;
                          },
                          onSaved: (val) => email = val ?? '',
                        ),
                        const SizedBox(height: 16),
                        // Description Field
                        Text(
                          'DESCRIPTION',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7B61FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          maxLines: 4,
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Describe the issue in detail...',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 1),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Please describe the issue';
                            if (val.length < 10) return 'Please provide a more detailed description';
                            return null;
                          },
                          onSaved: (val) => description = val ?? '',
                        ),
                        const SizedBox(height: 24),
                        // Submit Button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(29),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B61FF).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (formKey.currentState?.validate() ?? false) {
                                      formKey.currentState?.save();
                                      setModalState(() => isSubmitting = true);
                                      await Future.delayed(const Duration(seconds: 1));
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Report submitted successfully! Thank you.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                                            backgroundColor: const Color(0xFF10B981),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('Submit Report', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _build3DIcon(Icons.support_agent_rounded, const Color(0xFF7B61FF), size: 48, iconSize: 26),
                const SizedBox(height: 20),
                Text(
                  'Contact Support',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Our support team is available 24/7. Select your preferred contact method.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                // Contact Options
                _buildContactSupportOption(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF7B61FF),
                  title: 'Start Live Chat',
                  subtitle: 'Average reply time: 2 mins',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Starting Live Chat session...', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                        backgroundColor: const Color(0xFF7B61FF),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildContactSupportOption(
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFF6CA8FF),
                  title: 'Email Support',
                  subtitle: 'support@splitnest.com',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening email compose...', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                        backgroundColor: const Color(0xFF7B61FF),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFeatureRequestsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Feature Requests',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1F2937),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vote for features you want to see next, or request a new one!',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _featureRequests.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFFF3F4F6), height: 1),
                        itemBuilder: (context, index) {
                          final request = _featureRequests[index];
                          final hasVoted = request['voted'] as bool;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request['title'] as String,
                                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${request['upvotes']} upvotes',
                                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      if (hasVoted) {
                                        request['upvotes'] = (request['upvotes'] as int) - 1;
                                        request['voted'] = false;
                                      } else {
                                        request['upvotes'] = (request['upvotes'] as int) + 1;
                                        request['voted'] = true;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: hasVoted ? const Color(0xFF7B61FF) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: hasVoted ? const Color(0xFF7B61FF) : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.arrow_upward_rounded,
                                          color: hasVoted ? Colors.white : const Color(0xFF7B61FF),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasVoted ? 'Voted' : 'Vote',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: hasVoted ? Colors.white : const Color(0xFF7B61FF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B61FF).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Submit a feature request functionality placeholder', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                              backgroundColor: const Color(0xFF7B61FF),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                        ),
                        child: Text('Suggest a Feature', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCommunityGuidelinesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Guidelines',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1F2937),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GuidelineItem(
                          number: '1',
                          title: 'Be Transparent and Honest',
                          description: 'Only add genuine shared expenses. Misrepresenting costs undermines trust within your group.',
                        ),
                        SizedBox(height: 16),
                        _GuidelineItem(
                          number: '2',
                          title: 'Communicate Respectfully',
                          description: 'Use the Nest chat tab to resolve disputes constructively. Abuse, threats, or harassment will result in account ban.',
                        ),
                        SizedBox(height: 16),
                        _GuidelineItem(
                          number: '3',
                          title: 'Timely Settlements',
                          description: 'Strive to clear your dues promptly. Keep your friends updated if you need additional time to settle balances.',
                        ),
                        SizedBox(height: 16),
                        _GuidelineItem(
                          number: '4',
                          title: 'Protect Privacy',
                          description: 'Never share private details of group members outside the Nest app without their consent.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B61FF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                    ),
                    child: Text('I Understand', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactSupportOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: const Color(0xFF7B61FF).withOpacity(0.05),
        highlightColor: const Color(0xFF7B61FF).withOpacity(0.02),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B61FF).withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _build3DIcon(icon, iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280), fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(title: 'Help & Support'),
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
              child: CustomScrollView(
                slivers: [
                  // Header search bar section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How can we help you?',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF1F2937),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Search Bar (Premium Card Style)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B61FF).withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1F2937), fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search for articles, answers...',
                                hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 14),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7B61FF)),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF9CA3AF)),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Support Tools Categories (Grid Layout)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                          _buildCategoryCard(
                            icon: Icons.chat_bubble_outline_rounded,
                            iconColor: const Color(0xFF7B61FF),
                            title: 'Contact Support',
                            onTap: _showContactSupportDialog,
                          ),
                          _buildCategoryCard(
                            icon: Icons.report_problem_outlined,
                            iconColor: const Color(0xFF6CA8FF),
                            title: 'Report a Problem',
                            onTap: _showReportProblemDialog,
                          ),
                          _buildCategoryCard(
                            icon: Icons.lightbulb_outline_rounded,
                            iconColor: const Color(0xFFA78BFA),
                            title: 'Feature Requests',
                            onTap: _showFeatureRequestsDialog,
                          ),
                          _buildCategoryCard(
                            icon: Icons.gavel_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Guidelines',
                            onTap: _showCommunityGuidelinesDialog,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // FAQ Section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 40.0, bottom: 16.0),
                      child: Text(
                        _searchQuery.isEmpty ? 'FREQUENTLY ASKED QUESTIONS' : 'SEARCH RESULTS',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // FAQ List
                  if (faqs.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        child: Center(
                          child: Text(
                            'No FAQs found matching your query.',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 14),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final faq = faqs[index];
                            final faqIndex = _allFaqs.indexOf(faq);
                            final isExpanded = _expandedFaqs[faqIndex] ?? false;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildFaqAccordionCard(
                                faqIndex: faqIndex,
                                question: faq['question']!,
                                answer: faq['answer']!,
                                isExpanded: isExpanded,
                                onTap: () {
                                  setState(() {
                                    _expandedFaqs[faqIndex] = !isExpanded;
                                  });
                                },
                              ),
                            );
                          },
                          childCount: faqs.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 48),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: const Color(0xFF7B61FF).withOpacity(0.05),
          highlightColor: const Color(0xFF7B61FF).withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _build3DIcon(icon, iconColor, size: 38, iconSize: 20),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1F2937),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DIcon(IconData icon, Color primaryColor, {double size = 40, double iconSize = 20}) {
    return Container(
      width: size,
      height: size,
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
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildFaqAccordionCard({
    required int faqIndex,
    required String question,
    required String answer,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isExpanded ? const Color(0xFF7B61FF).withOpacity(0.15) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded 
                ? const Color(0xFF7B61FF).withOpacity(0.08) 
                : const Color(0xFF7B61FF).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            splashColor: const Color(0xFF7B61FF).withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: GoogleFonts.plusJakartaSans(
                        color: isExpanded ? const Color(0xFF7B61FF) : const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? const Color(0xFF7B61FF) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              child: Text(
                answer,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6B7280),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _GuidelineItem({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF7B61FF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6B7280),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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
