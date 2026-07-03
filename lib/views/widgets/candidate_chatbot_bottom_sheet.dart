import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class CandidateChatbotBottomSheet extends StatefulWidget {
  const CandidateChatbotBottomSheet({super.key});

  @override
  State<CandidateChatbotBottomSheet> createState() =>
      _CandidateChatbotBottomSheetState();
}

class _CandidateChatbotBottomSheetState
    extends State<CandidateChatbotBottomSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _candidateId;
  String? _chatSessionId;

  // Voice Chat
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  late AnimationController _pulseController;

  bool _isMentorTopic(String text) {
    final lower = text.toLowerCase();
    const mentorKeywords = [
      'career plan',
      'career path',
      'career goal',
      'become a',
      'career growth',
      'career advice',
      'career roadmap',
      'skill gap',
      'skill development',
      'upskill',
      'learn skill',
      'improve my skill',
      'course recommendation',
      'certification',
      'interview',
      'mock interview',
      'interview question',
      'interview tips',
      'resume',
      'cv review',
      'optimize my resume',
      'resume feedback',
      'resume tips',
      'salary',
      'negotiat',
      'compensation',
      'pay raise',
      'offer negotiation',
    ];
    return mentorKeywords.any((kw) => lower.contains(kw));
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _messages.add({
      'role': 'bot',
      'text':
          'Hi! I\'m HireMate, your AI career assistant. Ask me anything about matching jobs, remote roles, or your profile.',
      'time': 'Just now',
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Get.find<AuthController>();
      _candidateId = authController.currentUser.value['id']?.toString();
      if (_candidateId != null) {
        _loadSuggestions();
      }
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _pulseController.repeat(reverse: true);
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _pulseController.stop();
          _pulseController.reset();
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _pulseController.stop();
          _pulseController.reset();
        });
      }
    });
  }

  Future<void> _loadSuggestions() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/${ApiConstants.chatbotSuggestions}?candidate_id=$_candidateId',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['suggestions'] != null) {
          setState(() {
            _suggestions = List<String>.from(data['suggestions']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }

  void _listen() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
        _pulseController.stop();
        _pulseController.reset();
      });
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
                _pulseController.stop();
                _pulseController.reset();
              });
              if (_inputController.text.isNotEmpty) {
                _sendMessage(_inputController.text);
              }
            }
          }
        },
        onError: (val) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _pulseController.stop();
              _pulseController.reset();
            });
          }
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _pulseController.repeat(reverse: true);
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _inputController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _pulseController.reset();
      });
      _speech.stop();
    }
  }

  void _speak(String text) async {
    // Strip emojis or special chars if needed, but basic TTS handles it OK
    await _flutterTts.speak(text.replaceAll(RegExp(r'<[^>]*>|💡'), '').trim());
  }

  Future<void> _sendMessage(String text, {bool forceMentor = false}) async {
    if (text.trim().isEmpty || _isLoading || _candidateId == null) return;

    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
        _pulseController.stop();
      });
    }

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
      final useMentor = forceMentor || _isMentorTopic(text);
      final url = useMentor
          ? '${ApiConstants.baseUrl}/${ApiConstants.premiumMentorChat}'
          : '${ApiConstants.baseUrl}/${ApiConstants.chatbotAsk}';

      final body = useMentor
          ? {
              'candidate_id': _candidateId!,
              'message': text.trim(),
              if (_chatSessionId != null) 'session_id': _chatSessionId!,
            }
          : {'candidate_id': _candidateId!, 'question': text.trim()};

      final response = await http.post(Uri.parse(url), body: body);

      setState(() {
        _isTyping = false;
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (useMentor) {
            if (data['status'] == 'success' || data['message'] != null) {
              if (data['session_id'] != null) {
                _chatSessionId = data['session_id'];
              }
              final replyText = data['message'] ?? '...';
              _messages.add({
                'role': 'bot',
                'text': replyText,
                'time': DateFormat('hh:mm a').format(DateTime.now()),
                'features': data['premium_features'] != null
                    ? jsonEncode(data['premium_features'])
                    : '',
              });
              
              String fullSpeakText = replyText;

              if (data['progress_tracking'] != null &&
                  data['progress_tracking']['last_nudge'] != null) {
                final nudge = data['progress_tracking']['last_nudge'];
                _messages.add({
                  'role': 'bot',
                  'text': '💡 $nudge',
                  'time': DateFormat('hh:mm a').format(DateTime.now()),
                });
                fullSpeakText += '. $nudge';
              }
              
              _speak(fullSpeakText);

            } else if (data['error'] != null) {
              final err = data['error'];
              _messages.add({
                'role': 'bot',
                'text': err,
                'time': DateFormat('hh:mm a').format(DateTime.now()),
              });
              _speak(err);
            } else {
              _messages.add({
                'role': 'bot',
                'text': 'Sorry, I couldn\'t process that right now.',
                'time': DateFormat('hh:mm a').format(DateTime.now()),
              });
              _speak('Sorry, I couldn\'t process that right now.');
            }
          } else {
            if (data['success'] == true && data['answer'] != null) {
              final ans = data['answer'];
              _messages.add({
                'role': 'bot',
                'text': ans,
                'time': DateFormat('hh:mm a').format(DateTime.now()),
              });
              _speak(ans);
            } else {
              final ans = data['answer'] ?? 'Sorry, I couldn\'t process that.';
              _messages.add({
                'role': 'bot',
                'text': ans,
                'time': DateFormat('hh:mm a').format(DateTime.now()),
              });
              _speak(ans);
            }
          }
        } else {
          _messages.add({
            'role': 'bot',
            'text': 'Server error. Please try again.',
            'time': DateFormat('hh:mm a').format(DateTime.now()),
          });
          _speak('Server error. Please try again.');
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
        _speak('Connection error. Make sure you are logged in.');
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
    _pulseController.dispose();
    _flutterTts.stop();
    _speech.stop();
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
                    Icons.chat_outlined,
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
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isBot
                                ? (isDark ? const Color(0xFF162327) : const Color(0xFFE8F9F8))
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
                                  ? (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF16212B))
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
                            color: isDark ? const Color(0xFF7A8B96) : const Color(0xFF94A3B8),
                          ),
                        ),
                        if (msg['features'] != null && msg['features']!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (jsonDecode(msg['features']!) as List)
                                  .map<Widget>(
                                    (feature) => Chip(
                                      label: Text(
                                        feature is String
                                            ? feature
                                            : (feature['name']?.toString() ?? ''),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isBot
                                              ? (isDark ? Colors.black : Colors.white)
                                              : Colors.black,
                                        ),
                                      ),
                                      backgroundColor: isBot
                                          ? (isDark
                                              ? const Color(0xFF1FB7B5)
                                              : const Color(0xFF1FB7B5))
                                          : Colors.grey[200],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Actions
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickAction('Career Plan', isDark),
                _buildQuickAction('Skill Gap', isDark),
                _buildQuickAction('Interview Prep', isDark),
                _buildQuickAction('Resume Review', isDark),
                _buildQuickAction('Salary Tips', isDark),
              ],
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
                          color: isDark ? const Color(0xFF1FB7B5) : const Color(0xFF0D8A90),
                        ),
                      ),
                      backgroundColor: isDark ? const Color(0xFF162327) : const Color(0xFFE8F9F8),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF23343A) : const Color(0xFFD9ECE5),
                      ),
                      onPressed: () {
                        if (_suggestions[index].contains('#ID')) {
                          _inputController.text = _suggestions[index];
                        } else {
                          _sendMessage(_suggestions[index]);
                        }
                      },
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
                  color: isDark ? const Color(0xFF23343A) : const Color(0xFFD9ECE5),
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
                      hintText: _isListening ? 'Listening...' : 'Ask about matching jobs...',
                      hintStyle: TextStyle(
                        color: _isListening ? Colors.redAccent : const Color(0xFF94A3B8)
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      fillColor: isDark ? const Color(0xFF0A0D0F) : const Color(0xFFF8FCFA),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF23343A) : const Color(0xFFD9ECE5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF23343A) : const Color(0xFFD9ECE5),
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
                // Voice / Stop Audio Button
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.15);
                    final isStopping = _isListening || _isSpeaking;
                    return Transform.scale(
                      scale: isStopping ? scale : 1.0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isStopping
                              ? Colors.redAccent
                              : (isDark ? const Color(0xFF162327) : const Color(0xFFE8F9F8)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isStopping
                                ? Colors.redAccent
                                : const Color(0xFF1FB7B5).withOpacity(0.3),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isStopping ? Icons.stop_rounded : Icons.mic_rounded,
                            color: isStopping
                                ? Colors.white
                                : (isDark ? const Color(0xFF1FB7B5) : const Color(0xFF0D8A90)),
                            size: 20,
                          ),
                          onPressed: _listen,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Send Button
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

  Widget _buildQuickAction(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.getPrimary(isDark),
        onPressed: () {
          _sendMessage(title, forceMentor: true);
        },
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
