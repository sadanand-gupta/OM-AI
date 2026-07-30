import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:om_ai/constants/app_colors.dart';
import 'package:om_ai/screens/history_screen.dart';
import 'package:om_ai/service/claude_service.dart';
import 'package:om_ai/widgets/custom_app_bar.dart';
import 'package:om_ai/widgets/discover_screen.dart';
import 'package:om_ai/widgets/image_donwload_helper.dart';

class HomeScreen extends StatefulWidget {
  final String? conversationId;

  const HomeScreen({super.key, this.conversationId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 1);
  final GlobalKey<HistoryScreenState> _historyKey =
      GlobalKey<HistoryScreenState>();
  bool _isChatLoading = false;
  final ClaudeService _claudeService = ClaudeService();
  final List<ChatBubble> _messages = [];
  bool _isSendingMessage = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _rotationController;
  bool _isTyping = false;
  bool _isFromHistory = false;
  bool _isAppBarVisible = true;
  double _lastScrollOffset = 0;
  bool _userIsScrolling = false;
  Timer? _scrollEndTimer;
  DateTime? _lastBackPressTime;

  // Text input
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _scrollController.addListener(_onScroll);
    _inputFocusNode.addListener(() {
      setState(() => _isTyping = _inputFocusNode.hasFocus);
    });

    _claudeService.startNewSession();

    if (widget.conversationId != null) {
      _isFromHistory = true;
      _loadChatFromHistory(widget.conversationId!);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final scrollDelta = currentOffset - _lastScrollOffset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (scrollDelta < -5) {
      _userIsScrolling = true;
      _scrollEndTimer?.cancel();
      _scrollEndTimer = Timer(const Duration(seconds: 2), () {
        if (_scrollController.hasClients) {
          final pos = _scrollController.offset;
          final maxPos = _scrollController.position.maxScrollExtent;
          if (maxPos - pos < 100) _userIsScrolling = false;
        }
      });
    }

    if (currentOffset >= maxScroll - 50) _userIsScrolling = false;

    if (_messages.isNotEmpty) {
      if (scrollDelta > 5 && _isAppBarVisible) {
        setState(() => _isAppBarVisible = false);
      } else if (scrollDelta < -5 && !_isAppBarVisible) {
        setState(() => _isAppBarVisible = true);
      }
    }

    _lastScrollOffset = currentOffset;
  }

  Future<void> _loadChatFromHistory(String sessionId) async {
    setState(() => _isChatLoading = true);
    _messages.clear();

    final messages = await _claudeService.loadSession(sessionId);
    for (final m in messages) {
      _messages.add(ChatBubble(
        message: m.content,
        isUser: m.role == 'user',
        timestamp: m.timestamp,
      ));
    }

    setState(() => _isChatLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_userIsScrolling) return;
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && !_userIsScrolling) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSendingMessage) return;

    _userIsScrolling = false;
    _inputController.clear();
    _inputFocusNode.unfocus();

