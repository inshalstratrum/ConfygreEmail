import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:Confygre_Email/models/oauth_model.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'GlobalVariables.dart';
import 'secure_auth_store.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

Future<bool> authGoogle() async {
  if (_isDesktop) {
    return authGoogleDesktop();
  }

  googleSignIn = signInGoogle();
  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) return false;

  final googleAuth = await googleUser.authentication;
  final accessToken = googleAuth.accessToken;
  if (accessToken == null || accessToken.isEmpty) {
    throw StateError('Google did not return an access token.');
  }

  await SecureAuthStore.saveSession(
    accessToken: accessToken,
    idToken: googleAuth.idToken ?? '',
    email: googleUser.email,
  );

  // Remove credentials written by older builds from the ordinary ObjectBox DB.
  objectBox?.removeUserCredential();

  userEmail = googleUser.email;
  userName = googleUser.displayName;
  return true;
}

/// Desktop OAuth 2.0 Authorization Code flow with PKCE and a loopback redirect.
///
/// Installed applications cannot keep a client secret confidential, so this
/// flow intentionally uses a public client ID + PKCE and never embeds a secret.
Future<bool> authGoogleDesktop() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final redirectUri = 'http://127.0.0.1:${server.port}';

  final verifier = _newCodeVerifier();
  final challenge = _base64UrlNoPadding(
    sha256.convert(ascii.encode(verifier)).bytes,
  );

  final scopes = <String>[
    GmailApi.gmailModifyScope,
    GmailApi.gmailSendScope,
    'openid',
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
    'include_granted_scopes': 'true',
    'code_challenge': challenge,
    'code_challenge_method': 'S256',
  });

  final launched =
      await launchUrl(authUri, mode: LaunchMode.externalApplication);
  if (!launched) {
    await server.close(force: true);
    throw StateError('Could not open the system browser for Google sign-in.');
  }

  String? authCode;
  try {
    await for (final request in server.timeout(const Duration(minutes: 3))) {
      final code = request.uri.queryParameters['code'];
      final error = request.uri.queryParameters['error'];
      request.response.headers.contentType = ContentType.html;

      if (code != null) {
        authCode = code;
        request.response.write(
          '<!doctype html><meta charset="utf-8"><title>Confygre Email</title>'
          '<body style="font-family:sans-serif;text-align:center;padding:60px">'
          '<h2>Sign-in successful</h2><p>You can close this tab and return to Confygre Email.</p></body>',
        );
      } else {
        request.response.write(
          '<!doctype html><meta charset="utf-8"><title>Confygre Email</title>'
          '<body style="font-family:sans-serif;text-align:center;padding:60px">'
          '<h2>Sign-in did not complete</h2><p>${error ?? 'Canceled'}</p></body>',
        );
      }
      await request.response.close();
      break;
    }
  } finally {
    await server.close(force: true);
  }

  if (authCode == null) return false;

  final tokenResponse = await http.post(
    Uri.parse('https://oauth2.googleapis.com/token'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'code': authCode,
      'client_id': desktopOAuthClientId,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
      'code_verifier': verifier,
    },
  );

  if (tokenResponse.statusCode != 200) {
    throw StateError('Google token exchange failed.');
  }

  final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
  final accessToken = tokenData['access_token'] as String? ?? '';
  final idToken = tokenData['id_token'] as String? ?? '';
  final refreshToken = tokenData['refresh_token'] as String? ?? '';
  final expiresIn = (tokenData['expires_in'] as num?)?.toInt();

  if (accessToken.isEmpty) {
    throw StateError('Google OAuth response did not contain an access token.');
  }

  String email = '';
  String? displayName;
  final userinfoResponse = await http.get(
    Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  if (userinfoResponse.statusCode == 200) {
    final info = jsonDecode(userinfoResponse.body) as Map<String, dynamic>;
    email = info['email'] as String? ?? '';
    displayName = info['name'] as String?;
  }

  await SecureAuthStore.saveSession(
    accessToken: accessToken,
    idToken: idToken,
    refreshToken: refreshToken,
    email: email,
    expiresAt: expiresIn == null
        ? null
        : DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
  );

  objectBox?.removeUserCredential();
  userEmail = email;
  userName = displayName;
  return true;
}

