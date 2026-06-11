import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<SupportMessage> _messages = [];
  bool _isSending = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _messages.add(const SupportMessage(
      text: 'Hi! Welcome to Live Chat support. Send your question and I will reply as soon as possible.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final recruiterId = auth.currentRecruiter?.id;
    final text = _messageController.text.trim();

    if (recruiterId == null || text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(SupportMessage(text: text, isUser: true));
      _isSending = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final response = await ApiService().sendSupportMessage(
        recruiterId,
        text,
        sessionId: _sessionId,
      );

      final success = response['success'] == true;
      final messageText = success
          ? response['message']?.toString() ?? 'No response received.'
          : response['message']?.toString() ?? response['error']?.toString() ?? 'Unable to send message.';

      setState(() {
        _sessionId = response['session_id']?.toString() ?? _sessionId;
        _messages.add(SupportMessage(text: messageText, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(SupportMessage(
          text: 'Unable to reach support right now. Please try again later.',
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Live Chat', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_messages[index], isDark);
              },
            ),
          ),
          if (_isSending)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2)),
                  const SizedBox(width: 12),
                  Text('Sending...', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type your question here...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                      filled: true,
                      fillColor: isDark ? AppColors.bgDark : const Color(0xFFF2F4F7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!_isSending) {
                        _sendMessage();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.getPrimary(isDark),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isSending ? null : _sendMessage,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.send_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(SupportMessage message, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 10, left: message.isUser ? 60 : 0, right: message.isUser ? 0 : 60),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: message.isUser
                  ? AppColors.getPrimary(isDark)
                  : (isDark ? Colors.white10 : const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                bottomRight: Radius.circular(message.isUser ? 4 : 18),
              ),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: message.isUser ? Colors.white : AppColors.getText(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportMessage {
  final String text;
  final bool isUser;

  const SupportMessage({required this.text, required this.isUser});
}
