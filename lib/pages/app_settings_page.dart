import 'package:flutter/material.dart';

import '../components/GlobalVariables.dart';
import '../components/emails.dart';
import '../components/objectBox.dart';
import '../models/app_settings_model.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  late AppSettingsModel _model;

  @override
  void initState() {
    super.initState();
    final saved = objectBox?.getAppSettings();
    if (saved != null) {
      permanentDelete = saved.permanentDelete;
      blockTheSender = saved.blockTheSender;
      deleteAllMailsFromTheSender = saved.deleteAllMailsFromTheSender;
      showSkippedEmails = saved.showSkippedEmails;
      showOnlyUnsubscribableEmails = saved.showOnlyUnsubscribableEmails;
    }
    _model = AppSettingsModel(
      permanentDelete: permanentDelete,
      blockTheSender: blockTheSender,
      deleteAllMailsFromTheSender: deleteAllMailsFromTheSender,
      showSkippedEmails: showSkippedEmails,
      showOnlyUnsubscribableEmails: showOnlyUnsubscribableEmails,
    );
  }

  void _save() {
    _model
      ..permanentDelete = permanentDelete
      ..blockTheSender = blockTheSender
      ..deleteAllMailsFromTheSender = deleteAllMailsFromTheSender
      ..showSkippedEmails = showSkippedEmails
      ..showOnlyUnsubscribableEmails = showOnlyUnsubscribableEmails;
    objectBox?.updateAppSettings(_model);
  }

  Widget _toggle({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) =>
      Card(
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          value: value,
          onChanged: (next) { setState(() => onChanged(next)); _save(); },
        ),
      );

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text('Mailbox behavior', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Choose how cleanup actions should work. You can change these at any time.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          _toggle(title: 'Permanent delete', subtitle: 'Delete immediately instead of moving mail to Trash.', value: permanentDelete, onChanged: (v) => permanentDelete = v),
          const SizedBox(height: 8),
          _toggle(title: 'Block the sender', subtitle: 'Keep the existing sender-blocking preference enabled for cleanup.', value: blockTheSender, onChanged: (v) => blockTheSender = v),
          const SizedBox(height: 8),
          _toggle(title: 'Delete all mail from sender', subtitle: 'Apply sender cleanup to every matching message.', value: deleteAllMailsFromTheSender, onChanged: (v) => deleteAllMailsFromTheSender = v),
          const SizedBox(height: 24),
          Text('Review preferences', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _toggle(title: 'Show skipped senders', subtitle: 'Include senders you previously skipped in the cleanup queue.', value: showSkippedEmails, onChanged: (v) => showSkippedEmails = v),
          const SizedBox(height: 8),
          _toggle(title: 'Only show unsubscribable senders', subtitle: 'Focus the cleanup queue on messages with unsubscribe metadata.', value: showOnlyUnsubscribableEmails, onChanged: (v) => showOnlyUnsubscribableEmails = v),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.delete_sweep_outlined, color: Theme.of(context).colorScheme.onErrorContainer),
              title: Text('Empty Gmail Trash', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.w700)),
              subtitle: Text('Permanently delete every message currently in Trash.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              onTap: _emptyTrash,
            ),
          ),
        ],
      );

  Future<void> _emptyTrash() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Empty Trash permanently?'), content: const Text('This action cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Empty Trash'))]));
    if (confirmed != true) return;
    try { await emptyTrash(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trash emptied.'))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not empty Trash: $e'))); }
  }
}
