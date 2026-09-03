import 'package:flutter/material.dart';
import '../components/GlobalVariables.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = googleSignIn.currentUser;
    final email = account?.email ?? userEmail ?? 'Not signed in';
    final name = account?.displayName?.trim().isNotEmpty == true ? account!.displayName! : email.split('@').first;
    final unsubscribed = objectBox?.getUnsubscribedEmailsList()?.length ?? 0;
    final skipped = objectBox?.getSkippedEmailsList()?.length ?? 0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(radius: 42, child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontSize: 32))),
          const SizedBox(height: 12),
          Center(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          Center(child: Text(email, style: TextStyle(color: Colors.grey[700]))),
          const SizedBox(height: 24),
          Card(child: Column(children: [
            ProfileField(label: 'Unsubscribed senders', value: '$unsubscribed'),
            ProfileField(label: 'Skipped senders', value: '$skipped'),
            ProfileField(label: 'Today deleted', value: '$deletedToday'),
          ])),
          const SizedBox(height: 12),
          const Text('Your activity is stored locally on this device and is not uploaded by Confygre Email.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const ProfileField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), Text(value, style: TextStyle(color: Colors.grey[800]))]),
  );
}
