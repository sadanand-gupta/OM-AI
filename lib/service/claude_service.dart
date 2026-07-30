import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:om_ai/config/secrets.dart';
import 'package:om_ai/service/social_media_service.dart';

const String _kClaudeApiKey = claudeApiKey;
// OpenRouter model — free options: 'meta-llama/llama-3.1-8b-instruct:free'
// Paid Claude via OpenRouter: 'anthropic/claude-haiku-4-5'
const String _kClaudeModel = 'anthropic/claude-haiku-4-5';
const String _kAnthropicApiUrl = 'https://openrouter.ai/api/v1/chat/completions';

const String _kSystemPrompt = '''
You are OM AI, a highly capable, friendly, and detailed AI assistant — similar to ChatGPT.

Guidelines:
- Always give thorough, complete, and well-structured answers.
- Use markdown formatting: headings (###), bullet points, numbered lists, bold (**text**), and code blocks where appropriate.
- Break long answers into clear sections with headings.
- When explaining concepts, give examples.
- When asked about a person, topic, product, or place — provide full details: background, key facts, features, pros/cons, and any relevant context.
- Never cut answers short. If the topic is complex, cover it fully.
- Be conversational and helpful in tone.
- If you don't know something, say so clearly — never make up facts.
- When web content is provided in the message, analyze it thoroughly and summarize all key details.

Social Media Analysis (when profile data is provided in the message):
- Analyze the profile deeply: follower count, engagement potential, niche, content strategy.
- Give actionable insights: what is working, what can be improved, growth tips.
- Compare stats to typical benchmarks (e.g. follower/following ratio, posting frequency).
- For Instagram: comment on bio quality, niche clarity, branding.
- For LinkedIn: assess professional positioning, headline strength, skills relevance.
- For Twitter/X: assess tweet frequency, follower quality, engagement style.
- For YouTube: assess subscriber count, view-to-subscriber ratio, content consistency.
- Always end with 3-5 concrete recommendations to grow or improve the profile.
''';


// Regex to find URLs in a message
final RegExp _urlRegex = RegExp(
  r'https?://[^\s]+',
  caseSensitive: false,
);

/// Fetches a URL and returns plain text content (strips HTML tags).
Future<String?> _fetchWebPage(String url) async {
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (compatible; OM-AI-Bot/1.0)',
        'Accept': 'text/html,application/xhtml+xml,text/plain',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;

    String body = response.body;

    // Remove script and style blocks
    body = body.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    body = body.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');

    // Strip all remaining HTML tags
    body = body.replaceAll(RegExp(r'<[^>]+>'), ' ');

    // Decode common HTML entities
    body = body
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    // Collapse extra whitespace/newlines
    body = body.replaceAll(RegExp(r'\s{2,}'), '\n').trim();

    // Limit to ~6000 chars to stay within token budget
    if (body.length > 6000) body = '${body.substring(0, 6000)}\n[content truncated]';

    return body;
  } catch (e) {
    debugPrint('Web fetch error for $url: $e');
    return null;
  }
}

class ClaudeMessage {
  final String role; // "user" or "assistant"
  final String content;
  final DateTime timestamp;

  ClaudeMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ClaudeMessage.fromJson(Map<String, dynamic> json) => ClaudeMessage(
    role: json['role'] ?? 'user',
    content: json['content'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}

class ClaudeSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ClaudeMessage> messages;

  ClaudeSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ClaudeSession.fromJson(Map<String, dynamic> json) => ClaudeSession(
    id: json['id'] ?? '',
    title: json['title'] ?? 'Untitled Chat',
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    messages: (json['messages'] as List? ?? [])
        .map((m) => ClaudeMessage.fromJson(m))
        .toList(),
  );
}

class ClaudeResponse {
  final String text;
  final bool isError;
  final bool isCancelled;

  ClaudeResponse({required this.text, this.isError = false, this.isCancelled = false});
}

class ClaudeService {
  String? currentSessionId;
  final List<ClaudeMessage> _sessionMessages = [];
  http.Client? _activeClient; // closed on cancel to abort the request immediately

  static const String _sessionsKey = 'om_ai_sessions';

  // ── Cancel the in-flight request — closes the HTTP client immediately ─────
  void cancelMessage() {
    _activeClient?.close();
    _activeClient = null;
  }

