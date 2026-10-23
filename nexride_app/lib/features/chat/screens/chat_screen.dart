import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

// ── Message model ─────────────────────────────────────────────────────────────

class _Msg {
  final String text;
  final bool isUser;
  _Msg({required this.text, required this.isUser});
}

// ── Chat Screen ───────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();
  final List<_Msg>  _msgs = [];
  bool _isBotTyping  = false;
  bool _isSending    = false;   // prevents duplicate sends

  // ── Suggestion chips ──────────────────────────────────────────────────────
  static const _chips = [
    'Route from Majestic to Electronic City?',
    'Where is bus 401A?',
    'ETA for route 500D?',
    'Book ticket from MG Road to Whitefield',
  ];

  // ── initState: welcome message only, NO API call ──────────────────────────
  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(
      text: "👋 Hi! I'm **NexRide Assistant**.\n\n"
            "Ask me anything about Bengaluru buses — "
            "routes, tracking, ETA, or ticket booking!",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Send message ──────────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _msgs.add(_Msg(text: text, isUser: true));
      _isBotTyping = true;
      _inputCtrl.clear();
    });

    // Dismiss keyboard
    _focusNode.unfocus();
    _scrollToBottom();

    try {
      final res = await ApiClient.instance.dio
          .post('/chat/', data: {'message': text});
      final reply = (res.data['reply'] as String?)?.trim() ??
          'Sorry, something went wrong.';

      if (!mounted) return;
      setState(() {
        _isBotTyping = false;
        _msgs.add(_Msg(text: reply, isUser: false));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBotTyping = false;
        _msgs.add(_Msg(
          text: '⚠️ Connection error. Make sure the backend is running '
                'and run:\nadb reverse tcp:8000 tcp:8000',
          isUser: false,
        ));
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppTheme.bgDark        : const Color(0xFFF5F5F5);
    final navBg  = isDark ? AppTheme.bgSurface      : Colors.white;
    final divider = isDark ? AppTheme.glassBorder   : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: navBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: const SizedBox(),   // no back button in tab
        title: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                  Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NexRide AI',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87)),
                Row(children: [
                  Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Online',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.textSecondary
                              : Colors.black45)),
                ]),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: divider),
        ),
      ),

      body: Column(
        children: [
          // ── Message list ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              itemCount: _msgs.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_isBotTyping && i == _msgs.length) {
                  return _TypingIndicator(isDark: isDark);
                }
                return _BotBubble(
                  key: ValueKey(i),
                  msg: _msgs[i],
                  isDark: isDark,
                );
              },
            ),
          ),

          // ── Suggestion chips (only when just the welcome msg) ───────────
          if (_msgs.length == 1)
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                itemCount: _chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    _inputCtrl.text = _chips[i];
                    _send();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.25)),
                    ),
                    child: Text(_chips[i],
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ),

          if (_msgs.length == 1) const SizedBox(height: 8),

          // ── Input bar ────────────────────────────────────────────────────
          _InputBar(
            ctrl: _inputCtrl,
            focusNode: _focusNode,
            isDark: isDark,
            isSending: _isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── _InputBar — separated widget so it NEVER causes full list rebuild ─────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final bool isDark;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.ctrl,
    required this.focusNode,
    required this.isDark,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final barBg    = isDark ? AppTheme.bgSurface : Colors.white;
    final fieldBg  = isDark ? AppTheme.bgCard    : const Color(0xFFF0F0F5);
    final hintClr  = isDark ? AppTheme.textHint  : Colors.black38;
    final textClr  = isDark ? Colors.white       : Colors.black87;
    final divider  = isDark ? AppTheme.glassBorder : const Color(0xFFE0E0E0);

    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 10, 14, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: divider, width: 0.8)),
        boxShadow: isDark
            ? null
            : [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field — FocusNode attached directly, no GestureDetector wrapping
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: isDark
                    ? null
                    : [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4)],
              ),
              child: TextField(
                controller: ctrl,
                focusNode: focusNode,
                style: TextStyle(fontSize: 14, color: textClr, height: 1.4),
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Ask about routes, buses, ETA…',
                  hintStyle:
                      TextStyle(color: hintClr, fontSize: 13.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send button
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isSending
                    ? [Colors.grey.shade400, Colors.grey.shade400]
                    : [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSending
                    ? null
                    : [BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3))],
              ),
              child: isSending
                  ? const Center(
                      child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble ───────────────────────────────────────────────────────────────

class _BotBubble extends StatelessWidget {
  final _Msg msg;
  final bool isDark;

  const _BotBubble({super.key, required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;

    // Colors
    final userBubble  = AppTheme.primary;
    final botBubbleBg = isDark ? AppTheme.bgCard : Colors.white;
    final botBorder   = isDark ? AppTheme.glassBorder : const Color(0xFFE8E8F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? userBubble : botBubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: botBorder, width: 0.8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: _RichText(
                  text: msg.text,
                  isUser: isUser,
                  isDark: isDark),
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppTheme.primary, size: 17),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Inline bold markdown renderer ─────────────────────────────────────────────

class _RichText extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isDark;

  const _RichText(
      {required this.text, required this.isUser, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isUser
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final dimColor = isUser
        ? Colors.white.withOpacity(0.88)
        : (isDark ? Colors.white70 : Colors.black54);

    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*([^*]+)\*\*');
    int last = 0;

    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(
            text: text.substring(last, m.start),
            style: TextStyle(
                color: dimColor, fontSize: 13.5, height: 1.5)));
      }
      spans.add(TextSpan(
          text: m.group(1),
          style: TextStyle(
              color: baseColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.5)));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
          text: text.substring(last),
          style: TextStyle(
              color: dimColor, fontSize: 13.5, height: 1.5)));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ── Typing indicator (3 animated dots) ───────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppTheme.bgCard : Colors.white;
    final border =
        widget.isDark ? AppTheme.glassBorder : const Color(0xFFE8E8F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark]),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: border, width: 0.8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    // Each dot animates with a phase offset
                    final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
                    final opacity = (phase < 0.5)
                        ? phase * 2
                        : (1.0 - phase) * 2;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary
                            .withOpacity(0.3 + opacity * 0.7),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
