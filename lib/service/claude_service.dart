import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:om_ai/config/secrets.dart';

const String _kClaudeApiKey = claudeApiKey;
const String _kClaudeModel = 'claude-3-5-sonnet-20241022';
const String _kAnthropicApiUrl = 'https://api.anthropic.com/v1/messages';
const String _kAnthropicVersion = '2023-06-01';

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

  ClaudeResponse({required this.text, this.isError = false});
}

class ClaudeService {
  String? currentSessionId;
  final List<ClaudeMessage> _sessionMessages = [];

  static const String _sessionsKey = 'om_ai_sessions';

  // ── Send a message to Claude and get a response ──────────────────────────
  Future<ClaudeResponse> sendMessage(String userMessage) async {
    _sessionMessages.add(
      ClaudeMessage(
        role: 'user',
        content: userMessage,
        timestamp: DateTime.now(),
      ),
    );

    // Build messages payload (only role + content for API)
    final apiMessages = _sessionMessages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    try {
      final response = await http.post(
        Uri.parse(_kAnthropicApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _kClaudeApiKey,
          'anthropic-version': _kAnthropicVersion,
        },
        body: jsonEncode({
          'model': _kClaudeModel,
          'max_tokens': 4096,
          'messages': apiMessages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantText =
            data['content']?[0]?['text'] ?? 'No response received.';

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
        final error = jsonDecode(response.body);
        final errMsg =
            error['error']?['message'] ??
            'Request failed (${response.statusCode})';
        // Remove the user message we already added since it failed
        _sessionMessages.removeLast();
        return ClaudeResponse(text: errMsg, isError: true);
      }
    } catch (e) {
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
