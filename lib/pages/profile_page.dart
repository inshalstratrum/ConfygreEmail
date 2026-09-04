import 'package:flutter/material.dart';

import '../components/GlobalVariables.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = googleSignIn.currentUser;
    final email = account?.email ?? userEmail ?? 'Not signed in';
    final name = account?.displayName?.trim().isNotEmpty == true
        ? account!.displayName!
        : email.split('@').first;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              CircleAvatar(radius: 34, backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, child: Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(email, maxLines: 1, overflow: TextOverflow.ellipsis)])),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        Text('Your activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(label: 'Unsubscribed', value: '${objectBox?.getUnsubscribedEmailsList()?.length ?? 0}', icon: Icons.unsubscribe_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Skipped', value: '${objectBox?.getSkippedEmailsList()?.length ?? 0}', icon: Icons.skip_next_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Deleted today', value: '$deletedToday', icon: Icons.delete_outline)),
        ]),
        const SizedBox(height: 24),
        Card(child: ListTile(leading: const Icon(Icons.security_outlined), title: const Text('Privacy first', style: TextStyle(fontWeight: FontWeight.w600)), subtitle: const Text('Your cleanup history is stored locally on this device.'))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(label, maxLines: 2)])));
}
