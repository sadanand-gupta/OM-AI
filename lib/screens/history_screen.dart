import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:om_ai/constants/app_colors.dart';
import 'package:om_ai/main.dart';
import 'package:om_ai/screens/home_screen.dart';
import 'package:om_ai/screens/settings_screen.dart';
import 'package:om_ai/service/claude_service.dart';

class HistoryScreen extends StatefulWidget {
  final bool refresh;

  const HistoryScreen({super.key, this.refresh = false});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  List<ClaudeSession> _sessions = [];
  String _searchQuery = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final sessions = await ClaudeService.getAllSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
  }

  // Called from HomeScreen after a new message to refresh the list
  void refreshHistory() {
    _loadHistory(forceRefresh: true);
  }

  Future<void> _deleteSession(String sessionId) async {
    await ClaudeService.deleteSession(sessionId);
    setState(() {
      _sessions.removeWhere((s) => s.id == sessionId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Chat deleted",
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
        ),
      );
    }
  }

  List<ClaudeSession> get _filtered {
    if (_searchQuery.isEmpty) return _sessions;
    final q = _searchQuery.toLowerCase();
    return _sessions
        .where((s) => s.title.toLowerCase().contains(q))
        .toList();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    final nowOnly = DateTime(now.year, now.month, now.day);

    if (dateOnly == nowOnly) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'pm' : 'am';
      return 'Today at $hour:$minute $period';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _short(String text) =>
      text.length > 100 ? '${text.substring(0, 100)}...' : text;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildList(context)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildNewChatButton(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Text(
            "History",
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _iconButton(
            icon: Icons.settings_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade700, Colors.white],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: TextField(
          cursorColor: Colors.grey.shade700,
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            prefixIcon:
                const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
            hintText: "Search conversations",
            hintStyle: GoogleFonts.inter(
                color: const Color(0xFF9E9E9E),
                fontSize: 15,
                fontWeight: FontWeight.w400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF1A1A1A), strokeWidth: 2),
      );
    }

    if (_filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadHistory(forceRefresh: true),
        color: const Color(0xFF1A1A1A),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: _buildEmptyState(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      backgroundColor: Colors.white,
      onRefresh: () => _loadHistory(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildItem(context, _filtered[index]),
      ),
    );
  }

  Widget _buildItem(BuildContext context, ClaudeSession session) {
    final preview = session.messages.isNotEmpty
        ? session.messages.last.content
        : '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(conversationId: session.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _short(session.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _short(preview),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: AppColors.iconGray),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(session.createdAt),
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.iconGray),
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await _confirmDeleteDialog();
                  if (confirm) await _deleteSession(session.id);
                }
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              elevation: 6,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Text(
                          "Delete Chat",
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            title: Text(
              "Delete chat?",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900),
            ),
            content: Text(
              "This action cannot be undone.",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Cancel",
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child:
                const Icon(Icons.history, size: 48, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 20),
          Text(
            "No conversations yet",
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a new chat to see it here",
            style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9E9E9E),
                fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildNewChatButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade700, Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              "New Chat",
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2),
            ),
          ],
        ),
      ),
    );
  }
}
