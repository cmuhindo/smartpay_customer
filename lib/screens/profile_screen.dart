import 'package:flutter/material.dart';

import '../models/models.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile user;
  final Future<void> Function() onLogout;

  const ProfileScreen({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My account')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 36)), const SizedBox(height: 12), Text(user.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(user.email), if (user.phoneNumber != null) Text(user.phoneNumber!)]))),
          const SizedBox(height: 16),
          Card(child: Column(children: [ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Account security'), subtitle: const Text('Your session is protected with a secure access token.')), const Divider(height: 1), ListTile(leading: const Icon(Icons.info_outline), title: const Text('About SmartPay'), subtitle: const Text('View your hire-purchase phone loan and repayment information.'))])),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: onLogout, icon: const Icon(Icons.logout), label: const Text('Sign out')),
        ]),
      );
}
