import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:just_3/core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box _settingsBox;
  String _selectedTheme = 'system';

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settingsBox');
    _loadThemePreference();
  }

  void _loadThemePreference() {
    setState(() {
      _selectedTheme = _settingsBox.get('themeMode', defaultValue: 'dark');
    });
  }

  void _changeTheme(String? theme) {
    if (theme == null) return;

    setState(() {
      _selectedTheme = theme;
    });

    ThemeMode mode = theme == 'light'
        ? ThemeMode.light
        : theme == 'dark'
        ? ThemeMode.dark
        : ThemeMode.system;

    widget.onThemeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * .6,
            padding: EdgeInsets.all(24),
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pastelGreenColor,
                    ),
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.brightness_6),
                  title: Text('Theme'),
                  subtitle: Text(_getThemeDisplayName(_selectedTheme)),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    _showThemeDialog();
                  },
                ),

                Divider(),

                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System default';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Light'),
              value: 'light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                _changeTheme(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Dark'),
              value: 'dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                _changeTheme(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('System default'),
              value: 'system',
              groupValue: _selectedTheme,
              onChanged: (value) {
                _changeTheme(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About'),
        content: Text(
          'Just 3\nVersion 1.0.0\n\nA simple app to manage your daily tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
