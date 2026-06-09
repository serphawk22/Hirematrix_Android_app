import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/messages_controller.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final MessagesController controller;
  late final int recruiterId;
  late final int applicationId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    recruiterId = args['recruiter_id'] as int? ?? 0;
    applicationId = args['application_id'] as int? ?? 0;

    controller = Get.put(
      MessagesController(
        recruiterId: recruiterId,
        applicationId: applicationId,
      ),
      tag: 'chat_$recruiterId',
    );
  }

  @override
  void dispose() {
    Get.delete<MessagesController>(tag: 'chat_$recruiterId');
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "R";
    final parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = AppColors.getBackground(isDark);
      final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
      final subtitleColor = isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF6B7280);
      final barColor = isDark ? AppColors.getCard(isDark) : Colors.white;

      return Scaffold(
        backgroundColor: mainBg,
        appBar: AppBar(
          backgroundColor: barColor,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF6366F1),
                child: Text(
                  _getInitials(controller.recruiterName.value),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.recruiterName.value.isEmpty
                          ? 'Recruiter'
                          : controller.recruiterName.value,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Live Connection',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: controller.isLoading.value && controller.messages.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF6366F1),
                      ),
                    )
                  : controller.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: subtitleColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No messages yet.',
                            style: GoogleFonts.inter(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send a message to start the conversation.',
                            style: GoogleFonts.inter(
                              color: subtitleColor.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final item = controller.messages[index];
                        final fromCandidate =
                            (item['sender_role'] ?? '') == 'candidate';
                        final msgText = item['message'] ?? '';
                        final timestamp = item['created_at'] != null
                            ? DateFormat(
                                'MMM dd, hh:mm a',
                              ).format(DateTime.parse(item['created_at']))
                            : '';

                        return Align(
                          alignment: fromCandidate
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: fromCandidate
                                  ? (isDark
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF6366F1))
                                  : (isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(
                                  fromCandidate ? 16 : 2,
                                ),
                                bottomRight: Radius.circular(
                                  fromCandidate ? 2 : 16,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msgText,
                                  style: GoogleFonts.inter(
                                    color: fromCandidate
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.grey[200]
                                              : const Color(0xFF1F2937)),
                                    fontSize: 14.5,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    timestamp,
                                    style: GoogleFonts.inter(
                                      color: fromCandidate
                                          ? Colors.white70
                                          : subtitleColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: barColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: controller.messageController,
                          maxLines: 4,
                          minLines: 1,
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: GoogleFonts.inter(
                              color: subtitleColor,
                              fontSize: 13.5,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      return controller.isSending.value
                          ? const SizedBox(
                              width: 44,
                              height: 44,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : InkWell(
                              onTap: controller.sendMessage,
                              borderRadius: BorderRadius.circular(24),
                              child: Ink(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFF6366F1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  size: 22,
                                ),
                              ),
                            );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
