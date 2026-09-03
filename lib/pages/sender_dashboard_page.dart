import 'package:flutter/material.dart';

import '../components/GlobalVariables.dart';
import '../components/emails.dart';
import '../models/email_data_model.dart';

class SenderDashboardPage extends StatefulWidget {
  const SenderDashboardPage({super.key});

  @override
  State<SenderDashboardPage> createState() => _SenderDashboardPageState();
}

class _SenderDashboardPageState extends State<SenderDashboardPage> {
  final _searchController = TextEditingController();
  final Map<String, int> _counts = {};
  bool _loadingCounts = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _loadCounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, EmailDataModel>> get _senders {
    final entries = emailDataList.entries.where((entry) {
      final sender =
          '${entry.value.senderName ?? ''} ${entry.key}'.toLowerCase();
      return _query.isEmpty || sender.contains(_query);
    }).toList();
    entries.sort((a, b) => (_counts[b.key] ?? b.value.count)
        .compareTo(_counts[a.key] ?? a.value.count));
    return entries;
  }

  int get _totalClutter =>
      _counts.values.fold(0, (total, count) => total + count);

  Future<void> _loadCounts() async {
    if (emailDataList.isEmpty || _loadingCounts) return;
    setState(() => _loadingCounts = true);
    for (final entry in emailDataList.entries.toList()) {
      if (!mounted) return;
      try {
        final count = await getUnreadEmailCount(entry.key);
        if (mounted) setState(() => _counts[entry.key] = count);
      } catch (_) {
        // The sender remains visible even if one Gmail count request fails.
      }
    }
    if (mounted) setState(() => _loadingCounts = false);
  }

  Future<void> _deleteAll(String email, int count) async {
    try {
      final ids = await getBulkEmailList(email);
      await deleteEmail(ids);
      deletedToday += ids.length;
      objectBox?.updateTilesData(unsubscribedToday, skippedToday, deletedToday);
      if (!mounted) return;
      setState(() {
        emailDataList.remove(email);
        _counts.remove(email);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Messages moved to Trash.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update Gmail. Try again.')),
        );
      }
    }
  }

  Future<void> _unsubscribe(
      String email, EmailDataModel data, int count) async {
    try {
      await unSubEmail(data.mailToString ?? '', data.mailToSubject ?? '',
          data.directString ?? '');
      objectBox?.addUnsubscribedEmail(email, count, '');
      unsubscribedToday += 1;
      objectBox?.updateTilesData(unsubscribedToday, skippedToday, deletedToday);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsubscribe request sent.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unsubscribe request could not be sent.')),
        );
      }
    }
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AuthSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _senders;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Inbox cleanup',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              tooltip: 'Google account settings',
              onPressed: _openSettings,
              icon: const Icon(Icons.tune_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            Text('Your inbox, made lighter.',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('Review the senders creating the most clutter.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.black54)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: _StatCard(
                      label: 'Total senders',
                      value: '${emailDataList.length}',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF5B5CE2))),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: 'Unread clutter',
                      value: _loadingCounts && _totalClutter == 0
                          ? '…'
                          : '$_totalClutter',
                      icon: Icons.mark_email_unread_rounded,
                      color: const Color(0xFFE77D46))),
            ]),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search senders',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear_rounded)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            if (entries.isEmpty)
              _EmptyState(loading: _loadingCounts)
            else
              ...entries.map((entry) => _SenderCard(
                    email: entry.key,
                    data: entry.value,
                    count: _counts[entry.key] ?? entry.value.count,
                    onDelete: () => _deleteAll(
                        entry.key, _counts[entry.key] ?? entry.value.count),
                    onUnsubscribe: () => _unsubscribe(entry.key, entry.value,
                        _counts[entry.key] ?? entry.value.count),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A111827),
                  blurRadius: 18,
                  offset: Offset(0, 6))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, size: 19, color: color)),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: Colors.black54, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _SenderCard extends StatelessWidget {
  final String email;
  final EmailDataModel data;
  final int count;
  final VoidCallback onDelete, onUnsubscribe;
  const _SenderCard(
      {required this.email,
      required this.data,
      required this.count,
      required this.onDelete,
      required this.onUnsubscribe});
  @override
  Widget build(BuildContext context) {
    final name = (data.senderName ?? '').trim().isEmpty
        ? email
        : data.senderName!.trim();
    final initial = name.substring(0, 1).toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9EAF0))),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE9E8FF),
              child: Text(initial,
                  style: const TextStyle(
                      color: Color(0xFF5152C9),
                      fontWeight: FontWeight.w800,
                      fontSize: 18))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 3),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 12))
              ])),
          Text('$count',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: onUnsubscribe,
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: const Text('Delete all & unsubscribe'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5758D6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13))))),
        Row(children: [
          Expanded(
              child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete only'),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.black54))),
          Expanded(
              child: TextButton.icon(
                  onPressed: onUnsubscribe,
                  icon: const Icon(Icons.unsubscribe_rounded, size: 18),
                  label: const Text('Unsubscribe only'),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.black54))),
        ]),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool loading;
  const _EmptyState({required this.loading});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(children: [
        Icon(loading ? Icons.sync_rounded : Icons.mark_email_read_rounded,
            size: 48, color: const Color(0xFF5758D6)),
        const SizedBox(height: 16),
        Text(loading ? 'Scanning your inbox…' : 'No senders to review',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
            loading
                ? 'We are grouping messages by sender.'
                : 'Your inbox is looking good.',
            style: const TextStyle(color: Colors.black54))
      ]));
}

class _AuthSettingsSheet extends StatelessWidget {
  const _AuthSettingsSheet();
  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Google account',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(googleSignIn.currentUser?.email ?? 'Not connected',
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 20),
                ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: const Text('OAuth access'),
                    subtitle:
                        const Text('Tokens are managed by Google Sign-In'),
                    trailing: Icon(
                        googleSignIn.currentUser == null
                            ? Icons.error_outline
                            : Icons.check_circle,
                        color: googleSignIn.currentUser == null
                            ? Colors.orange
                            : Colors.green)),
                const SizedBox(height: 8),
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done')))
              ])));
}