    setState(() {
      _messages.add(ChatBubble(
        message: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isSendingMessage = true;
      _isFromHistory = false;
    });

    _scrollToBottom();

    final response = await _claudeService.sendMessage(text);

    setState(() {
      _messages.add(ChatBubble(
        message: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        isError: response.isError,
      ));
      _isSendingMessage = false;
    });

    _scrollToBottom();

    // Refresh history tab
    _historyKey.currentState?.refreshHistory();
  }

  void resetChat() {
    setState(() {
      _messages.clear();
      _isAppBarVisible = true;
      _isFromHistory = false;
    });
    _claudeService.startNewSession();
  }

  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Swipe again to exit"),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _pageController.dispose();
    _scrollController.dispose();
    _rotationController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  bool get _showAppBar => !_isTyping && !_isChatLoading && _isAppBarVisible;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.softCreamWhite,
        body: PageView(
          controller: _pageController,
          onPageChanged: (_) => setState(() {}),
          children: [
            HistoryScreen(key: _historyKey),
            _buildMainHome(),
            const DiscoverScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainHome() {
    return SafeArea(
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showAppBar ? const CustomAppBar() : const SizedBox(),
          ),
          Expanded(
            child: _isChatLoading
                ? _buildChatSkeleton()
                : _messages.isEmpty
                    ? _buildInitialView()
                    : _buildChatView(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Message OM AI...",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSendingMessage
                    ? Colors.grey.shade400
                    : Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: _isSendingMessage
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: 6,
        itemBuilder: (context, index) {
          bool isUser = index.isEven;
          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: isUser ? 80 : 140, color: Colors.white),
                  const SizedBox(height: 8),
                  if (!isUser)
                    Container(height: 12, width: 200, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          _buildCenterLogo(),
          const SizedBox(height: 24),
          Text(
            "How can I help you today?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isSendingMessage ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isSendingMessage && index == _messages.length) {
          return _buildLoadingIndicator();
        }

        final bubble = _messages[index];
        final isMostRecentBotMessage =
            !bubble.isUser &&
            index == _messages.length - 1 &&
            !_isFromHistory;

        return AnimatedChatBubble(
          key: ValueKey(
              '${bubble.timestamp.toIso8601String()}-${bubble.message.length}'),
          bubble: bubble,
          isMostRecentBotMessage: isMostRecentBotMessage,
          onAnimationComplete: _scrollToBottom,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
        child: LoadingAnimationWidget.waveDots(
          color: Colors.grey.shade600,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildCenterLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _rotationController,
          child: ClipOval(
            child: Image.asset(
              'assets/images/Drona_Bot_Logo.png',
              height: 28,
              width: 28,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: 'OM ',
                style: TextStyle(color: AppColors.kDark),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Color.fromRGBO(63, 81, 181, 0.95),
                      Colors.white,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── ChatBubble model ─────────────────────────────────────────────────────────

class ChatBubble {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatBubble({
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

// ── Text / table rendering helpers ────────────────────────────────────────────

Widget buildCustomTable(BuildContext context, String raw) {
  final tableData = parseTableFromText(raw);
  if (tableData == null) return _buildRawTable(raw);

  return Stack(
    alignment: Alignment.topRight,
    children: [
      _buildRawTable(raw),
      GestureDetector(
        onTap: () => exportTableAsCSV(context, tableData),
        child: Container(
          margin: const EdgeInsets.all(4.0),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(Icons.download_rounded, size: 18, color: Colors.black54),
        ),
      ),
    ],
  );
}

Widget _buildRawTable(String raw) {
  final lines = raw.trim().split("\n");
  final rawRows = lines
      .where((l) => l.contains("|"))
      .where((l) => !isSeparatorRow(l))
      .map((l) {
        final cells = l.split("|");
        if (cells.isNotEmpty) cells.removeAt(0);
        if (cells.isNotEmpty) cells.removeLast();
        return cells.map((c) => c.trim()).toList();
      })
      .toList();

  if (rawRows.isEmpty) return const SizedBox();
  final int columnCount = rawRows.first.length;

  TableRow buildSafeRow(List<String> row) {
    return TableRow(
      children: List.generate(
        columnCount,
        (index) => Container(
          padding: const EdgeInsets.all(8),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: index < row.length && row[index].isNotEmpty
                    ? AppColors.kDark
                    : Colors.grey,
              ),
              children: renderBold(
                    index < row.length && row[index].isNotEmpty
                        ? row[index]
                        : '-',
                  ).children ??
                  [renderBold('-')],
            ),
          ),
        ),
      ),
    );
  }

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Table(
      border: TableBorder.all(color: Colors.grey.shade400),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: rawRows.map(buildSafeRow).toList(),
    ),
  );
}

Widget buildSmartMessage(BuildContext context, String text) {
  final lines = text.split("\n");
  List<String> tableLines = [];
  List<Widget> widgets = [];
  bool insideTable = false;

  for (String line in lines) {
    final trimmed = line.trim();
    if (!insideTable && trimmed.contains("|")) {
      insideTable = true;
      tableLines.add(line);
      continue;
    }
    if (insideTable && trimmed.contains("|")) {
      tableLines.add(line);
      continue;
    }
    if (insideTable && !trimmed.contains("|")) {
      widgets.add(buildCustomTable(context, tableLines.join("\n")));
      tableLines.clear();
      insideTable = false;
    }
    if (trimmed.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 15, height: 1.4, color: AppColors.kDark),
            children: renderBold(trimmed).children ?? [renderBold(trimmed)],
          ),
        ),
      ));
    }
  }

  if (tableLines.isNotEmpty) {
    widgets.add(buildCustomTable(context, tableLines.join("\n")));
  }

  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
}

bool isSeparatorRow(String line) =>
    line.trim().startsWith("|") && line.contains("---");

TextSpan renderBold(String text) {
  List<TextSpan> parseInline(String line) {
    final pattern = RegExp(r'\*\*(.*?)\*\*|"(.*?)"', dotAll: true);
    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in pattern.allMatches(line)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: line.substring(lastIndex, match.start)));
      }
      final boldContent = match.group(1) ?? match.group(2) ?? '';
      spans.add(TextSpan(
          text: boldContent,
          style: const TextStyle(fontWeight: FontWeight.bold)));
      lastIndex = match.end;
    }
    if (lastIndex < line.length) {
      spans.add(TextSpan(text: line.substring(lastIndex)));
    }
    return spans;
  }

  if (text.isEmpty) return const TextSpan(text: '');

  final lines = text.split('\n');
  final resultSpans = <TextSpan>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final headingMatch = RegExp(r'^\s*###\s*(.*)$').firstMatch(line);
    if (headingMatch != null) {
      resultSpans.add(TextSpan(
          text: headingMatch.group(1) ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold)));
    } else {
      resultSpans.addAll(parseInline(line));
    }
    if (i != lines.length - 1) {
      resultSpans.add(const TextSpan(text: '\n'));
    }
  }

