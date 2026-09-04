import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import '../components/emails.dart';

class MailboxPageResult {
  final List<gmail.Message> messages;
  final String? nextPageToken;
  const MailboxPageResult(this.messages, this.nextPageToken);
}

class _CachedMailbox {
  final List<gmail.Message> messages;
  final DateTime savedAt;
  const _CachedMailbox(this.messages, this.savedAt);
}

class MailboxController extends ChangeNotifier {
  static const filters = <String, String>{
    'All mail': '',
    'Inbox': 'in:inbox',
    'Primary': 'category:primary',
    'Promotions': 'category:promotions',
    'Updates': 'category:updates',
    'Social': 'category:social',
    'Personal': 'category:personal',
    'Important': 'is:important',
    'Purchases': 'category:purchases',
    'Sent': 'in:sent',
    'Drafts': 'in:drafts',
    'Spam': 'in:spam',
    'Trash': 'in:trash',
  };

  final Map<String, _CachedMailbox> _cache = {};
  final Set<String> selected = {};
  Timer? _searchTimer;
  List<gmail.Message> messages = [];
  String filter = 'All mail';
  String search = '';
  String? nextPageToken;
  Object? error;
  bool loading = true;
  bool loadingMore = false;

  List<gmail.Message> get visibleMessages {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return messages;
    return messages.where((message) {
      final subject = header(message, 'subject').toLowerCase();
      final sender = header(message, 'from').toLowerCase();
      final snippet = (message.snippet ?? '').toLowerCase();
      return subject.contains(query) ||
          sender.contains(query) ||
          snippet.contains(query);
    }).toList();
  }

  String header(gmail.Message message, String name) =>
      (message.payload?.headers ?? const <gmail.MessagePartHeader>[])
          .firstWhere((item) => item.name?.toLowerCase() == name.toLowerCase(),
              orElse: () => gmail.MessagePartHeader())
          .value ??
      '';

  Future<void> load({bool force = false}) async {
    final key = filters[filter]!;
    final cached = _cache[key];
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.savedAt) <
            const Duration(minutes: 5)) {
      messages = List.of(cached.messages);
      nextPageToken = null;
      selected.clear();
      loading = false;
      error = null;
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    selected.clear();
    notifyListeners();
    try {
      final page = await listMailboxPage(query: key);
      messages = page.messages;
      nextPageToken = page.nextPageToken;
      _cache[key] = _CachedMailbox(List.of(messages), DateTime.now());
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loadingMore || nextPageToken == null) return;
    loadingMore = true;
    notifyListeners();
    try {
      final page = await listMailboxPage(
          query: filters[filter]!, pageToken: nextPageToken);
      messages = [...messages, ...page.messages];
      nextPageToken = page.nextPageToken;
      _cache[filters[filter]!] =
          _CachedMailbox(List.of(messages), DateTime.now());
    } catch (e) {
      error = e;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  void setFilter(String value) {
    if (filter == value) return;
    filter = value;
    load();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), notifyListeners);
  }

  void toggleSelected(String id, bool value) {
    value ? selected.add(id) : selected.remove(id);
    notifyListeners();
  }

  void selectAllVisible() {
    final ids = visibleMessages.map((m) => m.id).whereType<String>();
    if (ids.every(selected.contains)) {
      selected.removeAll(ids);
    } else {
      selected.addAll(ids);
    }
    notifyListeners();
  }

  void removeFromView(Iterable<String> ids) {
    messages.removeWhere((message) => ids.contains(message.id));
    selected.removeAll(ids);
    _cache.remove(filters[filter]!);
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
