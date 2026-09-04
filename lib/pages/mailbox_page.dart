import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import '../components/emails.dart';
import '../components/skeleton.dart';
import '../state/mailbox_controller.dart';

class MailboxPage extends StatelessWidget {
  const MailboxPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => MailboxController()..load(),
        child: const _MailboxView(),
      );
}

class _MailboxView extends StatefulWidget {
  const _MailboxView();

  @override
  State<_MailboxView> createState() => _MailboxViewState();
}

class _MailboxViewState extends State<_MailboxView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _header(gmail.Message message, String name) => context.read<MailboxController>().header(message, name);

  Future<void> _confirmDelete({String? id}) async {
    final controller = context.read<MailboxController>();
    final ids = id == null ? controller.selected.toList() : [id];
    if (ids.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text('${ids.length} message(s) will be moved to Gmail Trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Move to Trash')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deleteSelectedMessages(ids);
      controller.removeFromView(ids);
      if (mounted) _notice('${ids.length} message(s) moved to Trash.');
    } catch (e) {
      if (mounted) _notice('Delete failed: $e');
    }
  }

  Future<void> _unsubscribe(gmail.Message message) async {
    final from = _header(message, 'from');
    final parsed = parseUnsubscribeString(_header(message, 'list-unsubscribe'));
    if (parsed.mailToString == null && parsed.directString == null) {
      _notice('This sender does not provide an unsubscribe link.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsubscribe from sender?'),
        content: Text('Open the unsubscribe action provided by $from. The message will not be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unsubscribe')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await unSubEmail(parsed.mailToString ?? '', parsed.mailToSubject ?? '', parsed.directString ?? '');
      if (mounted) _notice('Unsubscribe request sent.');
    } catch (e) {
      if (mounted) _notice('Unsubscribe failed: $e');
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MailboxController>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mailbox'),
        actions: [
          if (controller.selected.isNotEmpty)
            IconButton(tooltip: 'Delete selected', onPressed: _confirmDelete, icon: const Icon(Icons.delete_outline)),
          if (controller.filter == 'Trash')
            IconButton(tooltip: 'Empty Trash', onPressed: () => _emptyTrash(controller), icon: const Icon(Icons.delete_sweep_outlined)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search sender, subject, or preview',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(onPressed: () { _searchController.clear(); controller.setSearch(''); setState(() {}); }, icon: const Icon(Icons.clear)),
              ],
              onChanged: (value) { controller.setSearch(value); setState(() {}); },
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: MailboxController.filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final value = MailboxController.filters.keys.elementAt(index);
                return FilterChip(label: Text(value), selected: controller.filter == value, onSelected: (_) => controller.setFilter(value));
              },
            ),
          ),
          if (controller.selected.isNotEmpty)
            Material(
              color: scheme.secondaryContainer,
              child: ListTile(
                dense: true,
                leading: IconButton(tooltip: 'Select all', onPressed: controller.selectAllVisible, icon: const Icon(Icons.select_all)),
                title: Text('${controller.selected.length} selected'),
                trailing: FilledButton.tonalIcon(onPressed: _confirmDelete, icon: const Icon(Icons.delete_outline), label: const Text('Delete')),
              ),
            ),
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  Widget _buildBody(MailboxController controller) {
    if (controller.loading) return const MailboxSkeleton();
    if (controller.error != null && controller.messages.isEmpty) {
      return Center(child: FilledButton.icon(onPressed: () => controller.load(force: true), icon: const Icon(Icons.refresh), label: const Text('Retry')));
    }
    if (controller.visibleMessages.isEmpty) {
      return RefreshIndicator(onRefresh: () => controller.load(force: true), child: ListView(children: const [SizedBox(height: 180), Icon(Icons.inbox_outlined, size: 54), SizedBox(height: 12), Center(child: Text('No messages found'))]));
    }
    return RefreshIndicator(
      onRefresh: () => controller.load(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: controller.visibleMessages.length + (controller.nextPageToken != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.visibleMessages.length) {
            if (!controller.loadingMore) controller.loadMore();
            return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
          }
          final message = controller.visibleMessages[index];
          final id = message.id!;
          final from = _header(message, 'from');
          final subject = _header(message, 'subject');
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Checkbox(value: controller.selected.contains(id), onChanged: (value) => controller.toggleSelected(id, value == true)),
              title: Text(subject.isEmpty ? '(no subject)' : subject, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('$from\n${message.snippet ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
              isThreeLine: true,
              onTap: () => _openMessage(message),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => value == 'delete' ? _confirmDelete(id: id) : _unsubscribe(message),
                itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'))), PopupMenuItem(value: 'unsubscribe', child: ListTile(leading: Icon(Icons.unsubscribe_outlined), title: Text('Unsubscribe')))],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openMessage(gmail.Message message) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_header(message, 'subject').isEmpty ? '(no subject)' : _header(message, 'subject')),
          content: SingleChildScrollView(child: SelectableText('From: ${_header(message, 'from')}\n\n${message.snippet ?? 'No preview available.'}')),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      );

  Future<void> _emptyTrash(MailboxController controller) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Empty Trash permanently?'), content: const Text('This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Empty Trash'))]));
    if (confirmed != true) return;
    await emptyTrash();
    if (mounted) { _notice('Trash emptied.'); controller.load(force: true); }
  }
}