  return TextSpan(children: resultSpans);
}

// ── AnimatedChatBubble ───────────────────────────────────────────────────────

class MessageChunk {
  final String content;
  final bool isTable;
  MessageChunk(this.content, {this.isTable = false});
}

class AnimatedChatBubble extends StatefulWidget {
  final ChatBubble bubble;
  final bool isMostRecentBotMessage;
  final VoidCallback onAnimationComplete;

  const AnimatedChatBubble({
    Key? key,
    required this.bubble,
    required this.isMostRecentBotMessage,
    required this.onAnimationComplete,
  }) : super(key: key);

  @override
  _AnimatedChatBubbleState createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<AnimatedChatBubble> {
  final List<MessageChunk> _chunks = [];
  int _currentChunkIndex = 0;
  Timer? _timer;
  String _currentlyAnimatingText = '';
  bool _isAnimatingText = false;
  final List<MessageChunk> _completedChunks = [];

  @override
  void initState() {
    super.initState();
    if (widget.isMostRecentBotMessage && !widget.bubble.isUser) {
      _parseMessageIntoChunks();
      _startChunkAnimation();
    }
  }

  void _parseMessageIntoChunks() {
    final message = widget.bubble.message;
    final lines = message.split('\n');
    List<String> currentChunkLines = [];
    bool isCurrentlyInTable = false;

    for (final line in lines) {
      final trimmedLine = line.trim();
      bool isTableLine =
          trimmedLine.startsWith('|') && trimmedLine.endsWith('|');

      if (isTableLine && !isCurrentlyInTable) {
        if (currentChunkLines.isNotEmpty) {
          _chunks.add(MessageChunk(currentChunkLines.join('\n')));
          currentChunkLines = [];
        }
        isCurrentlyInTable = true;
      } else if (!isTableLine && isCurrentlyInTable && trimmedLine.isNotEmpty) {
        if (currentChunkLines.isNotEmpty) {
          _chunks.add(
              MessageChunk(currentChunkLines.join('\n'), isTable: true));
          currentChunkLines = [];
        }
        isCurrentlyInTable = false;
      }
      currentChunkLines.add(line);
    }

    if (currentChunkLines.isNotEmpty) {
      _chunks.add(MessageChunk(currentChunkLines.join('\n'),
          isTable: isCurrentlyInTable));
    }
  }

  void _startChunkAnimation() {
    if (_currentChunkIndex >= _chunks.length) {
      if (mounted) setState(() {});
      return;
    }

    final chunk = _chunks[_currentChunkIndex];
    _currentChunkIndex++;

    if (chunk.isTable) {
      if (mounted) {
        setState(() => _completedChunks.add(chunk));
        Future.delayed(
            const Duration(milliseconds: 50), _startChunkAnimation);
      }
    } else {
      _animateTextChunk(chunk.content);
    }
  }

  void _animateTextChunk(String textToAnimate) {
    if (_isAnimatingText) return;
    _isAnimatingText = true;

    final words = _splitIntoWords(textToAnimate);
    int currentWordIndex = 0;
    _currentlyAnimatingText = '';

    void animateNextWord() {
      if (currentWordIndex >= words.length) {
        if (mounted) {
          setState(() {
            _completedChunks.add(MessageChunk(_currentlyAnimatingText));
            _currentlyAnimatingText = '';
            _isAnimatingText = false;
          });
        }
        _startChunkAnimation();
        return;
      }

      if (mounted) {
        setState(() {
          _currentlyAnimatingText += words[currentWordIndex];
          currentWordIndex++;
        });
        widget.onAnimationComplete();
      }

      int delay = 60;
      final previousWord = words[currentWordIndex - 1].trim();
      if (currentWordIndex < words.length) {
        final nextWord = words[currentWordIndex];
        if (nextWord.contains('\n')) delay += 250;
      }
      delay += previousWord.length * 5;
      if (previousWord.endsWith('.') || previousWord.endsWith('?')) {
        delay += 200;
      } else if (previousWord.endsWith(',')) {
        delay += 100;
      }
      delay = min(delay, 600);

      _timer = Timer(Duration(milliseconds: delay), animateNextWord);
    }

    animateNextWord();
  }

  List<String> _splitIntoWords(String text) {
    final List<String> result = [];
    final RegExp wordPattern = RegExp(r'(\S+|\s+)');
    for (final match in wordPattern.allMatches(text)) {
      result.add(match.group(0)!);
    }
    return result;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubble = widget.bubble;

    if (!widget.isMostRecentBotMessage || bubble.isUser) {
      return _buildStaticBubble(context, bubble);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.90),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final chunk in _completedChunks)
                chunk.isTable
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: buildSmartMessage(context, chunk.content),
                      )
                    : RichText(
                        text: TextSpan(
                          children: renderBold(chunk.content).children ??
                              [renderBold(chunk.content)],
                          style:
                              TextStyle(color: AppColors.kDark, fontSize: 16, height: 1.4),
                        ),
                      ),
              if (_isAnimatingText && _currentlyAnimatingText.isNotEmpty)
                RichText(
                  text: TextSpan(
                    children: renderBold(_currentlyAnimatingText).children ??
                        [renderBold(_currentlyAnimatingText)],
                    style: TextStyle(
                        color: AppColors.kDark, fontSize: 16, height: 1.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticBubble(BuildContext context, ChatBubble bubble) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment:
            bubble.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width *
                (bubble.isUser ? 0.75 : 0.90),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: bubble.isUser
                ? (bubble.isError
                    ? Colors.red.shade100
                    : const Color.fromARGB(255, 223, 222, 222))
                : const Color.fromARGB(0, 228, 227, 227),
            borderRadius: BorderRadius.circular(16),
          ),
          child: buildSmartMessage(context, bubble.message),
        ),
      ),
    );
  }
}

