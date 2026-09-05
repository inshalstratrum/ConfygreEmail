import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/email_string_model.dart';
import '../models/parse_unsubscribe_string_model.dart';
import '../models/skipped_emails_history_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:app_state/app_state.dart';
import 'package:googleapis/gmail/v1.dart' as gMail;
import '../models/email_data_model.dart';
import '../pages/login_page.dart';
import '../pages/tiles_page.dart';
import 'GlobalVariables.dart';
import 'gmail_auth.dart';
import 'dart:convert';

late gMail.GmailApi gmailApi;
List<gMail.Message> messagesList = [];
List<String> excludedEmails = [];

String buildExclusionQuery(List<String> excludedEmails) {
  try {
    // Create a query for excluded emails
    if (excludedEmails.isEmpty) {
      return ''; // No exclusion query if the list is empty
    }

    // Construct exclusion query
    String exclusionQuery =
        excludedEmails.map((email) => 'from:$email').join(' OR ');

    // Return the complete query to exclude the emails
    return 'NOT ($exclusionQuery)';
  } catch (e) {
    return '';
  }
}

Future<void> getEmails() async {
  try {
    print("getting emails");
    await Future.delayed(Duration.zero); // Ensures this runs asynchronously
    emailDataList.clear();
    messagesList.clear();

    // Get authenticated headers (from mobile sign in or desktop stored credentials)
    Map<String, String>? authHeaders;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        authHeaders = await googleSignIn.currentUser?.authHeaders;
      } catch (_) {}
    }
    if (authHeaders == null) {
      final cred = objectBox?.getUserCredential();
      if (cred != null && cred.accessToken.isNotEmpty) {
        authHeaders = {'Authorization': 'Bearer ${cred.accessToken}'};
      }
    }

    // Check if authHeaders is null
    if (authHeaders == null) {
      print("Failed to get auth headers. Make sure the user is signed in.");
      return;
    }

    skippedEmails = objectBox?.getSkippedEmailsList();

    // Pass the resolved headers to GoogleAuthClient
    final authenticateClient = GoogleAuthClient(authHeaders);
    gmailApi = gMail.GmailApi(authenticateClient);

    String? nextPageToken;
    int pageCount = 0;
    const int maxPages = 2; // Limit to 2 pages initially

    // Fetch messages
    do {
      String query = "";
      List<String> queryParts = [];

      // Category / folder filter
      if (selectedMailFilter == 'Promotions') {
        queryParts.add('category:promotions');
      } else if (selectedMailFilter == 'Updates') {
        queryParts.add('category:updates');
      } else if (selectedMailFilter == 'Social') {
        queryParts.add('category:social');
      } else if (selectedMailFilter == 'Important') {
        queryParts.add('is:important');
      } else if (selectedMailFilter == 'Purchases') {
        queryParts.add('category:purchases');
      } else if (selectedMailFilter == 'Sent') {
        queryParts.add('in:sent');
      } else if (selectedMailFilter == 'Drafts') {
        queryParts.add('in:draft');
      } else if (selectedMailFilter == 'Trash') {
        queryParts.add('in:trash');
      } else if (selectedMailFilter == 'Spam') {
        queryParts.add('in:spam');
      } else if (selectedMailFilter == 'Starred') {
        queryParts.add('is:starred');
      } else if (selectedMailFilter == '1-Click Only') {
        queryParts.add('unsubscribe in:inbox');
      } else {
        queryParts.add('in:inbox');
      }

      if (!showSkippedEmails) {
        if (excludedEmails.length > 0) excludedEmails.clear();
        if (skippedEmails != null) {
          excludedEmails.addAll(skippedEmails!.map((e) => e.email).toList());
          String exclusion = buildExclusionQuery(excludedEmails);
          if (exclusion.isNotEmpty) {
            queryParts.add(exclusion);
          }
        }
      }

      query = queryParts.join(' ');

      gMail.ListMessagesResponse results = await gmailApi.users.messages
          .list("me", pageToken: nextPageToken, q: query.isEmpty ? null : query, maxResults: 25);

      //Check if results.messages is not null before iterating
      if (results.messages != null) {
        for (gMail.Message message in results.messages!) {
          gMail.Message detailedMessage = await gmailApi.users.messages.get(
              "me", message.id!,
              $fields: "payload(headers),labelIds,threadId");
          messagesList.add(detailedMessage);

          // Extract headers for subject, sender, etc.
          var headers = detailedMessage.payload?.headers;

          EmailDataModel emailData = new EmailDataModel();
          EmailStringModel? emailStringModel = new EmailStringModel();

          emailData.emailId = message.id;

          // Parse headers
          if (headers != null) {
            for (var header in headers) {
              if (header.name == "From") {
                // Extract sender information
                var from = header.value ?? "";

                emailStringModel = processEmailString(from);

                emailData.senderEmail = emailStringModel?.email;
                emailData.senderName = emailStringModel?.name;
              } else if (header.name == "List-Unsubscribe-Post" &&
                  header.value == "List-Unsubscribe=One-Click") {
                emailData.isOneClickUnsub = true;
              } else if (header.name == "List-Unsubscribe") {
                //process string
                ParseUnsubscribeStringModel parseUnsubscribeStringResult =
                    parseUnsubscribeString(header.value ?? "");
                emailData.mailToString =
                    parseUnsubscribeStringResult.mailToString;
                emailData.mailToSubject =
                    parseUnsubscribeStringResult.mailToSubject;
                emailData.directString =
                    parseUnsubscribeStringResult.directString;
              } else if (header.name == "Subject") {
                emailData.subject = header.value ?? "";
              }
            }
          }

          print(
              "${emailDataList.containsKey(emailStringModel?.email)} (${emailData.isOneClickUnsub} || ${showOnlyUnsubscribableEmails})");
          if (!emailDataList.containsKey(emailStringModel?.email) &&
              (emailData.isOneClickUnsub || (!showOnlyUnsubscribableEmails && selectedMailFilter != '1-Click Only'))) {
            print("in");
            // Extract labels and flags
            emailData.isStared = false;
            emailData.isImportant = false;
            emailData.isLabeled = false;
            emailData.subject = "";

            // Get number of emails available
            emailData.count = 0;

            // Print the details
            print("Email ID: ${emailData.emailId}");
            // print("Sender Name: ${emailData.senderName}");
            // print("Sender Email: ${emailData.senderEmail}");
            // print("Subject: ${emailData.subject}");
            // print("Starred: ${emailData.isStared}");
            // print("Important: ${emailData.isImportant}");
            print("------------------------------------");

            emailDataList[emailStringModel?.email ?? ""] = emailData;
          }

          print("checking next one ${message.id}");
        }
        gettingEmails = false;
      } else {
        print("No messages found.");
      }

      // Update the nextPageToken for the next iteration
      nextPageToken = results.nextPageToken;
      pageCount++;
    } while (nextPageToken != null && await googleSignIn.isSignedIn() && pageCount < maxPages);

    if (!await googleSignIn.isSignedIn())
      print("signed out");
    else
      print("closed loop");
  } catch (e) {
    googleSignIn.signOut();
    objectBox?.removeUserCredential();
    gettingEmails = false;
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  final http.Client _client = new http.Client();

  GoogleAuthClient(this._headers);

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

Future<int> getEmailCount(String emailAddress) async {
  int count = 0;
  emailIdsToDelete.clear();

  // Use a fast estimated batch query with maxResults to avoid quota issues
  final response = await gmailApi.users.messages.list(
    "me",
    q: 'from:$emailAddress',
    maxResults: 100, // Fast batch query to estimate count
  );

  // Add the number of messages retrieved in the current response
  count += response.messages?.length ?? 0;

  emailIdsToDelete.addAll(
      response.messages?.map((message) => message.id!).toList() ?? []);

  return count;
}

Future<int> getUnreadEmailCount(String emailAddress) async {
  String? nextPageTokenForUnread;
  int count = 0;
  do {
    final response = await gmailApi.users.messages.list(
      'me',
      q: 'from:$emailAddress is:unread',
      pageToken: nextPageTokenForUnread,
    );
    count += response.messages?.length ?? 0;
    nextPageTokenForUnread = response.nextPageToken;
  } while (nextPageTokenForUnread != null);
  return count;
}

Future<List<String>> getBulkEmailList(String email) async {
  String? nextPageToken;
  List<String> emailIds = [];
  do {
    gMail.ListMessagesResponse response = await gmailApi.users.messages.list(
      "me",
      q: 'from:$email',
      pageToken: nextPageToken, // Use the token to get the next page
    );

    if (response.messages != null) {
      emailIds.addAll(response.messages!.map((message) => message.id!));
    }

    // Update the nextPageToken for the next iteration
    nextPageToken = response.nextPageToken;
  } while (nextPageToken != null); // Continue until there are no more pages

  return emailIds;
}

Future<List<gMail.Message>> listMailboxMessages({
  String query = '',
  int maxResults = 50,
}) async {
  final response = await gmailApi.users.messages.list(
    'me',
    q: query.isEmpty ? null : query,
    maxResults: maxResults,
  );
  final summaries = response.messages ?? <gMail.Message>[];
  final details = <gMail.Message>[];
  for (final summary in summaries) {
    if (summary.id == null) continue;
    details.add(
        await gmailApi.users.messages.get('me', summary.id!, format: 'full'));
  }
  return details;
}

Future<void> emptyTrash() async {
  String? pageToken;
  final ids = <String>[];
  do {
    final response = await gmailApi.users.messages.list(
      'me',
      q: 'in:trash',
      pageToken: pageToken,
    );
    ids.addAll(response.messages?.map((message) => message.id!).toList() ?? []);
    pageToken = response.nextPageToken;
  } while (pageToken != null);
  if (ids.isNotEmpty) {
    await gmailApi.users.messages.batchDelete(
      gMail.BatchDeleteMessagesRequest(ids: ids),
      'me',
    );
  }
}

Future<void> deleteSelectedMessages(List<String> ids) async {
  if (ids.isEmpty) return;
  if (permanentDelete) {
    await gmailApi.users.messages.batchDelete(
      gMail.BatchDeleteMessagesRequest(ids: ids),
      'me',
    );
  } else {
    await gmailApi.users.messages.batchModify(
      gMail.BatchModifyMessagesRequest(ids: ids, addLabelIds: ['TRASH']),
      'me',
    );
  }
}

ParseUnsubscribeStringModel parseUnsubscribeString(String input) {
  String? mailToString;
  String? mailSubject = "dummy subject"; // Default value for mailSubject
  String? directString;

  ParseUnsubscribeStringModel parseUnsubscribeStringModel =
      new ParseUnsubscribeStringModel();

  // Split the input by commas to get individual entries
  final parts = input.split(',');

  // Regex to detect mailto and URL
  final mailtoRegex =
      RegExp(r'mailto:([^>\?]+)'); // Extracts email before `?` or `>`
  final subjectRegex = RegExp(
      r'subject=([^>\&]+)'); // Extracts subject after `subject=` excluding trailing `>` or `&`
  final urlRegex = RegExp(r'https?://[^\s,>]+');

  for (var part in parts) {
    part = part.trim(); // Trim spaces

    // Check for mailto link
    final mailtoMatch = mailtoRegex.firstMatch(part);
    if (mailtoMatch != null) {
      parseUnsubscribeStringModel.mailToString = mailtoMatch.group(1);

      // Check for subject in the same part
      final subjectMatch = subjectRegex.firstMatch(part);
      if (subjectMatch != null) {
        parseUnsubscribeStringModel.mailToSubject = subjectMatch.group(1);
      }
    }

    // Check for URL
    final urlMatch = urlRegex.firstMatch(part);
    if (urlMatch != null) {
      parseUnsubscribeStringModel.directString = urlMatch.group(0);
    }
  }

  // print('MailTo String: $mailToString');
  // print('Mail Subject: $mailSubject');
  // print('Direct String: $directString');

  return parseUnsubscribeStringModel;
}

Future<void> deleteEmail(List<String> messageIds) async {
  //Permanently Delete
  // try{
  //   await gmailApi.users.messages.batchDelete(
  //     gMail.BatchDeleteMessagesRequest(ids: messageIds),
  //     'me',
  //   );
  // } catch(e) {
  //   print(e);
  // }

  try {
    await gmailApi.users.messages.batchModify(
      gMail.BatchModifyMessagesRequest(
        ids: messageIds, // List of message IDs
        addLabelIds: ['TRASH'], // Add the TRASH label to move emails to trash
      ),
      'me',
    );
    print('Messages moved to trash.');
  } catch (e) {
    print('Error moving messages to trash: $e');
  }
}

void blockEmail(String email) {}

Future<void> unSubEmail(
    String mailToString, String mailToSubject, String directString) async {
  String currentUserEmail = userEmail ??
      (!kIsWeb && (Platform.isAndroid || Platform.isIOS) ? googleSignIn.currentUser?.email : null) ??
      objectBox?.getUserCredential()?.userEmail ??
      '';
  String body = "This message was automatically generated by Confygre Email.";
  if (mailToString.length != 0 && currentUserEmail.length != 0) {
    if (mailToSubject.length != 0) {
      final rawMessage =
          createEmail(currentUserEmail, mailToString, mailToSubject, body);
      final message = gMail.Message()..raw = rawMessage;
      await gmailApi.users.messages.send(message, 'me');
    } else {
      final rawMessage =
          createEmail(currentUserEmail, mailToString, "unsubscribe", body);
      final message = gMail.Message()..raw = rawMessage;
      await gmailApi.users.messages.send(message, 'me');
    }
  } else if (directString.length != 0 && currentUserEmail.length != 0) {
    callWebPage(directString);
  }
}

String createEmail(
    String sender, String recipient, String subject, String body) {
  final message = StringBuffer();
  message.writeln('From: $sender');
  message.writeln('To: $recipient');
  message.writeln('Subject: $subject');
  message.writeln('');
  message.writeln(body);

  return base64UrlEncode(utf8.encode(message.toString()));
}

Future<void> callWebPage(String url) async {
  try {
    final response = await http.get(Uri.parse(url)); // Sends a GET request
    if (response.statusCode == 200) {
      print('Web page called successfully.');
    } else {
      print('Failed to call web page. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred while calling web page: $e');
  }
}


/// Fetches one Gmail page and only expands messages in that page. The caller owns
/// the cursor so screens can lazy-load more results without re-fetching page one.
Future<({List<gMail.Message> messages, String? nextPageToken})> listMailboxPage({
  String query = '',
  String? pageToken,
  int maxResults = 30,
}) async {
  final response = await gmailApi.users.messages.list(
    'me',
    q: query.isEmpty ? null : query,
    pageToken: pageToken,
    maxResults: maxResults,
  );
  final details = <gMail.Message>[];
  for (final summary in response.messages ?? <gMail.Message>[]) {
    if (summary.id == null) continue;
    details.add(await gmailApi.users.messages.get('me', summary.id!, format: 'full'));
  }
  return (messages: details, nextPageToken: response.nextPageToken);
}
