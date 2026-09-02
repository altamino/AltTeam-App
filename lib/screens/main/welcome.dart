import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/repositories/users.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/coming_soon_placeholder.dart';
import '../../core/api/repositories/blogs.dart';
import 'announcement_details.dart';
import '../../core/api/objects/args/roles.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _usersRepo = UsersRepository();
  final _blogsRepo = BlogsRepository();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _profile;
  List<dynamic> _announcements = [];

  bool _profileLoading = true;
  bool _blogsLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _profileLoading = true;
      _blogsLoading = true;
      _error = null;
    });

    await Future.wait([
      _loadProfile(),
      _loadAnnouncements(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _usersRepo.getUserProfile(Storage.userId ?? '', 0);
      if (!mounted) return;
      setState(() { _profile = profile; _profileLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _profileLoading = false; });
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final response = await _blogsRepo.getAnnouncements(
        language: 'en',
        start: 0,
        size: 25,
      );
      if (!mounted) return;
      setState(() {
        _announcements = response['blogList'] as List<dynamic>? ?? [];
        _blogsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _blogsLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final nickname = _profile?['nickname'] as String? ?? '';
    final iconUrl = _profile?['icon'] as String?;
    final isVerified = _profile?['isNicknameVerified'] as bool? ?? false;
    final role = Storage.role ?? _profile?['role'] as int? ?? 0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        nickname: nickname,
        aminoId: Storage.aminoId ?? 'null',
        iconUrl: iconUrl,
        isVerified: isVerified,
        role: role,
        isTelegramLinked: Storage.telegramId != null,
      ),
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
              _buildHeader(colors),
              Expanded(
                child: _error != null
                    ? Center(
                        child: Text(_error!, style: TextStyle(color: colors.error, fontSize: 13)),
                      )
                    : (_profileLoading || _blogsLoading)
                        ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                        : _buildContent(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.glassFill,
        border: Border(bottom: BorderSide(color: colors.glassBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Icon(Icons.hub_rounded, color: colors.accentPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.t('auth.login.brand'),
            style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer()
        ],
      ),
    );
  }

  Widget _buildContent(AppPalette colors) {
    final canCreate = RoleTypes.isAnnouncementsRole(Storage.role);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.t('announcements.title'),
                style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (canCreate)
                IconButton(
                  icon: Icon(Icons.add_circle_rounded, color: colors.accentPrimary, size: 24),
                  onPressed: () async {
                    await context.push('/admin/announcements/create');
                    _loadAnnouncements();
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              color: colors.accentPrimary,
              backgroundColor: colors.glassFill,
              onRefresh: _loadAnnouncements,
              child: _announcements.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: ComingSoonPlaceholder(
                            icon: Icons.campaign_outlined,
                            text: AppLocalizations.t('announcements.empty'),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final item = _announcements[index] as Map<String, dynamic>;
                        return _buildAnnouncementCard(colors, item);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(AppPalette colors, Map<String, dynamic> item) {
    final author = item['author'] as Map<String, dynamic>? ?? {};
    final authorName = author['nickname'] as String? ?? AppLocalizations.t('announcements.details.system_author');
    final authorAvatar = author['icon'] as String?;
    final title = item['title'] as String? ?? AppLocalizations.t('announcements.details.no_title');

    String previewContent = item['content'] as String? ?? '';
    previewContent = previewContent.replaceAll(RegExp(r'\[[BICS]+\]'), '');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: colors.glassFill,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.glassBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AnnouncementDetailsScreen(announcement: item),
            ),
          );

          if (result == true) {
            _loadAnnouncements();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors.accentPrimary.withOpacity(0.2),
                    backgroundImage: authorAvatar != null ? NetworkImage(authorAvatar) : null,
                    child: authorAvatar == null
                        ? Icon(Icons.person, size: 16, color: colors.accentPrimary)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    authorName,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title.trim(),
                style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                previewContent.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textPrimary.withOpacity(0.8), fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}