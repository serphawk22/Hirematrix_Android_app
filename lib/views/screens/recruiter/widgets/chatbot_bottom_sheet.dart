import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatbotBottomSheet extends StatefulWidget {
  const ChatbotBottomSheet({super.key});

  @override
  State<ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class _ChatbotBottomSheetState extends State<ChatbotBottomSheet>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// Chat messages list. Each item has role/text/time/actions.
  final List<Map<String, dynamic>> _messages = [];

  /// Suggestion chips loaded from the server – shown INLINE in chat
  /// after the welcome message, and hidden once the user sends a message.
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = true;

  /// Mirrors the JS chatContext: last_candidate, last_draft, last_job
  Map<String, dynamic> _chatContext = {
    'last_candidate': null,
    'last_draft': null,
    'last_job': null,
  };

  /// Pending draft: set when a "draft" action button is tapped.
  Map<String, String>? _pendingDraft;

  bool _isLoading = false;
  bool _isTyping = false;
  String? _recruiterId;

  // Voice
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _shouldSpeakNextReply = false;
  late AnimationController _pulseController;

  // ─────────────────────────────────────────────────────────────────────────
  //  Init
  // ─────────────────────────────────────────────────────────────────────────

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

    // Welcome message — always the first item
    _messages.add({
      'role': 'bot',
      'text':
          'Hi! I\'m HireMate, your AI recruitment assistant. Ask me anything about your jobs, applications, candidates, or interviews.',
      'time': 'Just now',
      'actions': <dynamic>[],
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      _recruiterId = auth.currentRecruiter?.id;
      if (_recruiterId != null) {
        _loadSuggestions(); // load chips first
        _loadBrief();       // brief appended after suggestions
      }
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() { _isSpeaking = true; _pulseController.repeat(reverse: true); });
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() { _isSpeaking = false; _pulseController.stop(); _pulseController.reset(); });
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() { _isSpeaking = false; _pulseController.stop(); _pulseController.reset(); });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  API Loaders
  // ─────────────────────────────────────────────────────────────────────────

  /// Load suggestion chips – displayed inline in chat after welcome message.
  Future<void> _loadSuggestions() async {
    try {
      final data = await _apiService.getChatbotSuggestions(_recruiterId!);
      if (!mounted) return;
      if (data['success'] == true && data['suggestions'] != null) {
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(
            (data['suggestions'] as List).map(
              (x) => x is Map<String, dynamic>
                  ? x
                  : {'text': x.toString(), 'mode': 'send'},
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Suggestions error: $e');
    }
  }

  /// Load morning brief – appended as a new bot message AFTER suggestions,
  /// just like the web version (appendMessage, not replace).
  Future<void> _loadBrief() async {
    try {
      final data = await _apiService.getChatbotBrief(_recruiterId!);
      if (!mounted) return;
      if (data['success'] == true && data['answer'] != null) {
        final actions = List<dynamic>.from(data['actions'] ?? []);
        _updateChatContext(actions);
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': data['answer'],
            'time': DateFormat('hh:mm a').format(DateTime.now()),
            'actions': actions,
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Brief error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Context Tracking  (mirrors JS updateChatContext)
  // ─────────────────────────────────────────────────────────────────────────

  void _updateChatContext(List<dynamic> actions) {
    for (final card in actions) {
      if (card is! Map<String, dynamic>) continue;

      final type      = card['type']?.toString() ?? '';
      final candidateId = card['candidate_id'];
      final jobId     = card['job_id'];
      final jobTitle  = card['job_title']?.toString() ?? '';

      if ((type == 'candidate' || type == 'message_draft') && candidateId != null) {
        _chatContext['last_candidate'] = {
          'candidate_id': candidateId,
          'application_id': card['application_id'],
          'job_id': jobId,
          'candidate_name':
              card['candidate_name']?.toString() ?? card['title']?.toString() ?? '',
          'job_title': jobTitle,
        };
      }

      if (jobId != null || jobTitle.isNotEmpty) {
        _chatContext['last_job'] = {
          'job_id': jobId,
          'job_title': jobTitle.isNotEmpty ? jobTitle : (card['meta']?.toString() ?? ''),
        };
      }

      if (type == 'message_draft' &&
          (card.containsKey('command') ||
              card.containsKey('subject') ||
              card.containsKey('message_body'))) {
        _chatContext['last_draft'] = {
          'candidate_id': candidateId,
          'application_id': card['application_id'],
          'job_id': jobId,
          'subject': card['subject']?.toString() ?? '',
          'message_body':
              card['message_body']?.toString() ?? card['detail']?.toString() ?? '',
          'command': card['command']?.toString() ?? '',
        };
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Messaging
  // ─────────────────────────────────────────────────────────────────────────

  bool _looksLikeInternalCommand(String v) =>
      RegExp(r'^(confirm\s+)?(send|message|shortlist|reject)\b',
              caseSensitive: false)
          .hasMatch(v);

  Future<void> _sendMessage(String text, {bool silent = false}) async {
    String toSend = text.trim();
    if (toSend.isEmpty || _isLoading || _recruiterId == null) return;

    // Pending-draft: prepend command prefix
    if (_pendingDraft != null) {
      if (!_looksLikeInternalCommand(toSend)) {
        toSend = (_pendingDraft!['commandPrefix'] ?? '') + toSend;
      }
      _pendingDraft = null;
    }

    if (_isSpeaking) {
      await _flutterTts.stop();
      if (mounted) setState(() { _isSpeaking = false; _pulseController.stop(); });
    }

    _inputController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _showSuggestions = false; // hide suggestion chips once conversation starts
      if (!silent) {
        _messages.add({
          'role': 'user',
          'text': toSend,
          'time': DateFormat('hh:mm a').format(DateTime.now()),
          'actions': <dynamic>[],
        });
      }
      _isLoading = true;
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final data = await _apiService.askChatbot(
        _recruiterId!,
        toSend,
        chatContext: _chatContext,
      );
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _isLoading = false;

        final ans = data['answer']?.toString() ??
            'Sorry, I couldn\'t process that. Please try asking differently.';
        final actions = List<dynamic>.from(data['actions'] ?? []);
        _updateChatContext(actions);

        _messages.add({
          'role': 'bot',
          'text': ans,
          'time': DateFormat('hh:mm a').format(DateTime.now()),
          'actions': actions,
        });

        if (_shouldSpeakNextReply) {
          _shouldSpeakNextReply = false;
          _speak(ans);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _isLoading = false;
        _messages.add({
          'role': 'bot',
          'text':
              'Connection error: $e. Make sure you are logged in as a recruiter.',
          'time': DateFormat('hh:mm a').format(DateTime.now()),
          'actions': <dynamic>[],
        });
      });
    }
    _scrollToBottom();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Voice
  // ─────────────────────────────────────────────────────────────────────────

  void _listen() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
        _shouldSpeakNextReply = false;
        _pulseController.stop();
        _pulseController.reset();
      });
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if ((val == 'done' || val == 'notListening') && mounted) {
            setState(() {
              _isListening = false;
              _pulseController.stop();
              _pulseController.reset();
            });
            if (_inputController.text.isNotEmpty) {
              _shouldSpeakNextReply = true;
              _sendMessage(_inputController.text);
            }
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _shouldSpeakNextReply = false;
              _pulseController.stop();
              _pulseController.reset();
            });
          }
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _inputController.text = '';
          _pulseController.repeat(reverse: true);
        });
        _speech.listen(
          onResult: (val) =>
              setState(() => _inputController.text = val.recognizedWords),
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
    final clean = text.replaceAll(RegExp(r'<[^>]*>|💡'), '').trim();
    if (clean.isEmpty) return;
    await _flutterTts.speak(clean);
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

  // ─────────────────────────────────────────────────────────────────────────
  //  Action Button Handler
  // ─────────────────────────────────────────────────────────────────────────

  void _handleActionButton(
    Map<String, dynamic> action,
    Map<String, dynamic> card,
    Map<String, bool> selectedIds,
    StateSetter setCardState,
  ) async {
    final kind    = action['kind']?.toString() ?? '';
    final command = action['command']?.toString();
    final url     = action['url']?.toString();

    // Pre-select checkboxes
    if (action['select_candidate_ids'] != null) {
      final ids = List<dynamic>.from(action['select_candidate_ids'] as List);
      setCardState(() {
        for (final id in ids) selectedIds[id.toString()] = true;
      });
      return;
    }

    // Link / URL
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // Requires selection
    if (action['requires_selection'] == true) {
      final checked =
          selectedIds.entries.where((e) => e.value).map((e) => e.key).toList();
      if (checked.isEmpty) {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'bot',
              'text': 'Select at least one candidate first.',
              'time': DateFormat('hh:mm a').format(DateTime.now()),
              'actions': <dynamic>[],
            });
          });
          _scrollToBottom();
        }
        return;
      }
      final prefix = action['command_prefix']?.toString() ?? '';
      final built  = prefix + checked.map((id) => 'candidate #$id').join(' ');
      _sendMessage(built, silent: action['silent'] == true);
      return;
    }

    // Copy
    if (kind == 'copy' || action['copy_text'] != null) {
      final copyText = action['copy_text']?.toString() ?? command ?? '';
      if (copyText.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: copyText));
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'bot',
              'text': 'Copied.',
              'time': DateFormat('hh:mm a').format(DateTime.now()),
              'actions': <dynamic>[],
            });
          });
          _scrollToBottom();
        }
      }
      return;
    }

    if (command == null || command.isEmpty) return;

    // Draft
    if (kind == 'draft') {
      String draftText = action['draft_text']?.toString() ?? '';
      if (draftText.isEmpty) {
        final colon = command.indexOf(':');
        draftText = colon >= 0 ? command.substring(colon + 1).trim() : command;
      }
      String commandPrefix = action['command_prefix']?.toString() ?? '';
      if (commandPrefix.isEmpty) {
        final colon = command.indexOf(':');
        commandPrefix = colon >= 0
            ? command.substring(0, colon + 1) + ' '
            : command + ' ';
      }
      setState(() {
        _pendingDraft = {
          'commandPrefix': commandPrefix,
          'originalCommand': command,
        };
      });
      _inputController.text = draftText;
      _inputController.selection =
          TextSelection.fromPosition(TextPosition(offset: _inputController.text.length));
      FocusScope.of(context).requestFocus(_focusNode);
      return;
    }

    // Default: send command
    _sendMessage(command, silent: action['silent'] == true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Dispose
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final primaryColor  = AppColors.getPrimary(isDark);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0D0F) : const Color(0xFFF5F7FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _buildHeader(),

          // ── Messages + inline suggestions ──────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              // extra slots: suggestions block + typing indicator
              itemCount: _messages.length +
                  (_showSuggestions && _suggestions.isNotEmpty ? 1 : 0) +
                  (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                final suggestionsSlot =
                    _showSuggestions && _suggestions.isNotEmpty ? 1 : 0;

                // First item: welcome message (index 0 in _messages)
                if (index < 1) {
                  return _buildMessageRow(_messages[0], isDark, primaryColor);
                }

                // After the welcome message, inject suggestions block
                if (suggestionsSlot == 1 && index == 1) {
                  return _buildInlineSuggestions(isDark);
                }

                // Remaining messages (brief + user/bot conversation)
                final msgIndex = index - suggestionsSlot;
                if (msgIndex < _messages.length) {
                  return _buildMessageRow(
                      _messages[msgIndex], isDark, primaryColor);
                }

                // Typing indicator at the end
                return _buildTypingIndicator(isDark);
              },
            ),
          ),

          // ── Input ───────────────────────────────────────────────────────
          _buildInput(isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
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
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'HireMate AI',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Message Row
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMessageRow(
      Map<String, dynamic> msg, bool isDark, Color primaryColor) {
    final isBot   = msg['role'] == 'bot';
    final actions = List<dynamic>.from(msg['actions'] ?? []);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Bubble
          Align(
            alignment:
                isBot ? Alignment.centerLeft : Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              child: _buildBubble(msg, isBot, isDark, primaryColor),
            ),
          ),

          // Action cards
          if (isBot && actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: actions.map((a) {
                  if (a is! Map<String, dynamic>) return const SizedBox.shrink();
                  return _ActionCard(
                    card: a,
                    isDark: isDark,
                    onButtonTap: _handleActionButton,
                    onSendMessage: _sendMessage,
                  );
                }).toList(),
              ),
            ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              msg['time'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isDark
                    ? const Color(0xFF7A8B96)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Message Bubble
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBubble(
      Map<String, dynamic> msg, bool isBot, bool isDark, Color primaryColor) {
    final text = msg['text']?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isBot
            ? (isDark ? const Color(0xFF1A2E35) : const Color(0xFFE9F6F5))
            : primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isBot ? 4 : 16),
          bottomRight: Radius.circular(isBot ? 16 : 4),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: isBot
              ? (isDark ? const Color(0xFFF0F4F8) : const Color(0xFF1A2E35))
              : Colors.white,
          fontSize: 13.5,
          height: 1.55,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Inline Suggestion Chips  (mirroring web: vertical list in chat)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInlineSuggestions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _suggestions.map((s) {
          final text = s['text']?.toString() ?? '';
          final mode = s['mode']?.toString() ?? 'send';
          final url  = s['url']?.toString() ?? '';
          if (text.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SuggestionChip(
              text: text,
              isDark: isDark,
              onTap: () async {
                if (mode == 'link' && url.isNotEmpty) {
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                  return;
                }
                if (mode == 'edit') {
                  setState(() { _showSuggestions = false; });
                  _inputController.text = text;
                  final idx = text.indexOf('#ID');
                  _inputController.selection = idx != -1
                      ? TextSelection(baseOffset: idx, extentOffset: idx + 3)
                      : TextSelection.fromPosition(
                          TextPosition(offset: text.length));
                  _focusNode.requestFocus();
                } else {
                  _sendMessage(text);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Input Area
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInput(bool isDark) {
    final isStopping = _isListening || _isSpeaking;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1214) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E2E35)
                : const Color(0xFFD4EDE9),
          ),
        ),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              style: TextStyle(
                color: isDark ? const Color(0xFFF0F4F8) : const Color(0xFF16212B),
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText: _isListening
                    ? 'Listening...'
                    : _pendingDraft != null
                        ? 'Edit the message, then press Send'
                        : 'Ask about your hiring data...',
                hintStyle: TextStyle(
                  color: _isListening
                      ? Colors.redAccent
                      : const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                fillColor: isDark
                    ? const Color(0xFF111A1E)
                    : const Color(0xFFF4FAF9),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide(
                    color: _pendingDraft != null
                        ? const Color(0xFF1FB7B5)
                        : (isDark
                            ? const Color(0xFF1E2E35)
                            : const Color(0xFFD4EDE9)),
                    width: _pendingDraft != null ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(
                      color: Color(0xFF1FB7B5), width: 1.5),
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),

          // Mic / Stop button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final scale = 1.0 + (_pulseController.value * 0.15);
              return Transform.scale(
                scale: isStopping ? scale : 1.0,
                child: _CircleButton(
                  size: 42,
                  backgroundColor: isStopping
                      ? Colors.redAccent
                      : (isDark
                          ? const Color(0xFF162327)
                          : const Color(0xFFE3F5F3)),
                  borderColor: isStopping
                      ? Colors.redAccent
                      : const Color(0xFF1FB7B5).withOpacity(0.35),
                  icon: isStopping
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  iconColor: isStopping
                      ? Colors.white
                      : const Color(0xFF1FB7B5),
                  onTap: _listen,
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Send button
          _CircleButton(
            size: 42,
            gradient: const LinearGradient(
              colors: [Color(0xFF1FB7B5), Color(0xFF53B86C)],
            ),
            icon: Icons.send_rounded,
            iconColor: Colors.white,
            iconSize: 17,
            onTap: () => _sendMessage(_inputController.text),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Typing Indicator
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A2E35)
                : const Color(0xFFE9F6F5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypingDot(),
              SizedBox(width: 4),
              _TypingDot(delay: 200),
              SizedBox(width: 4),
              _TypingDot(delay: 400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Suggestion Chip Widget  (full-width row like the web version)
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionChip extends StatefulWidget {
  final String text;
  final bool isDark;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.text,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _pressed
              ? (isDark
                  ? const Color(0xFF1A3540)
                  : const Color(0xFFD0EFED))
              : (isDark
                  ? const Color(0xFF132028)
                  : const Color(0xFFE9F7F6)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E3A44)
                : const Color(0xFFBCE4E1),
            width: 1,
          ),
        ),
        child: Text(
          widget.text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark
                ? const Color(0xFF2DD4D0)
                : const Color(0xFF0A8C88),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stateful Action Card  (manages its own checkbox selections)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatefulWidget {
  final Map<String, dynamic> card;
  final bool isDark;
  final void Function(
    Map<String, dynamic> action,
    Map<String, dynamic> card,
    Map<String, bool> selectedIds,
    StateSetter setCardState,
  ) onButtonTap;
  final Future<void> Function(String text, {bool silent}) onSendMessage;

  const _ActionCard({
    required this.card,
    required this.isDark,
    required this.onButtonTap,
    required this.onSendMessage,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  final Map<String, bool> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final card  = widget.card;
    final isDark = widget.isDark;

    final title      = card['title']?.toString() ?? '';
    final meta       = card['meta']?.toString() ?? '';
    final detail     = card['detail']?.toString() ?? '';
    final itemsTitle = card['items_title']?.toString() ?? '';
    final items      = List<dynamic>.from(card['items'] ?? []);
    final buttons    = List<dynamic>.from(card['buttons'] ?? []);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1214) : Colors.white,
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3040)
              : const Color(0xFFD4EDE9),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF1FB7B5).withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFF0F4F8)
                      : const Color(0xFF16212B),
                )),
          if (meta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(meta,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  )),
            ),
          if (detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(detail,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.55,
                    color: isDark
                        ? const Color(0xFFB0C4CE)
                        : const Color(0xFF475569),
                  )),
            ),
          if (itemsTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(itemsTitle,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFFF0F4F8)
                        : const Color(0xFF16212B),
                  )),
            ),
          if (items.isNotEmpty)
            ...items.map((c) {
              if (c is! Map<String, dynamic>) return const SizedBox.shrink();
              final cid   = c['candidate_id']?.toString() ?? '';
              if (cid.isEmpty) return const SizedBox.shrink();
              final label = c['label']?.toString() ?? 'Candidate';
              final cMeta = c['meta']?.toString() ?? '';
              final checked = _selectedIds[cid] ?? false;
              return InkWell(
                onTap: () => setState(() => _selectedIds[cid] = !checked),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: checked,
                          onChanged: (v) =>
                              setState(() => _selectedIds[cid] = v ?? false),
                          activeColor: const Color(0xFF1FB7B5),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFF0F4F8)
                                      : const Color(0xFF16212B),
                                )),
                            if (cMeta.isNotEmpty)
                              Text(cMeta,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (buttons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: buttons.map((btn) {
                  if (btn is! Map<String, dynamic>) {
                    return const SizedBox.shrink();
                  }
                  final label = btn['label']?.toString() ?? '';
                  final kind  = btn['kind']?.toString() ?? 'secondary';

                  Color bg     = isDark ? const Color(0xFF132028) : const Color(0xFFF4FAF9);
                  Color fg     = isDark ? const Color(0xFF2DD4D0) : const Color(0xFF0A8C88);
                  Color border = isDark ? const Color(0xFF1E3040) : const Color(0xFFD4EDE9);

                  if (kind == 'primary') {
                    bg = const Color(0xFF1FB7B5);
                    fg = Colors.white;
                    border = Colors.transparent;
                  } else if (kind == 'danger') {
                    fg = const Color(0xFFEF4444);
                  }

                  return InkWell(
                    onTap: () => widget.onButtonTap(
                        Map<String, dynamic>.from(btn),
                        widget.card,
                        _selectedIds,
                        setState),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: border),
                      ),
                      child: Text(label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Circle Button Helper
// ─────────────────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final VoidCallback onTap;

  const _CircleButton({
    required this.size,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    required this.icon,
    required this.iconColor,
    this.iconSize = 20,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1)
              : null,
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Typing Dot
// ─────────────────────────────────────────────────────────────────────────────

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({this.delay = 0});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _c,
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
