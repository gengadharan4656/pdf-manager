import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _box = Hive.box('settings');
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  bool get _isDark => _box.get('darkMode', defaultValue: false) as bool;
  bool get _haptics => _box.get('haptics', defaultValue: true) as bool;
  bool get _autoSave => _box.get('autoSave', defaultValue: true) as bool;
  String get _defaultQuality =>
      _box.get('defaultQuality', defaultValue: 'high') as String;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // App section
          _SettingsSection(title: 'Appearance', children: [
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: _isDark,
              onChanged: (v) {
                _box.put('darkMode', v);
                ref.read(themeModeProvider.notifier).state =
                    v ? ThemeMode.dark : ThemeMode.light;
                setState(() {});
              },
            ),
          ]),

          _SettingsSection(title: 'Scanner', children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Default Camera Quality'),
              subtitle: Text(_defaultQuality.toUpperCase()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showQualityPicker(),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Vibrate on capture'),
              value: _haptics,
              onChanged: (v) {
                _box.put('haptics', v);
                setState(() {});
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.save),
              title: const Text('Auto-Save Scans'),
              subtitle: const Text('Automatically save after scanning'),
              value: _autoSave,
              onChanged: (v) {
                _box.put('autoSave', v);
                setState(() {});
              },
            ),
          ]),

          _SettingsSection(title: 'Storage', children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Storage Location'),
              subtitle: const Text('App Documents Folder'),
              trailing: const Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear Cache'),
              subtitle: const Text('Free up temporary storage'),
              onTap: _clearCache,
            ),
          ]),

          _SettingsSection(title: 'About', children: [
            ListTile(
              leading: const Icon(Icons.star_rate),
              title: const Text('Rate Us'),
              subtitle: const Text('Love the app? Leave a review!'),
              onTap: () async {
                final review = InAppReview.instance;
                if (await review.isAvailable()) {
                  review.requestReview();
                } else {
                  review.openStoreListing(appStoreId: 'YOUR_APP_STORE_ID');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share App'),
              onTap: () {
                // Share app link
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () => launchUrl(Uri.parse('https://yourapp.com/privacy')),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms of Service'),
              onTap: () => launchUrl(Uri.parse('https://yourapp.com/terms')),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Version'),
              subtitle: Text('PDF Manager Pro v$_version'),
            ),
          ]),
        ],
      ),
    );
  }

  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Camera Quality',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          ...['low', 'medium', 'high', 'veryHigh'].map((q) => ListTile(
            leading: Icon(
              _defaultQuality == q
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _defaultQuality == q
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(q == 'veryHigh' ? 'Very High' :
                '${q[0].toUpperCase()}${q.substring(1)}'),
            onTap: () {
              _box.put('defaultQuality', q);
              setState(() {});
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will remove temporary files. Your documents will not be affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Clear temp files
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared'),
                    backgroundColor: Colors.green),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }
}
