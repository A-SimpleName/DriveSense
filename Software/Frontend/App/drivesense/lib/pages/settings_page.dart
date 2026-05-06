import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Account'),
            onTap: () => Navigator.pushNamed(context, 'AccountPage'),
          ),
          ListTile(
            title: const Text('App Design'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}