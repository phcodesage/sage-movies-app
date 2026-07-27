import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:sagemovies/services/api_service.dart';

class AppVersionInfo {
  final String latestVersion;
  final int versionCode;
  final String downloadUrl;
  final String directApkUrl;
  final String releaseNotes;
  final bool forceUpdate;

  AppVersionInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.downloadUrl,
    required this.directApkUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: json['latest_version'] ?? '1.0.1',
      versionCode: json['version_code'] ?? 2,
      downloadUrl: json['download_url'] ?? 'https://link-center.net/7848832/gBVDxSZ1rUTX',
      directApkUrl: json['direct_apk_url'] ?? '',
      releaseNotes: json['release_notes'] ?? 'New features and performance updates available.',
      forceUpdate: json['force_update'] ?? false,
    );
  }
}

class UpdateService {
  static const int currentVersionCode = 1;
  static const String currentVersionName = '1.0.0';

  static ValueNotifier<AppVersionInfo?> availableUpdate = ValueNotifier(null);

  static Future<AppVersionInfo?> checkUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/api/app-version'),
            headers: ApiService.defaultHeaders,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final info = AppVersionInfo.fromJson(data);
        if (info.versionCode > currentVersionCode) {
          availableUpdate.value = info;
          return info;
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
    return null;
  }

  static void promptUpdateIfNeeded(BuildContext context, {bool showNoUpdateToast = false}) async {
    final updateInfo = await checkUpdate();

    if (!context.mounted) return;

    if (updateInfo == null) {
      if (showNoUpdateToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your app is up to date (v1.0.0)'),
            backgroundColor: Color(0xFF1E1E24),
          ),
        );
      }
      return;
    }

    showUpdateDialog(context, updateInfo);
  }

  static void showUpdateDialog(BuildContext context, AppVersionInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141419),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  color: Color(0xFFE50914),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version ${updateInfo.latestVersion}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WHAT\'S NEW:',
                style: TextStyle(
                  color: Color(0xFFE50914),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  updateInfo.releaseNotes,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (!updateInfo.forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Later',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse(updateInfo.downloadUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.download, size: 18),
              label: const Text(
                'Update Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
