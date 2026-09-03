import 'dart:ffi';

import 'package:flutter/material.dart';
import '../pages/history_page.dart';
import '../pages/home_page.dart';

import '../components/GlobalVariables.dart';
import '../components/objectBox.dart';
import '../components/emails.dart';
import '../models/app_settings_model.dart';
import '../objectbox.g.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {

  AppSettingsModel _appSettingsModel = AppSettingsModel(
      //unsubscribeAndMoveToTrash: unsubscribeAndMoveToTrash,
      permanentDelete: permanentDelete,
      blockTheSender: blockTheSender,
      deleteAllMailsFromTheSender: deleteAllMailsFromTheSender,
      showSkippedEmails: showSkippedEmails,
      showOnlyUnsubscribableEmails: showOnlyUnsubscribableEmails
  );

  @override
  void initState() {
    super.initState();

    AppSettingsModel? data = objectBox?.getAppSettings();

    if(data != null){
      //unsubscribeAndMoveToTrash = data.unsubscribeAndMoveToTrash;
      permanentDelete = data.permanentDelete;
      blockTheSender = data.blockTheSender;
      deleteAllMailsFromTheSender = data.deleteAllMailsFromTheSender;
      showSkippedEmails = data.showSkippedEmails;
      showOnlyUnsubscribableEmails = data.showOnlyUnsubscribableEmails;
    }
  }

  void updateToLocalDB(){
    //_appSettingsModel.unsubscribeAndMoveToTrash = unsubscribeAndMoveToTrash;
    _appSettingsModel.permanentDelete = permanentDelete;
    _appSettingsModel.blockTheSender = blockTheSender;
    _appSettingsModel.deleteAllMailsFromTheSender = deleteAllMailsFromTheSender;
    _appSettingsModel.showSkippedEmails = showSkippedEmails;
    _appSettingsModel.showOnlyUnsubscribableEmails = showOnlyUnsubscribableEmails;
    objectBox?.updateAppSettings(_appSettingsModel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0, left: 25, right: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Permanent delete'),
              subtitle: const Text('Delete instead of moving messages to Trash'),
              activeColor: Colors.blueAccent,
              value: permanentDelete,
              onChanged: (bool value) {
                setState(() { permanentDelete = value; updateToLocalDB(); });
              },
            ),
            // First toggle switch
            // SwitchListTile(
            //   title: Text(
            //     'Unsubscribe and move to trash',
            //   ),
            //   activeColor: Colors.blueAccent,
            //   inactiveThumbColor: Colors.black,
            //   value: unsubscribeAndMoveToTrash,
            //   onChanged: (bool value) {
            //     setState(() {
            //       unsubscribeAndMoveToTrash = value;
            //       updateToLocalDB();
            //     });
            //   },
            // ),
            // Second toggle switch
            // SwitchListTile(
            //   title: Text('Permanent delete'),
            //   activeColor: Colors.blueAccent,
            //   inactiveThumbColor: Colors.black,
            //   value: permanentDelete,
            //   onChanged: (bool value) {
            //     setState(() {
            //       permanentDelete = value;
            //       updateToLocalDB();
            //     });
            //   },
            // ),
            // Third toggle switch
            SwitchListTile(
              title: Text('Block the sender'),
              activeColor: Colors.blueAccent,
              inactiveThumbColor: Colors.black,
              value: blockTheSender,
              onChanged: (bool value) {
                setState(() {
                  blockTheSender = value;
                  updateToLocalDB();
                });
              },
            ),
            //Fourth toggle switch
            SwitchListTile(
              title: Text('Delete all mails from the sender'),
              activeColor: Colors.blueAccent,
              inactiveThumbColor: Colors.black,
              value: deleteAllMailsFromTheSender,
              onChanged: (bool value) {
                setState(() {
                  deleteAllMailsFromTheSender = value;
                  updateToLocalDB();
                });
              },
            ),
            //Fifth toggle switch
            SwitchListTile(
              title: Text('Show skipped emails'),
              activeColor: Colors.blueAccent,
              inactiveThumbColor: Colors.black,
              value: showSkippedEmails,
              onChanged: (bool value) {
                setState(() {
                  showSkippedEmails = value;
                  updateToLocalDB();
                });
              },
            ),
            //Sixth toggle switch
            SwitchListTile(
              title: Text('Show only unsubscribable emails'),
              activeColor: Colors.blueAccent,
              inactiveThumbColor: Colors.black,
              value: showOnlyUnsubscribableEmails,
              onChanged: (bool value) {
                setState(() {
                  showOnlyUnsubscribableEmails = value;
                  updateToLocalDB();
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear all messages from Trash'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Empty Trash?'), content: const Text('This permanently deletes every message currently in Gmail Trash.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Empty Trash'))]));
                  if (confirmed == true) {
                    try { await emptyTrash(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trash emptied'))); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not empty Trash: $e'))); }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
