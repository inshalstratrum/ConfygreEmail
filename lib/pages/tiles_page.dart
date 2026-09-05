import 'package:flutter/material.dart';
import '../models/tiles_data_model.dart';
import '../models/email_data_model.dart';
import '../components/GlobalVariables.dart';
import '../components/emails.dart';
import '../components/gmail_auth.dart';
import '../models/email_string_model.dart';
import 'login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'mail_list_page.dart';

class Tiles extends StatefulWidget {
  const Tiles({super.key});

  @override
  State<Tiles> createState() => _TilesState();
}

EmailStringModel? processEmailString(String input) {
  try {
    EmailStringModel emailStringModel = EmailStringModel();
    if (input.contains('<') && input.contains('>')) {
      final name = input.substring(0, input.indexOf('<')).trim();
      final email = input.substring(input.indexOf('<') + 1, input.indexOf('>')).trim();
      emailStringModel.name = name;
      emailStringModel.email = email;
      return emailStringModel;
    } else {
      final name = input.substring(0, input.indexOf('@')).trim();
      final email = input.substring(input.indexOf('@') + 1, input.length).trim();
      emailStringModel.name = name;
      emailStringModel.email = email;
      return emailStringModel;
    }
  } catch (e) {
    return null;
  }
}

class _TilesState extends State<Tiles> {
  // Undo history stack for skipped senders
  final List<EmailDataModel> _skippedHistory = [];

  final List<Map<String, dynamic>> _filterOptions = const [
    {'name': 'Inbox', 'label': 'All Inbox', 'icon': Icons.inbox_rounded},
    {'name': '1-Click Only', 'label': '⚡ 1-Click Unsub', 'icon': Icons.flash_on_rounded},
    {'name': 'Promotions', 'label': 'Promotions', 'icon': Icons.local_offer_outlined},
    {'name': 'Updates', 'label': 'Updates', 'icon': Icons.notifications_none_rounded},
    {'name': 'Personal', 'label': 'Personal', 'icon': Icons.person_outline_rounded},
    {'name': 'Social', 'label': 'Social', 'icon': Icons.people_outline_rounded},
    {'name': 'Important', 'label': 'Important', 'icon': Icons.label_important_outline_rounded},
    {'name': 'Purchases', 'label': 'Purchases', 'icon': Icons.shopping_bag_outlined},
    {'name': 'Starred', 'label': 'Starred', 'icon': Icons.star_border_rounded},
    {'name': 'Trash', 'label': 'Trash', 'icon': Icons.delete_outline_rounded},
    {'name': 'Spam', 'label': 'Spam', 'icon': Icons.block_flipped},
  ];

  @override
  void initState() {
    super.initState();
    checkNewVersion();
    setState(() {
      TilesDataModel? tilesData = objectBox?.getTilesData(dateTimeInUTC);
      if (tilesData != null) {
        unsubscribedToday = tilesData.unsubscribed;
        deletedToday = tilesData.deleted;
        skippedToday = tilesData.skipped;
      }
    });
    showEmailDataOrWait();
  }

