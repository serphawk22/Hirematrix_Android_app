import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/premium_mentor_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';

class PremiumMentorScreen extends StatefulWidget {
  const PremiumMentorScreen({super.key});

  @override
  State<PremiumMentorScreen> createState() => _PremiumMentorScreenState();
}

class _PremiumMentorScreenState extends State<PremiumMentorScreen> {
  final controller = Get.put(PremiumMentorController());
  final _chatInputController = TextEditingController();
  final _scrollController = ScrollController();

  // Create plan controller fields
  final _formKey = GlobalKey<FormState>();
  String? _selectedCurrentRole;
  String? _selectedTargetRole;
  String? _selectedTimeline = '6 months';
  final _customCurrentRoleController = TextEditingController();
  final _customTargetRoleController = TextEditingController();

  final List<String> _timelineOptions = [
    '3 months',
    '6 months',
    '9 months',
    '12 months',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchMentorData().then((_) {
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    _scrollController.dispose();
    _customCurrentRoleController.dispose();
    _customTargetRoleController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
      final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);
      final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'AI Career Mentor',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: textColor,
            ),
          ),
          actions: [
            if (controller.hasSubscription.value) ...[
              IconButton(
                icon: const Icon(Icons.playlist_add),
                color: textColor,
                tooltip: 'Start Transition Plan',
                onPressed: () => _showCreatePlanBottomSheet(isDark, textColor, cardColor),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.crown, color: Colors.white, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      controller.subscription['plan_name']?.toString() ?? 'Premium',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        body: controller.isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.getPrimary(isDark),
                  ),
                ),
              )
            : !controller.hasSubscription.value
                ? _buildNotSubscribedView(isDark)
                : _buildDashboardView(isDark, textColor, subtitleColor, cardColor),
      );
    });
  }

  Widget _buildNotSubscribedView(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.lock,
              size: 64,
              color: AppColors.getPrimary(isDark),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Unlock AI Career Mentor',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Get 24/7 unlimited access to your personal AI Career coach, custom roadmap builder, smart goal synchronization, and skill gaps analysis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          _buildPremiumFeatureRow(
            isDark,
            FontAwesomeIcons.solidCommentDots,
            'Real-time Career Advice',
            'Chat regarding mock interviews, salary negotiations, and resume positioning.',
          ),
          _buildPremiumFeatureRow(
            isDark,
            FontAwesomeIcons.route,
            'Dynamic Learning Roadmaps',
            'Phased timelines matching actual certifications and resource topics.',
          ),
          _buildPremiumFeatureRow(
            isDark,
            FontAwesomeIcons.brain,
            'SMART Goal Synchronization',
            'AI auto-analyzes your chats to build, save, and score your progression objectives.',
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.plans),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              backgroundColor: AppColors.getPrimary(isDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.crown, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Upgrade Plan Now',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatureRow(
    bool isDark,
    dynamic icon,
    String title,
    String desc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon is IconData
                ? Icon(icon, color: AppColors.getPrimary(isDark), size: 20)
                : FaIcon(icon, color: AppColors.getPrimary(isDark), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(
    bool isDark,
    Color textColor,
    Color? subtitleColor,
    Color cardColor,
  ) {
    return _buildChatTab(isDark, textColor, subtitleColor, cardColor);
  }

  Widget _buildChatTab(
    bool isDark,
    Color textColor,
    Color? subtitleColor,
    Color cardColor,
  ) {
    return Column(
      children: [
        // Daily Usage banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.getPrimary(isDark).withOpacity(0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mentor Chat Window',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getPrimary(isDark),
                ),
              ),
              Text(
                controller.subscription['chat_limit'] != null
                    ? '${controller.usageToday.value}/${controller.subscription['chat_limit']} chats used today'
                    : 'Unlimited chats',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),

        // Quick Actions Grid/Scroll
        _buildQuickActions(isDark),

        // Chat Log
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            child: controller.chatHistory.isEmpty
                ? _buildEmptyChatLog(isDark, subtitleColor)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.chatHistory.length,
                    itemBuilder: (context, idx) {
                      final msg = controller.chatHistory[idx];
                      return _buildChatBubble(msg, isDark, textColor, cardColor);
                    },
                  ),
          ),
        ),

        // Typing indicator
        if (controller.isChatSending.value)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Typing...',
                    style: GoogleFonts.inter(
                      fontStyle: FontStyle.italic,
                      color: subtitleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Smart magical button
        _buildSmartMagicButton(isDark),

        // Follow up chips
        _buildFollowUpChips(isDark),

        // Input Box
        _buildInputBox(isDark, cardColor, textColor, subtitleColor),
      ],
    );
  }

  Widget _buildEmptyChatLog(bool isDark, Color? subtitleColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.robot,
              size: 48,
              color: AppColors.getPrimary(isDark).withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat with AI Career Mentor',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about interview prep, learning paths, salary negotiations, or start a structured career roadmap.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: subtitleColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final List<Map<String, dynamic>> actions = [
      {
        'label': 'Career Plan',
        'icon': FontAwesomeIcons.route,
        'prompt': 'Help me create a career plan to become a Software Engineer',
        'color': const Color(0xFF3B82F6)
      },
      {
        'label': 'Skill Gap',
        'icon': FontAwesomeIcons.chartSimple,
        'prompt': 'Do a skill gap analysis for my target role',
        'color': const Color(0xFF10B981)
      },
      {
        'label': 'Interview Prep',
        'icon': FontAwesomeIcons.microphone,
        'prompt': 'Help me prepare for interviews',
        'color': const Color(0xFF06B6D4)
      },
      {
        'label': 'Resume Review',
        'icon': FontAwesomeIcons.fileLines,
        'prompt': 'Review and optimize my resume',
        'color': const Color(0xFFF59E0B)
      },
      {
        'label': 'Salary Tips',
        'icon': FontAwesomeIcons.dollarSign,
        'prompt': 'Give me salary negotiation tips',
        'color': const Color(0xFFEF4444)
      },
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: actions.length,
        itemBuilder: (context, idx) {
          final act = actions[idx];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                _chatInputController.text = act['prompt'];
                _submitChat();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: act['color'].withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: act['color'].withOpacity(0.06),
                ),
                child: Row(
                  children: [
                    FaIcon(act['icon'], size: 12, color: act['color']),
                    const SizedBox(width: 6),
                    Text(
                      act['label'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: act['color'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(
    dynamic msg,
    bool isDark,
    Color textColor,
    Color cardColor,
  ) {
    final role = msg['role']?.toString();
    final content = msg['content']?.toString() ?? '';

    if (role == 'system_event') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.rotate,
                size: 10,
                color: isDark ? Colors.grey[400] : const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isUser = role == 'user';
    final isSystemError = msg['is_system_error'] == true;

    final bubbleBg = isUser
        ? AppColors.getPrimary(isDark)
        : (isSystemError
            ? Colors.red[900]?.withOpacity(0.2)
            : cardColor);

    final bubbleTextColor = isUser
        ? Colors.white
        : (isSystemError ? Colors.red[300]! : textColor);

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          );

    final premiumFeaturesList = msg['premium_features'] as List?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: borderRadius,
          border: isUser
              ? null
              : Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Text(
                'AI Career Mentor',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.getPrimary(isDark),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: bubbleTextColor,
              ),
            ),
            if (!isUser && premiumFeaturesList != null && premiumFeaturesList.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: premiumFeaturesList.map((feature) {
                  final label = feature.toString().replaceAll('_', ' ').capitalizeFirst ?? '';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(isDark).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getPrimary(isDark).withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmartMagicButton(bool isDark) {
    if (controller.activeSessions.isEmpty) return const SizedBox.shrink();

    final s = controller.activeSessions.first;
    final nextMilestones = s['next_milestones'] as List?;
    final roleName = s['target_role']?.toString() ?? 'career';
    final lastNudge = s['last_nudge']?.toString() ?? '';
    final milestone = (nextMilestones != null && nextMilestones.isNotEmpty) ? nextMilestones[0] : null;

    String continuePrompt = '';
    if (milestone != null) {
      continuePrompt = "I'm ready to work on '$milestone'. Any tips on getting started?";
    } else if (lastNudge.isNotEmpty && lastNudge.length < 100) {
      continuePrompt = "Regarding your advice \"$lastNudge\"—what's the best next step?";
    } else {
      continuePrompt = "I'm ready to keep moving on my $roleName goal. What's the next step?";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () {
            controller.switchContext('plan-${s['id']}', s['target_role'] ?? 'Active Plan');
            _chatInputController.text = continuePrompt;
            _submitChat();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 10, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    continuePrompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowUpChips(bool isDark) {
    if (controller.followUpChips.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.followUpChips.length,
        itemBuilder: (context, idx) {
          final chip = controller.followUpChips[idx];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                _chatInputController.text = chip;
                _submitChat();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.getPrimary(isDark).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  chip,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBox(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatInputController,
              onSubmitted: (_) => _submitChat(),
              style: GoogleFonts.inter(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask your AI career mentor anything...',
                hintStyle: GoogleFonts.inter(color: subtitleColor, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _submitChat,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(
                FontAwesomeIcons.paperPlane,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitChat() {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;
    _chatInputController.clear();
    controller.sendChatMessage(text).then((_) {
      _scrollToBottom();
    });
  }



  void _showCreatePlanBottomSheet(bool isDark, Color textColor, Color cardColor) {
    // Reset inputs
    _selectedCurrentRole = controller.userProfile['current_role']?.toString();
    _selectedTargetRole = controller.userProfile['target_role']?.toString();
    _selectedTimeline = '6 months';
    _customCurrentRoleController.clear();
    _customTargetRoleController.clear();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          final isCurrentCustom = _selectedCurrentRole == 'custom';
          final isTargetCustom = _selectedTargetRole == 'custom';

          final List<String> currentRoleOptions = [];
          if (controller.userProfile['current_role'] != null) {
            currentRoleOptions.add(controller.userProfile['current_role'].toString());
          }
          currentRoleOptions.addAll(controller.suggestedRoles.take(5));
          currentRoleOptions.add('custom');
          final finalCurrentOptions = currentRoleOptions.toSet().toList();

          final List<String> targetRoleOptions = [];
          if (controller.userProfile['target_role'] != null) {
            targetRoleOptions.add(controller.userProfile['target_role'].toString());
          }
          targetRoleOptions.addAll(controller.suggestedRoles.take(10));
          targetRoleOptions.add('custom');
          final finalTargetOptions = targetRoleOptions.toSet().toList();

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Career Roadmap',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current Role
                    Text(
                      'Current Position',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: finalCurrentOptions.contains(_selectedCurrentRole) ? _selectedCurrentRole : null,
                      dropdownColor: cardColor,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: finalCurrentOptions.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role == 'custom' ? 'Type Custom...' : role,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 14, color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          _selectedCurrentRole = val;
                        });
                      },
                      validator: (val) => val == null ? 'Current role is required' : null,
                    ),
                    if (isCurrentCustom) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _customCurrentRoleController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter your current role name',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) => isCurrentCustom && (val == null || val.trim().isEmpty)
                            ? 'Please enter your current role'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Target Role
                    Text(
                      'Target Role / Objective',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: finalTargetOptions.contains(_selectedTargetRole) ? _selectedTargetRole : null,
                      dropdownColor: cardColor,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: finalTargetOptions.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role == 'custom' ? 'Type Custom...' : role,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 14, color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          _selectedTargetRole = val;
                        });
                      },
                      validator: (val) => val == null ? 'Target role is required' : null,
                    ),
                    if (isTargetCustom) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _customTargetRoleController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter target job title (e.g. Senior DevOps)',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) => isTargetCustom && (val == null || val.trim().isEmpty)
                            ? 'Please enter target role'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Timeline
                    Text(
                      'Transition Timeline',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedTimeline,
                      dropdownColor: cardColor,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _timelineOptions.map((t) {
                        return DropdownMenuItem<String>(
                          value: t,
                          child: Text(
                            t,
                            style: GoogleFonts.inter(fontSize: 14, color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          _selectedTimeline = val;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Obx(() {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.isPlanCreating.value
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    final current = _selectedCurrentRole == 'custom'
                                        ? _customCurrentRoleController.text.trim()
                                        : _selectedCurrentRole!;
                                    final target = _selectedTargetRole == 'custom'
                                        ? _customTargetRoleController.text.trim()
                                        : _selectedTargetRole!;
                                    final timeline = _selectedTimeline!;

                                    final success = await controller.createCareerPlan(
                                      target,
                                      timeline,
                                      current,
                                    );
                                    if (success) {
                                      Get.back(); // close bottom sheet
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.getPrimary(isDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: controller.isPlanCreating.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Generate AI Career Roadmap',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
