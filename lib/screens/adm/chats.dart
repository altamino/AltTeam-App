import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/user_avatar.dart';

class AdminChatsScreen extends StatefulWidget {
  const AdminChatsScreen({super.key});

  @override
  State<AdminChatsScreen> createState() => _AdminChatsScreenState();
}

class _AdminChatsScreenState extends State<AdminChatsScreen> {
  bool _loading = false;
  String? _error;
  List<_ChatPreview> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _chats = [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AdminHeader(title: AppLocalizations.t('drawer.chats')),
              Expanded(child: _buildBody(colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppPalette colors) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.accentPrimary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: TextStyle(color: colors.error, fontSize: 13), textAlign: TextAlign.center),
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 44, color: colors.textMuted),
            const SizedBox(height: 14),
            Text(
              '—',
              style: TextStyle(color: colors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: colors.accentPrimary,
      backgroundColor: colors.glassFill,
      onRefresh: _loadChats,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _chatTile(colors, _chats[i]),
      ),
    );
  }

  Widget _chatTile(AppPalette colors, _ChatPreview chat) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/admin/chats/${chat.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: colors.glassFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.glassBorder),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                UserAvatar(
                  nickname: chat.title,
                  iconUrl: null,
                  size: 46,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat.title,
                              style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            chat.time,
                            style: TextStyle(color: colors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.isGroup ? '${chat.senderName}: ${chat.lastMessage}' : chat.lastMessage,
                              style: TextStyle(color: colors.textSecondary, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.accentPrimary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${chat.unreadCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatPreview {
  final String id;
  final String title;
  final String lastMessage;
  final String senderName;
  final String time;
  final int unreadCount;
  final bool isGroup;

  const _ChatPreview({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.senderName,
    required this.time,
    required this.unreadCount,
    required this.isGroup,
  });
}

