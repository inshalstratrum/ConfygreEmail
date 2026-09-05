import 'dart:convert';
import 'dart:io';
import 'package:Confygre_Email/models/oauth_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/user_credential_model.dart';
import 'GlobalVariables.dart';
import 'emails.dart';

UserCredentialModel _userCredentialModel = UserCredentialModel(
    userEmail: userEmail ?? '',
    accessToken: userAccessToken ?? '',
    idToken: userIdToken ?? '');

Future<bool> authGoogle() async {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    return await authGoogleDesktop();
  }

  // Mobile flow (Android / iOS)
  googleSignIn = signInGoole();

  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    return false;
  }
  final googleAuth = await googleUser.authentication;
  final accessToken = googleAuth.accessToken;
  final idToken = googleAuth.idToken;

  if (accessToken == null) {
    throw 'No Access Token found.';
  }

  _userCredentialModel.accessToken = accessToken.toString();
  _userCredentialModel.idToken = idToken.toString();
  _userCredentialModel.userEmail = googleUser.email;
  objectBox?.updateUserCredential(_userCredentialModel);

  userAccessToken = accessToken;
  userIdToken = idToken;
  userEmail = googleUser.email;

  print("auth completed");
  return true;
}

/// Loopback desktop OAuth 2.0 flow for Windows/macOS/Linux
Future<bool> authGoogleDesktop() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  final redirectUri = 'http://127.0.0.1:$port';

  final scopes = [
    'https://mail.google.com/',
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/gmail.compose',
    'https://www.googleapis.com/auth/gmail.send',
    'email',
    'profile',
  ].join(' ');

  final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
    'client_id': desktopOAuthClientId,
    'redirect_uri': redirectUri,
    'response_type': 'code',
    'scope': scopes,
    'access_type': 'offline',
    'prompt': 'consent',
  });

  final launched = await launchUrl(authUri, mode: LaunchMode.externalApplication);
  if (!launched) {
    await server.close(force: true);
    throw 'Could not open system browser for Google sign in.';
  }

  String? authCode;
  try {
    await for (final request in server.timeout(const Duration(minutes: 3))) {
      final code = request.uri.queryParameters['code'];
      final error = request.uri.queryParameters['error'];

      request.response.headers.contentType = ContentType.html;
      if (code != null) {
        authCode = code;
        request.response.write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Confygre Email - Signed in</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; text-align: center; padding: 60px 20px; background: #F6F8FB;">
  <div style="max-width: 420px; margin: 0 auto; background: white; padding: 36px; border-radius: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.06);">
    <div style="font-size: 52px; margin-bottom: 12px;">🎉</div>
    <h2 style="color: #0F172A; margin: 0 0 12px 0;">Sign-in Successful!</h2>
    <p style="color: #475569; font-size: 15px; margin: 0 0 20px 0; line-height: 1.5;">You are now signed in to <strong>Confygre Email</strong>.</p>
    <p style="color: #94A3B8; font-size: 13px; margin: 0;">You can close this browser tab and return to the desktop app.</p>
  </div>
</body>
</html>
''');
        await request.response.close();
        break;
      } else {
        request.response.write('''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Sign-in Failed</title></head>
<body style="font-family: sans-serif; text-align: center; padding: 60px;">
  <h2>Sign-in did not complete (${error ?? 'canceled'})</h2>
  <p>Please return to Confygre Email and try again.</p>
</body>
</html>
''');
        await request.response.close();
        break;
      }
    }
  } finally {
    await server.close(force: true);
  }

  if (authCode == null) {
    return false;
  }

  final tokenResponse = await http.post(
    Uri.parse('https://oauth2.googleapis.com/token'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'code': authCode,
      'client_id': desktopOAuthClientId,
      'client_secret': desktopOAuthClientSecret,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
    },
  );

  if (tokenResponse.statusCode != 200) {
    throw 'Failed to exchange authorization code: ${tokenResponse.body}';
  }

  final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
  final accessToken = tokenData['access_token'] as String?;
  final idToken = tokenData['id_token'] as String? ?? '';

  if (accessToken == null || accessToken.isEmpty) {
    throw 'Google OAuth response did not contain an access token.';
  }

  String userEmailAddress = '';
  try {
    final userinfoResp = await http.get(
      Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (userinfoResp.statusCode == 200) {
      final info = jsonDecode(userinfoResp.body);
      userEmailAddress = info['email'] ?? '';
      userName = info['name'] ?? '';
    }
  } catch (_) {}

  _userCredentialModel.accessToken = accessToken;
  _userCredentialModel.idToken = idToken;
  _userCredentialModel.userEmail = userEmailAddress;
  objectBox?.updateUserCredential(_userCredentialModel);

  userAccessToken = accessToken;
  userIdToken = idToken;
  userEmail = userEmailAddress;

  final authClient = GoogleAuthClient({'Authorization': 'Bearer $accessToken'});
  gmailApi = GmailApi(authClient);

  return true;
}

GoogleSignIn signInGoole() {
  OauthModel? oauthModel = objectBox?.getOAuthData();
  final savedOverride =
      oauthModel?.useDefaultKey == false ? oauthModel?.oAuthKey.trim() : null;
  final webClientId =
      savedOverride?.isNotEmpty == true ? savedOverride! : defaultOAuthKeyValue;

  const iosClientId = '';

  final GoogleSignIn googleSignIn =
      GoogleSignIn(serverClientId: webClientId, scopes: <String>[
    GmailApi.gmailComposeScope,
    GmailApi.gmailSendScope,
    GmailApi.gmailModifyScope,
    GmailApi.mailGoogleComScope
  ]);

  return googleSignIn;
}

void initSignIn() {
  try {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }
    if (googleSignIn.currentUser == null) {
      googleSignIn.signIn();
      print("--------- SIGNED IN ----------");
      print(googleSignIn.currentUser?.id);
    } else {
      print("already signed in");
    }
  } catch (e) {
    print(e);
  }
}
