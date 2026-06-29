import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';

class ChatbotBottomSheet extends StatefulWidget {
  const ChatbotBottomSheet({super.key});

  @override
  State<ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class _ChatbotBottomSheetState extends State<ChatbotBottomSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _recruiterId;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'bot',
      'text':
          'Hi! I\'m HireMate, your AI recruitment assistant. Ask me anything about your jobs, applications, candidates, or interviews.',
      'time': 'Just now',
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      _recruiterId = authController.currentRecruiter?.id;
      if (_recruiterId != null) {
        _loadSuggestions();
      }
    });
  }

  Future<void> _loadSuggestions() async {
    try {
      final data = await _apiService.getChatbotSuggestions(_recruiterId!);
      if (data['success'] == true && data['suggestions'] != null) {
        setState(() {
          _suggestions = List<String>.from(data['suggestions']);
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading || _recruiterId == null) return;

    _inputController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text.trim(),
        'time': DateFormat('hh:mm a').format(DateTime.now()),
      });
      _isLoading = true;
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final data = await _apiService.askChatbot(_recruiterId!, text.trim());
      setState(() {
        _isTyping = false;
        if (data['success'] == true && data['answer'] != null) {
          _messages.add({
            'role': 'bot',
            'text': data['answer'],
            'time': DateFormat('hh:mm a').format(DateTime.now()),
          });
        } else {
          _messages.add({
            'role': 'bot',
            'text': data['answer'] ?? 'Sorry, I couldn\'t process that.',
            'time': DateFormat('hh:mm a').format(DateTime.now()),
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _isLoading = false;
        _messages.add({
          'role': 'bot',
          'text': 'Connection error. Make sure you are logged in.',
          'time': DateFormat('hh:mm a').format(DateTime.now()),
        });
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(isDark);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0D0F) : const Color(0xFFF8FCFA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1FB7B5), Color(0xFF53B86C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'HireMate AI',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(isDark);
                }

                final msg = _messages[index];
                final isBot = msg['role'] == 'bot';

                return Align(
                  alignment: isBot
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Column(
                      crossAxisAlignment: isBot
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isBot
                                ? (isDark
                                      ? const Color(0xFF162327)
                                      : const Color(0xFFE8F9F8))
                                : primaryColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: isBot
                                  ? const Radius.circular(4)
                                  : const Radius.circular(14),
                              bottomRight: isBot
                                  ? const Radius.circular(14)
                                  : const Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: GoogleFonts.inter(
                              color: isBot
                                  ? (isDark
                                        ? const Color(0xFFF8FAFC)
                                        : const Color(0xFF16212B))
                                  : Colors.white,
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          msg['time'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isDark
                                ? const Color(0xFF7A8B96)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Suggestions
          if (_suggestions.isNotEmpty)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        _suggestions[index],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF1FB7B5)
                              : const Color(0xFF0D8A90),
                        ),
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF162327)
                          : const Color(0xFFE8F9F8),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF23343A)
                            : const Color(0xFFD9ECE5),
                      ),
                      onPressed: () => _sendMessage(_suggestions[index]),
                    ),
                  );
                },
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF23343A)
                      : const Color(0xFFD9ECE5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF8FAFC) : Colors.black,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask about your hiring data...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      fillColor: isDark
                          ? const Color(0xFF0A0D0F)
                          : const Color(0xFFF8FCFA),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF23343A)
                              : const Color(0xFFD9ECE5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF23343A)
                              : const Color(0xFFD9ECE5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF1FB7B5)),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1FB7B5), Color(0xFF53B86C)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => _sendMessage(_inputController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162327) : const Color(0xFFE8F9F8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _TypingDot(),
            SizedBox(width: 4),
            _TypingDot(delay: 200),
            SizedBox(width: 4),
            _TypingDot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({this.delay = 0});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
          reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
        ),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