// ── Table / CSV helpers ──────────────────────────────────────────────────────

class TableData {
  final List<String> headers;
  final List<List<String>> rows;
  TableData({required this.headers, required this.rows});
}

TableData? parseTableFromText(String rawTableText) {
  final lines = rawTableText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.startsWith('|') && l.endsWith('|'))
      .where((l) => !l.contains('---'))
      .toList();

  if (lines.isEmpty) return null;

  List<String> parseRow(String line) {
    final cells = line.substring(1, line.length - 1).split('|');
    return cells.map((cell) => cell.trim()).toList();
  }

  return TableData(
    headers: parseRow(lines.first),
    rows: lines.skip(1).map(parseRow).toList(),
  );
}

Future<void> exportTableAsCSV(BuildContext context, TableData table) async {
  try {
    final buffer = StringBuffer();

    String escapeCell(String cell) {
      if (cell.contains(',') || cell.contains('"') || cell.contains('\n')) {
        return '"${cell.replaceAll('"', '""')}"';
      }
      return cell;
    }

    buffer.writeln(table.headers.map(escapeCell).join(','));
    for (final row in table.rows) {
      buffer.writeln(row.map(escapeCell).join(','));
    }

    final bytes = utf8.encode(buffer.toString());
    final fileName = 'table_data_${DateTime.now().millisecondsSinceEpoch}';

    final path = await ImageDownloadHelper.downloadCSV(
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
    );

    debugPrint('✅ CSV saved at: $path');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Table downloaded as $fileName.csv')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download table: $e')),
      );
    }
  }
}
