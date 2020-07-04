import 'dart:async';

import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../pages/login/email_login_form.dart';
import '../pages/login/user_info_form.dart';

enum AuthMethod {
  SIGN_IN,
  SIGN_UP,
}

class AuthResponse {
  AuthResponse({this.user, this.error});

  final FirebaseUser user;

  final dynamic error;
}

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _db = Firestore.instance;

  /// Firebase user one-time fetch
  Future<FirebaseUser> get getUser => _auth.currentUser();

  /// Firebase user a realtime stream
  Stream<FirebaseUser> get user => _auth.onAuthStateChanged;

  /// Check the database to see if the user has entered VALORANT info like their Riot ID and their "main", if not, we open a form for them to enter that data.
  ///
  /// Returns a future that will resolve when the user has entered their data and the database has been updated.
  /// The future will resolve instantly if the user has already entered data.
  Future<void> openUserDataEntryFormIfNoData(
    String uid,
    BuildContext context,
  ) async {
    final userData = await _db.collection("users").document(uid).get();

    if (!userData.exists) {
      // Push them to the user info entry form where they will update the DB with their info
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserInfoForm(),
        ),
      );
    }
  }

  /// Sign in with Google.
  Future<AuthResponse> googleSignIn(BuildContext context) async {
    try {
      final GoogleSignInAccount googleSignInAccount =
          await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      await openUserDataEntryFormIfNoData(user.uid, context);

      return AuthResponse(user: user);
    } on NoSuchMethodError {
      // If the Google popup was closed, don't return an error, return null.
      return null;
    } catch (error) {
      return AuthResponse(error: error);
    }
  }

  /// Determine if we can use Apple Sign In on this device.
  Future<bool> get appleSignInAvailable => AppleSignIn.isAvailable();

  Future<AuthResponse> appleSignIn(BuildContext context) async {
    try {
      final appleResult = await AppleSignIn.performRequests(
        [
          const AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName]),
        ],
      );

      if (appleResult.error != null) {
        print(appleResult.error);
      }

      final credential =
          const OAuthProvider(providerId: 'apple.com').getCredential(
        accessToken:
            String.fromCharCodes(appleResult.credential.authorizationCode),
        idToken: String.fromCharCodes(appleResult.credential.identityToken),
      );

      final firebaseResult = await _auth.signInWithCredential(credential);
      final user = firebaseResult.user;

      await openUserDataEntryFormIfNoData(user.uid, context);

      return AuthResponse(user: user);
    } catch (error) {
      print(error);
      return AuthResponse(error: error);
    }
  }

  Future<AuthResponse> emailSignIn(BuildContext context) async {
    try {
      final userMap = await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => EmailLoginForm()));

      if (userMap == null) {
        return null;
      } else {
        final email = userMap['email'];
        final password = userMap['password'];

        if (userMap['method'] == AuthMethod.SIGN_IN) {
          final AuthResult authResult = await _auth.signInWithEmailAndPassword(
              email: email, password: password);

          final user = authResult.user;

          return AuthResponse(user: user);
        } else {
          final AuthResult authResult = await _auth
              .createUserWithEmailAndPassword(email: email, password: password);

          final user = authResult.user;

          await openUserDataEntryFormIfNoData(user.uid, context);

          return AuthResponse(user: user);
        }
      }
    } catch (error) {
      print(error);
      return AuthResponse(error: error);
    }
  }

  /// Sign out
  Future<void> signOut() => _auth.signOut();
}
