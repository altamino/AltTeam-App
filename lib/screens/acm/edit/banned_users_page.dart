import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'deps.dart';
import 'widgets/member_tile.dart';
import '../../../core/api/repositories/altacm.dart';

class BannedUsersPage extends StatefulWidget {
  final int ndcId;
  const BannedUsersPage({super.key, required this.ndcId});

  @override
  State<BannedUsersPage> createState() => _BannedUsersPageState();
}

class _BannedUsersPageState extends State<BannedUsersPage> {
  static const _pageSize = 25;

  final _repo = AltACMRepository();
  final _scroll = ScrollController();
  final _users = <Map<String, dynamic>>[];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        _load();
      }
    });
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore || (!reset && !_hasMore)) return;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _hasMore = true;
        _users.clear();
      });
    }
    _loadingMore = true;
    try {
      final res = await _repo.getCommunityBannedUsers(
        widget.ndcId,
        start: _users.length,
        size: _pageSize,
      );

      final list = (res['userProfileList'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() {
        _users.addAll(list);
        _hasMore = list.length >= _pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _loadingMore = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openModeration(Map<String, dynamic> user) async {
    final uid = user['uid']?.toString();
    if (uid == null || uid.isEmpty) return;
    await context.push('/user/$uid?ndcId=${widget.ndcId}');
    if (mounted) _load(reset: true); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t('admin.community.banned_users')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _users.isEmpty
              ? Center(
                  child: TextButton(
                    onPressed: () => _load(reset: true),
                    child: Text(_error!),
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Text(
                          AppLocalizations.t('admin.community.banned_empty')),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(reset: true),
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= _users.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }
                          final u = _users[i];
                          return MemberTile(
                            user: u,
                            isSelf: false,
                            onOpen: () => _openModeration(u),
                            onManage: null,
                          );
                        },
                      ),
                    ),
    );
  }
}