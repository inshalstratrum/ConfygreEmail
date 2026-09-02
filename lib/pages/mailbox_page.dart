import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart' as gMail;

import '../components/emails.dart';

class MailboxPage extends StatefulWidget {
  const MailboxPage({super.key});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  static const filters = <String, String>{
    'All mail': '',
    'Primary': 'category:primary',
    'Promotions': 'category:promotions',
    'Updates': 'category:updates',
    'Social': 'category:social',
    'Important': 'is:important',
    'Purchases': 'category:purchases',
    'Spam': 'in:spam',
    'Sent': 'in:sent',
    'Drafts': 'in:drafts',
    'Trash': 'in:trash',
  };

  String selectedFilter = 'All mail';
  List<gMail.Message> messages = [];
  final selected = <String>{};
  bool loading = true;
  String? error;

  String header(gMail.Message message, String name) {
    for (final item
        in message.payload?.headers ?? <gMail.MessagePartHeader>[]) {
      if (item.name?.toLowerCase() == name.toLowerCase())
        return item.value ?? '';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await listMailboxMessages(query: filters[selectedFilter]!);
      if (!mounted) return;
      setState(() {
        messages = result;
        selected.clear();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> deleteSelected() async {
    if (selected.isEmpty) return;
    try {
      await deleteSelectedMessages(selected.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${selected.length} message(s) moved to Trash.')),
      );
      await loadMessages();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> clearTrash() async {
    try {
      await emptyTrash();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Trash emptied.')));
      await loadMessages();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not empty Trash: $e')));
    }
  }

  void openMessage(gMail.Message message) {
    final subject = header(message, 'subject');
    final from = header(message, 'from');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(subject.isEmpty ? '(no subject)' : subject),
        content: SingleChildScrollView(
          child: SelectableText(
              'From: $from\n\n${message.snippet ?? 'No preview available.'}'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mailbox'),
        actions: [
          if (selected.isNotEmpty)
            IconButton(
                onPressed: deleteSelected,
                icon: const Icon(Icons.delete_outline)),
          if (selectedFilter == 'Trash')
            IconButton(
                onPressed: clearTrash, icon: const Icon(Icons.delete_forever)),
          IconButton(onPressed: loadMessages, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: const InputDecoration(
                  labelText: 'Filter', border: OutlineInputBorder()),
              items: filters.keys
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedFilter = value);
                loadMessages();
              },
            ),
          ),
          if (selected.isNotEmpty)
            Row(children: [
              Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('${selected.length} selected')),
              const Spacer(),
              TextButton(
                  onPressed: deleteSelected,
                  child: const Text('Delete selected')),
            ]),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(error!)))
                    : messages.isEmpty
                        ? const Center(
                            child: Text('No messages in this filter.'))
                        : ListView.builder(
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final id = message.id!;
                              final subject = header(message, 'subject');
                              final from = header(message, 'from');
                              return ListTile(
                                leading: Checkbox(
                                  value: selected.contains(id),
                                  onChanged: (checked) => setState(() {
                                    if (checked == true)
                                      selected.add(id);
                                    else
                                      selected.remove(id);
                                  }),
                                ),
                                title: Text(
                                    subject.isEmpty ? '(no subject)' : subject,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    '$from\n${message.snippet ?? ''}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                isThreeLine: true,
                                onTap: () => openMessage(message),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