Future<Map<String, String>?> getAuthenticatedHeaders() async {
  if (!_isDesktop) {
    googleSignIn = signInGoogle();
    final account =
        googleSignIn.currentUser ?? await googleSignIn.signInSilently();
    if (account == null) return null;

    userEmail = account.email;
    userName = account.displayName;
    return account.authHeaders;
  }

  final session = await SecureAuthStore.readSession();
  if (session == null) return null;

  userEmail = session.email.isEmpty ? userEmail : session.email;

  if (session.accessToken.isNotEmpty && !session.isExpiringSoon) {
    return {'Authorization': 'Bearer ${session.accessToken}'};
  }

  if (session.refreshToken.isEmpty) return null;

  final response = await http.post(
    Uri.parse('https://oauth2.googleapis.com/token'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'client_id': desktopOAuthClientId,
      'refresh_token': session.refreshToken,
      'grant_type': 'refresh_token',
    },
  );

  if (response.statusCode != 200) {
    await SecureAuthStore.clear();
    return null;
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final accessToken = data['access_token'] as String? ?? '';
  final expiresIn = (data['expires_in'] as num?)?.toInt();
  if (accessToken.isEmpty) return null;

  await SecureAuthStore.saveSession(
    accessToken: accessToken,
    idToken: session.idToken,
    refreshToken: session.refreshToken,
    email: session.email,
    expiresAt: expiresIn == null
        ? null
        : DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
  );

  return {'Authorization': 'Bearer $accessToken'};
}

Future<bool> hasStoredAuthSession() async {
  if (!_isDesktop) {
    try {
      googleSignIn = signInGoogle();
      final account =
          googleSignIn.currentUser ?? await googleSignIn.signInSilently();
      if (account != null) {
        userEmail = account.email;
        userName = account.displayName;
        return true;
      }
    } catch (_) {
      // Fall through to the secure-store check.
    }
  }

  final session = await SecureAuthStore.readSession();
  if (session == null) return false;
  if (session.email.isNotEmpty) userEmail = session.email;
  return session.accessToken.isNotEmpty || session.refreshToken.isNotEmpty;
}

Future<String> currentAuthenticatedEmail() async {
  if ((userEmail ?? '').isNotEmpty) return userEmail!;

  if (!_isDesktop) {
    final account =
        googleSignIn.currentUser ?? await googleSignIn.signInSilently();
    if (account != null) {
      userEmail = account.email;
      return account.email;
    }
  }

  final session = await SecureAuthStore.readSession();
  if (session != null && session.email.isNotEmpty) {
    userEmail = session.email;
    return session.email;
  }
  return '';
}

Future<void> signOutSecurely() async {
  await SecureAuthStore.clear();
  objectBox?.removeUserCredential();

  if (!_isDesktop) {
    try {
      await googleSignIn.signOut();
    } catch (_) {}
  }

  userEmail = null;
  userName = null;
}

GoogleSignIn signInGoogle() {
  final OauthModel? oauthModel = objectBox?.getOAuthData();
  final savedOverride =
      oauthModel?.useDefaultKey == false ? oauthModel?.oAuthKey.trim() : null;
  final webClientId =
      savedOverride?.isNotEmpty == true ? savedOverride! : defaultOAuthKeyValue;

  return GoogleSignIn(
    serverClientId: webClientId,
    scopes: <String>[
      GmailApi.gmailModifyScope,
      GmailApi.gmailSendScope,
    ],
  );
}

// Kept for older callers while correcting the historical misspelling.
GoogleSignIn signInGoole() => signInGoogle();

void initSignIn() {
  if (_isDesktop) return;
  googleSignIn = signInGoogle();
  googleSignIn.signInSilently();
}

String _newCodeVerifier() {
  final random = Random.secure();
  final bytes = List<int>.generate(64, (_) => random.nextInt(256));
  return _base64UrlNoPadding(bytes);
}

String _base64UrlNoPadding(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');