  void checkNewVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      // String currentVersion = packageInfo.version;
    } catch (_) {}
  }

  void chekPlaystoreDialog() {
    bool toShow = objectBox?.getPlaystoreRatingModel() ?? false;
    if (toShow) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Is it easy to clear emails? 😉'),
          content: const Text('Would you give us a rating on Google Play Store?'),
          actions: [
            TextButton(
              onPressed: () {
                objectBox?.updatePlaystoreRatingModel(true);
                Navigator.pop(context);
              },
              child: const Text('Will never do', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                objectBox?.updatePlaystoreRatingModel(false);
                Navigator.pop(context);
              },
              child: const Text('Maybe later', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  objectBox?.updatePlaystoreRatingModel(true);
                  String url = "https://google.com/";
                  Uri uri = Uri.parse(url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (ex) {
                  print(ex);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900]),
              child: const Text('Sure, let\'s go!', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> showEmailDataOrWait() async {
    if (emailDataList.isNotEmpty) {
      final firstEntry = emailDataList.entries.first.value;
      final sender = firstEntry.senderEmail ?? "";
      int emailCount = 1;
      if (sender.isNotEmpty) {
        try {
          emailCount = await getEmailCount(sender);
        } catch (_) {
          emailCount = 1;
        }
      }

      if (mounted) {
        setState(() {
          emailId = firstEntry.emailId ?? "";
          emailSubject = firstEntry.subject ?? "";
          emailSenderName = firstEntry.senderName ?? "Unknown Sender";
          emailSenderEmail = sender;
          isEmailStared = firstEntry.isStared;
          isEmailImportant = firstEntry.isImportant;
          numberOfEmailsAvailable = emailCount;
          isOneClickUnsub = firstEntry.isOneClickUnsub;
          mailToString = firstEntry.mailToString ?? "";
          mailToSubject = firstEntry.mailToSubject ?? "";
          directString = firstEntry.directString ?? "";
        });
      }
    } else {
      if (!gettingEmails) {
        setState(() {
          gettingEmails = true;
        });
        try {
          await getEmails();
          if (emailDataList.isNotEmpty && mounted) {
            await showEmailDataOrWait();
          }
        } catch (e) {
          try {
            googleSignIn.signOut();
            objectBox?.removeUserCredential();
            gettingEmails = false;
            if (mounted) {
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
              });
            }
          } catch (ex) {
            print(ex);
          }
        } finally {
          if (mounted) {
            setState(() {
              gettingEmails = false;
            });
          }
        }
      }
    }
  }

  void unsubscribeEmail(String email, int count, String emailId) {
    if (email.isNotEmpty) {
      objectBox?.addUnsubscribedEmail(email, count, emailId);
      emailDataList.remove(email);

      unSubEmail(mailToString, mailToSubject, directString);

      if (blockTheSender) {
        blockEmail(email);
      }

      deleteEmail(emailIdsToDelete);

      setState(() {
        unsubscribedToday += 1;
        deletedToday += count;
        objectBox?.updateTilesData(unsubscribedToday, skippedToday, deletedToday);
      });

      showEmailDataOrWait();

      setState(() {
        canGetNextRequest = true;
      });
    }
  }

  Future<void> unsubscribeOnly(String email) async {
    if (email.isEmpty) return;
    setState(() => canGetNextRequest = false);
    await unSubEmail(mailToString, mailToSubject, directString);
    objectBox?.addUnsubscribedEmail(email, numberOfEmailsAvailable, emailId);
    emailDataList.remove(email);
    setState(() {
      unsubscribedToday += 1;
      objectBox?.updateTilesData(unsubscribedToday, skippedToday, deletedToday);
      canGetNextRequest = true;
    });
    showEmailDataOrWait();
  }

  void skipEmail(String email, String emailId) async {
    if (email.isNotEmpty) {
      final currentModel = emailDataList[email] ??
          (emailDataList.isNotEmpty ? emailDataList.entries.first.value : null);
      if (currentModel != null) {
        _skippedHistory.add(currentModel);
      }

      List<String> bulkEmailList = await getBulkEmailList(email);
      objectBox?.addSkippedEmail(email, bulkEmailList);
      emailDataList.remove(email);

      setState(() {
        skippedToday += 1;
        objectBox?.updateTilesData(unsubscribedToday, skippedToday, deletedToday);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Skipped "${currentModel?.senderName ?? email}"',
              overflow: TextOverflow.ellipsis,
            ),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFF38BDF8),
              onPressed: _undoSkip,
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      showEmailDataOrWait();

      setState(() {
        canGetNextRequest = true;
      });
    }
  }

  Future<void> _undoSkip() async {
    if (_skippedHistory.isEmpty || !canGetNextRequest) return;

    setState(() {
      canGetNextRequest = false;
    });

    final lastSkipped = _skippedHistory.removeLast();
    final email = lastSkipped.senderEmail;
    if (email != null && email.isNotEmpty) {
      await objectBox?.removeSkippedEmail(email);
      if (skippedToday > 0) {
        skippedToday -= 1;
        objectBox?.updateTilesData(unsubscribedToday, skippedToday, deletedToday);
      }
      // Re-insert at the start of emailDataList so user immediately reviews it
      final newMap = <String, EmailDataModel>{email: lastSkipped};
      newMap.addAll(emailDataList);
      emailDataList = newMap;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.restore_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Restored "${lastSkipped.senderName ?? email}" to review queue',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    await showEmailDataOrWait();

    if (mounted) {
      setState(() {
        canGetNextRequest = true;
      });
    }
  }

  void deleteEmails(String email, int count) {
    if (email.isNotEmpty) {
      emailDataList.remove(email);
      deleteEmail(emailIdsToDelete);

      setState(() {
        deletedToday += count;
        objectBox?.updateTilesData(unsubscribedToday, skippedToday, deletedToday);
      });

      showEmailDataOrWait();

      setState(() {
        canGetNextRequest = true;
      });
    }
  }

  void _onSelectFilter(String filterName) {
    if (filterName == selectedMailFilter) return;
    setState(() {
      selectedMailFilter = filterName;
      emailDataList.clear();
      gettingEmails = false;
    });
    showEmailDataOrWait();
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color1,
    Color color2,
    IconData icon, {
    VoidCallback? onTap,
    String? badgeText,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color1.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  Icon(icon, size: 14, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),

            // Smart Filter Chips Row
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _filterOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filterOptions[index];
                  final isSelected = selectedMailFilter == filter['name'];
                  return ChoiceChip(
                    selected: isSelected,
                    showCheckmark: false,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'] as IconData,
                          size: 15,
                          color: isSelected ? Colors.white : Colors.blueGrey[700],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          filter['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.blueGrey[900],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: Colors.white,
                    elevation: isSelected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (_) => _onSelectFilter(filter['name'] as String),
                  );
                },
              ),
            ),

            // Sub-bar with Queue Count, Undo button, and Refresh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 14,
                    color: Colors.blueGrey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    emailDataList.isNotEmpty
                        ? 'Showing 1 of ${emailDataList.length} loaded'
                        : (gettingEmails ? 'Scanning mailbox...' : 'Queue empty'),
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_skippedHistory.isNotEmpty)
                    InkWell(
                      onTap: canGetNextRequest ? _undoSkip : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.undo_rounded, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              'Undo Skip (${_skippedHistory.length})',
                              style: const TextStyle(
                                color: Color(0xFF0284C7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh Mailbox',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.blueGrey[800],
                    onPressed: () {
                      if (!gettingEmails) {
                        setState(() {
                          emailDataList.clear();
                          gettingEmails = false;
                        });
                        showEmailDataOrWait();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Today's Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _buildStatCard(
                    'Unsubscribed',
                    unsubscribedToday.toString(),
                    const Color(0xFF4C1D95),
                    const Color(0xFF6D28D9),
                    Icons.mark_email_read_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    'Deleted',
                    deletedToday.toString(),
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                    Icons.delete_sweep_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    'Skipped',
                    skippedToday.toString(),
                    const Color(0xFF0F766E),
                    const Color(0xFF14B8A6),
                    Icons.skip_next_outlined,
                    onTap: _skippedHistory.isNotEmpty ? _undoSkip : null,
                    badgeText: _skippedHistory.isNotEmpty ? 'Undo ${_skippedHistory.length}' : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Main Tile / Review Card Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: _buildMainContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    // 1. Loading State
    if (gettingEmails && emailDataList.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                  strokeWidth: 3.5,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scanning your mailbox...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Finding senders in "$selectedMailFilter"',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Empty / All Clean State
    if (!gettingEmails && emailDataList.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 48,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'All Clean! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No pending senders in "$selectedMailFilter". Your mailbox is tidy!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey[600],
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        emailDataList.clear();
                        gettingEmails = false;
                      });
                      showEmailDataOrWait();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Scan Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (_skippedHistory.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: canGetNextRequest ? _undoSkip : null,
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: Text('Undo Skip (${_skippedHistory.length})'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 3. Sender Review Card
    final initial = emailSenderName.trim().isNotEmpty
        ? emailSenderName.trim()[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Sender Name & Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Sender info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emailSenderName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      emailSenderEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Undo quick button if available
              if (_skippedHistory.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.undo_rounded, color: Color(0xFF38BDF8), size: 22),
                  tooltip: 'Undo last skip (${_skippedHistory.length})',
                  onPressed: canGetNextRequest ? _undoSkip : null,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Badges: 1-Click Unsub, Important, Starred
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (isOneClickUnsub)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.18),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, color: Color(0xFF34D399), size: 14),
                      SizedBox(width: 4),
                      Text(
                        '1-Click Unsubscribe',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isEmailImportant)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.18),
                    border: Border.all(color: Colors.amber.withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_important_rounded, color: Colors.amberAccent, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Important',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isEmailStared)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.18),
                    border: Border.all(color: Colors.orange.withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Starred',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Tappable Email Count Banner
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MailListPage(sender: emailSenderEmail),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$numberOfEmailsAvailable email(s) from this sender',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap to inspect message history ›',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white38,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // Subject snippet if available
          if (emailSubject.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.subject_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      emailSubject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Action Buttons
          // 1. Primary Action: Unsubscribe & Delete All (or Delete All)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canGetNextRequest
                  ? () {
                      if (isOneClickUnsub) {
                        setState(() => canGetNextRequest = false);
                        unsubscribeEmail(emailSenderEmail, numberOfEmailsAvailable, emailId);
                      } else {
                        setState(() => canGetNextRequest = false);
                        deleteEmails(emailSenderEmail, numberOfEmailsAvailable);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_sweep_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isOneClickUnsub ? 'Unsubscribe & Delete All' : 'Delete All Emails',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 2. Secondary 1-Click Unsubscribe Only (Keep Emails)
          if (isOneClickUnsub) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: canGetNextRequest ? () => unsubscribeOnly(emailSenderEmail) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_email_read_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Unsubscribe Only (Keep Emails)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // 3. Bottom Row: Delete Only, Skip, Undo
          Row(
            children: [
              // Delete Only
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: canGetNextRequest
                        ? () {
                            setState(() => canGetNextRequest = false);
                            deleteEmails(emailSenderEmail, numberOfEmailsAvailable);
                          }
                        : null,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                      color: Color(0xFFF97316),
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Skip
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: canGetNextRequest
                        ? () {
                            setState(() => canGetNextRequest = false);
                            skipEmail(emailSenderEmail, emailId);
                          }
                        : null,
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: const Text(
                      'Skip',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              // Undo Button
              if (_skippedHistory.isNotEmpty) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  width: 48,
                  child: OutlinedButton(
                    onPressed: canGetNextRequest ? _undoSkip : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(
                      Icons.undo_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
