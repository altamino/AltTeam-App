import 'package:package_info_plus/package_info_plus.dart';
import '../../api/network/api.dart';

class VersionCheckResult {
  final bool isUpToDate;
  final String latestVersion;
  final String downloadPage;

  const VersionCheckResult({
    required this.isUpToDate,
    required this.latestVersion,
    required this.downloadPage,
  });
}

class VersionCheck {
  static Future<VersionCheckResult> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version;

      final response = await Api.get(
        '/g/s/altteam/version?version=$installedVersion',
      );

      final latestVersion = response['latestVersion'] as String;
      final downloadPage = response['downloadPage'] as String;

      final isUpToDate =
          _compareVersions(installedVersion, latestVersion) >= 0;

      return VersionCheckResult(
        isUpToDate: isUpToDate,
        latestVersion: latestVersion,
        downloadPage: downloadPage,
      );
    } catch (e) {
      return const VersionCheckResult(
        isUpToDate: true,
        latestVersion: '',
        downloadPage: '',
      );
    }
  }

  static int _compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < pa.length || i < pb.length; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }
}