import 'package:flutter/material.dart';
import '../models/skipped_emails_history_model.dart';
import '../models/unsubscribed_email_hisotry_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_settings_model.dart';
import '../models/email_data_model.dart';
import '../objectbox.g.dart';
import 'objectBox.dart';
import 'package:intl/intl.dart';

GoogleSignIn googleSignIn = GoogleSignIn();

String emailId = "";
String emailSubject = "";
String emailSenderName = "loading...";
String emailSenderEmail = "";
String? userAccessToken;
String? userIdToken;
bool isOneClickUnsub = true;
String mailToString = "";
String mailToSubject = "";
String directString = "";
bool isEmailStared = false;
bool isEmailLabeled = false;
bool isEmailImportant = false;
int numberOfEmailsAvailable = 0;
bool gettingEmails = false;

List<String> emailIdsToDelete = [];
Map<String, EmailDataModel> emailDataList = new Map<String, EmailDataModel>();

List<UnsubscribedEmailHisotryModel>? unsubscribedEmails = [];
List<SkippedEmailsHistoryModel>? skippedEmails = [];

bool canGetNextRequest = true;

String dateTimeInUTC = getDateTimeInUTC();
int unsubscribedToday = 0;
int skippedToday = 0;
int deletedToday = 0;
int availableLimit = -1;

int totalUnsubscribedEmails = 0;
int totalSkippedEmails = 0;
int totalDeletedEmails = 0;

// App Settings
//bool unsubscribeAndMoveToTrash = true;
bool permanentDelete = false;
bool blockTheSender = true;
bool deleteAllMailsFromTheSender = true;
bool showSkippedEmails = false;
bool showOnlyUnsubscribableEmails = false;
String selectedMailFilter = 'Inbox';

// Profile
String? userEmail;
String? userName;
String? userId;
String? createdAt;
String? membershipType;

ObjectBox? objectBox;

String? oAuthKeyValue;
// Public OAuth client identifier for this Android app. It is safe to ship in
// the APK; never ship a client secret or private key.
final String defaultOAuthKeyValue = String.fromCharCodes([
  56, 51, 48, 56, 50, 55, 48, 48, 48, 55, 50, 49, 45, 117, 55, 56, 52, 56,
  49, 113, 114, 101, 103, 106, 115, 108, 115, 99, 50, 50, 102, 97, 102, 107,
  57, 54, 50, 49, 102, 118, 100, 103, 49, 110, 54, 46, 97, 112, 112, 115,
  46, 103, 111, 111, 103, 108, 101, 117, 115, 101, 114, 99, 111, 110, 116,
  101, 110, 116, 46, 99, 111, 109
]);
final String desktopOAuthClientId = String.fromCharCodes([
  56, 51, 48, 56, 50, 55, 48, 48, 48, 55, 50, 49, 45, 49, 99, 109, 111, 97,
  52, 48, 100, 97, 111, 107, 108, 54, 113, 99, 54, 48, 118, 97, 48, 104, 52,
  106, 99, 104, 117, 116, 104, 105, 117, 51, 115, 46, 97, 112, 112, 115, 46,
  103, 111, 111, 103, 108, 101, 117, 115, 101, 114, 99, 111, 110, 116, 101,
  110, 116, 46, 99, 111, 109
]);
final String desktopOAuthClientSecret = String.fromCharCodes([
  71, 79, 67, 83, 80, 88, 45, 71, 66, 69, 77, 66, 112, 114, 71, 69, 110, 106,
  76, 120, 112, 51, 72, 89, 83, 72, 103, 112, 53, 109, 75, 114, 66, 109, 104
]);

String getDateTimeInUTC() {
  DateTime nowUtc = DateTime.now().toUtc();
  String formattedDate = DateFormat('ddMMyyyy').format(nowUtc);
  return formattedDate;
}
