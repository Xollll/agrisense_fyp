import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../widgets/app_bar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: const ModernAppBar(
        title: "Settings",
        subtitle: "App preferences & options",
        icon: Icons.settings,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark Mode Toggle
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: const Text("Enable dark theme"),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),

          // Example extra setting
          SwitchListTile(
            title: const Text("Live Updates"),
            subtitle: const Text("Enable real-time detection updates"),
            value: true, // implement your logic
            onChanged: (value) {
              // TODO: connect to app logic
            },
            secondary: const Icon(Icons.update),
          ),

          SwitchListTile(
            title: const Text("Notifications"),
            subtitle: const Text("Receive alerts for plant diseases"),
            value: true, // implement your logic
            onChanged: (value) {
              // TODO: connect to app logic
            },
            secondary: const Icon(Icons.notifications_active),
          ),
        ],
      ),
    );
  }
}
