import 'package:Confygre_Email/models/oauth_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';

import '../models/user_credential_model.dart';
import 'GlobalVariables.dart';
import 'emails.dart';

UserCredentialModel _userCredentialModel = UserCredentialModel(
    userEmail: userEmail ?? '',
    accessToken: userAccessToken ?? '',
    idToken: userIdToken ?? '');

Future<bool> authGoogle() async {
  googleSignIn = signInGoole();

  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    return false;
  }
  final googleAuth = await googleUser!.authentication;
  final accessToken = googleAuth.accessToken;
  final idToken = googleAuth.idToken;

  if (accessToken == null) {
    throw 'No Access Token found.';
  }
  if (idToken == null) {
    // throw 'No ID Token found.';
  }

  _userCredentialModel.accessToken = accessToken.toString();
  _userCredentialModel.idToken = idToken.toString();
  _userCredentialModel.userEmail = googleUser.email;
  objectBox?.updateUserCredential(_userCredentialModel);

  print("auth completed");

  // return supabase.auth.signInWithIdToken(
  //   provider: OAuthProvider.google,
  //   idToken: idToken,
  //   accessToken: accessToken,
  // );

  return true;
}

GoogleSignIn signInGoole() {
  // const webClientId = '446415986013-4mg1uh7kptaodrt17rmv9mak0fv2n5hf.apps.googleusercontent.com'; //OG
  OauthModel? oauthModel = objectBox?.getOAuthData();
  final savedOverride =
      oauthModel?.useDefaultKey == false ? oauthModel?.oAuthKey.trim() : null;
  final webClientId =
      savedOverride?.isNotEmpty == true ? savedOverride! : defaultOAuthKeyValue;

  /// TODO: update the iOS client ID with your own.
  ///
  /// iOS Client ID that you registered with Google Cloud.
  // const iosClientId = '584283423841-fc09qt6577ark3k7lvql1o7bjvdlqaqj.apps.googleusercontent.com';
  const iosClientId = '';

  final GoogleSignIn googleSignIn =
      GoogleSignIn(serverClientId: webClientId, scopes: <String>[
    // GmailApi.gmailReadonlyScope,
    GmailApi.gmailComposeScope,
    GmailApi.gmailSendScope,
    GmailApi.gmailModifyScope,
    GmailApi.mailGoogleComScope
  ]);

  return googleSignIn;
}

void initSignIn() {
  try {
    // Ensure the user is signed in
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