  // ── Send a message to Claude and get a response ──────────────────────────
  Future<ClaudeResponse> sendMessage(String userMessage) async {
    // Close any previous in-flight client
    _activeClient?.close();
    _activeClient = null;

    final buffer = StringBuffer(userMessage);
    bool hasExtra = false;

    // 1. Detect social media handles/URLs and fetch profile data
    final social = SocialMediaDetector.detect(userMessage);
    if (social != null) {
      final profileData = await SocialMediaService.fetchProfile(
          social.platform, social.handle);
      if (profileData != null) {
        if (!hasExtra) { buffer.writeln('\n\n--- Social Media Data Fetched ---'); hasExtra = true; }
        buffer.writeln(profileData);
      }
    }

    // 2. Detect plain URLs and fetch web content
    final urls = _urlRegex.allMatches(userMessage).map((m) => m.group(0)!).toList();
    if (urls.isNotEmpty) {
      if (!hasExtra) { buffer.writeln('\n\n--- Web Content Fetched ---'); hasExtra = true; }
      for (final url in urls) {
        // Skip social media URLs already handled above
        if (social != null &&
            (url.contains('instagram.com') ||
             url.contains('linkedin.com') ||
             url.contains('twitter.com') ||
             url.contains('x.com') ||
             url.contains('youtube.com'))) continue;
        final content = await _fetchWebPage(url);
        if (content != null && content.isNotEmpty) {
          buffer.writeln('\n[Content from $url]\n$content');
        } else {
          buffer.writeln('\n[Could not fetch content from $url]');
        }
      }
    }

    final String enrichedMessage = hasExtra ? buffer.toString() : userMessage;

    _sessionMessages.add(
      ClaudeMessage(
        role: 'user',
        content: userMessage, // store original message in history
        timestamp: DateTime.now(),
      ),
    );

    // Build messages payload — use enriched message only for the last (current) turn
    final apiMessages = _sessionMessages
        .take(_sessionMessages.length - 1)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList()
      ..add({'role': 'user', 'content': enrichedMessage});

    // Create a fresh client for this request — closing it aborts the request
    final client = http.Client();
    _activeClient = client;

    try {
      // OpenRouter uses OpenAI-compatible format with system message inside messages[]
      final messagesWithSystem = [
        {'role': 'system', 'content': _kSystemPrompt},
        ...apiMessages,
      ];

      final response = await client.post(
        Uri.parse(_kAnthropicApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_kClaudeApiKey',
          'HTTP-Referer': 'https://om-ai.app',
          'X-Title': 'OM AI',
        },
        body: jsonEncode({
          'model': _kClaudeModel,
          'max_tokens': 4096,
          'messages': messagesWithSystem,
        }),
      );

      client.close();
      _activeClient = null;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // OpenRouter returns OpenAI format: choices[0].message.content
        final assistantText =
            data['choices']?[0]?['message']?['content'] ?? 'No response received.';

        _sessionMessages.add(
          ClaudeMessage(
            role: 'assistant',
            content: assistantText,
            timestamp: DateTime.now(),
          ),
        );

        // Auto-save session after each exchange
        await _saveCurrentSession(userMessage);

        return ClaudeResponse(text: assistantText);
      } else {
        debugPrint('❌ API Error ${response.statusCode}: ${response.body}');
        Map<String, dynamic> error = {};
        try {
          error = jsonDecode(response.body);
        } catch (_) {}
        final errMsg = error['error']?['message'] ??
            'Request failed (${response.statusCode}): ${response.body}';
        _sessionMessages.removeLast();
        return ClaudeResponse(text: errMsg, isError: true);
      }
    } catch (e) {
      _activeClient = null;
      // When client.close() is called mid-request it throws a ClientException
      // or SocketException — treat that as a user cancel
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('clientexception') ||
          errStr.contains('connection closed') ||
          errStr.contains('software caused') ||
          errStr.contains('socketexception')) {
        if (_sessionMessages.isNotEmpty) _sessionMessages.removeLast();
        return ClaudeResponse(text: '', isCancelled: true);
      }
      _sessionMessages.removeLast();
      return ClaudeResponse(text: 'Network error: $e', isError: true);
    }
  }

  // ── Start a new session ───────────────────────────────────────────────────
  void startNewSession() {
    currentSessionId = const Uuid().v4();
    _sessionMessages.clear();
  }

  // ── Load a session from local storage ────────────────────────────────────
  Future<List<ClaudeMessage>> loadSession(String sessionId) async {
    final sessions = await _loadAllSessions();
    final session = sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session != null) {
      currentSessionId = sessionId;
      _sessionMessages
        ..clear()
        ..addAll(session.messages);
      return session.messages;
    }
    return [];
  }

  // ── Get all saved sessions (for history screen) ───────────────────────────
  static Future<List<ClaudeSession>> getAllSessions() async {
    return _loadAllSessions();
  }

  // ── Delete a session ─────────────────────────────────────────────────────
  static Future<void> deleteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _loadAllSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  // ── Internal: save current session to SharedPreferences ──────────────────
  Future<void> _saveCurrentSession(String firstUserMessage) async {
    if (currentSessionId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final sessions = await _loadAllSessions();

    final existingIndex = sessions.indexWhere((s) => s.id == currentSessionId);
    final title = _sessionMessages.isNotEmpty
        ? _truncate(_sessionMessages.first.content, 60)
        : 'New Chat';

    final updatedSession = ClaudeSession(
      id: currentSessionId!,
      title: title,
      createdAt: existingIndex >= 0
          ? sessions[existingIndex].createdAt
          : DateTime.now(),
      messages: List.from(_sessionMessages),
    );

    if (existingIndex >= 0) {
      sessions[existingIndex] = updatedSession;
    } else {
      sessions.insert(0, updatedSession);
    }

    await prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  static Future<List<ClaudeSession>> _loadAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ClaudeSession.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }

  void clearSession() {
    currentSessionId = null;
    _sessionMessages.clear();
  }
}
