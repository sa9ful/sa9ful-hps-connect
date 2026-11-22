import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:material_ui/material_ui.dart';

/// CI বিল্ডের সময় `--dart-define` দিয়ে বসানো হয় (.github/workflows/android.yml)।
/// লোকাল/টেস্ট বিল্ডে 0 থাকে, তখন আপডেট চেক হয় না।
const int kAppBuildNumber = int.fromEnvironment('APP_BUILD_NUMBER');
const String kAppVersion =
    String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

/// releases রিপোর version.json।
const String kUpdateUrl = String.fromEnvironment(
  'UPDATE_URL',
  defaultValue:
      'https://raw.githubusercontent.com/sa9ful/hps-connect-releases/main/version.json',
);

class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.releaseNotes,
  });

  final String version;
  final int buildNumber;
  final String apkUrl;
  final String releaseNotes;

  static AppUpdate? fromJson(Map<String, dynamic> j) {
    final build = j['build_number'];
    final url = j['latest_apk_url'] ?? j['apk_url'];
    if (build is! num || url is! String) return null;
    return AppUpdate(
      version: '${j['version'] ?? ''}',
      buildNumber: build.toInt(),
      apkUrl: url,
      releaseNotes: '${j['release_notes'] ?? ''}'.trim(),
    );
  }
}

/// নতুন বিল্ড থাকলে সেটা দেয়, না থাকলে বা নেট না থাকলে null।
Future<AppUpdate?> fetchAvailableUpdate({
  int currentBuild = kAppBuildNumber,
  String url = kUpdateUrl,
}) async {
  if (currentBuild <= 0 || !Platform.isAndroid) return null;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final uri = Uri.parse(url).replace(
      queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
    );
    final req = await client.getUrl(uri);
    final res = await req.close().timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final body = await res.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    if (data is! Map<String, dynamic>) return null;
    final update = AppUpdate.fromJson(data);
    if (update == null || update.buildNumber <= currentBuild) return null;
    return update;
  } catch (e) {
    debugPrint('আপডেট চেক করা যায়নি: $e');
    return null;
  } finally {
    client.close(force: true);
  }
}

const _channel = MethodChannel('com.hps.connect/update');

Future<void> _openInBrowser(String url) async {
  try {
    await _channel.invokeMethod<void>('openUrl', {'url': url});
  } catch (e) {
    debugPrint('লিংক খোলা যায়নি: $e');
  }
}

/// অ্যাপ চালুর পর একবার ডাকা হয়। নতুন ভার্সন থাকলে ডায়ালগ দেখায়।
Future<void> checkForUpdateAndPrompt(BuildContext context) async {
  final update = await fetchAvailableUpdate();
  if (update == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('নতুন আপডেট এসেছে'),
      content: SingleChildScrollView(
        child: Text(
          'HPS Connect v${update.version} পাওয়া যাচ্ছে '
          '(আপনার ভার্সন v$kAppVersion)।'
          '${update.releaseNotes.isEmpty ? '' : '\n\n${update.releaseNotes}'}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('পরে'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            _openInBrowser(update.apkUrl);
          },
          child: const Text('ডাউনলোড'),
        ),
      ],
    ),
  );
}
