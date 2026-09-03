import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import '../components/emails.dart';

class MailListPage extends StatefulWidget {
  final String sender;
  const MailListPage({super.key, required this.sender});

  @override
  State<MailListPage> createState() => _MailListPageState();
}

class _MailListPageState extends State<MailListPage> {
  final List<gmail.Message> _messages = [];
  final Set<String> _selected = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      String? token;
      do {
        final response = await gmailApi.users.messages.list('me', q: 'from:${widget.sender}', pageToken: token, maxResults: 100);
        _messages.addAll(response.messages ?? const []);
        token = response.nextPageToken;
      } while (token != null);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<gmail.Message> _details(String id) => gmailApi.users.messages.get('me', id, format: 'full');

  String _header(gmail.Message message, String name) => message.payload?.headers?.firstWhere((h) => h.name?.toLowerCase() == name.toLowerCase(), orElse: () => gmail.MessagePartHeader()).value ?? '';

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    await deleteEmail(_selected.toList());
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => _selected.contains(m.id));
      _selected.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected messages deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sender, overflow: TextOverflow.ellipsis),
        actions: [IconButton(onPressed: _selected.isEmpty ? null : _deleteSelected, icon: const Icon(Icons.delete))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!)))
              : _messages.isEmpty
                  ? const Center(child: Text('No messages found'))
                  : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final id = message.id ?? '';
                        final subject = _header(message, 'Subject');
                        final date = _header(message, 'Date');
                        return CheckboxListTile(
                          value: _selected.contains(id),
                          onChanged: (checked) => setState(() => checked == true ? _selected.add(id) : _selected.remove(id)),
                          title: Text(subject.isEmpty ? '(No subject)' : subject, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(date.isEmpty ? (message.snippet ?? '') : date, maxLines: 2, overflow: TextOverflow.ellipsis),
                          secondary: IconButton(icon: const Icon(Icons.visibility), onPressed: () async {
                            final detail = await _details(id);
                            if (!context.mounted) return;
                            showDialog(context: context, builder: (_) => AlertDialog(title: Text(_header(detail, 'Subject')), content: SingleChildScrollView(child: Text(detail.snippet ?? 'No message preview available.')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
                          }),
                        );
                      },
                    ),
      floatingActionButton: _messages.isEmpty ? null : FloatingActionButton.extended(onPressed: _selected.isEmpty ? null : _deleteSelected, icon: const Icon(Icons.delete), label: Text('Delete ${_selected.length}')),
    );
  }
}
