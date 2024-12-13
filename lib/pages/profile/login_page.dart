import 'dart:io';

import 'package:espy/modules/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<User?> _getUser(GoogleSignInAccount googleSignInAccount) async {
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user;
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;

    return Center(
      child: ElevatedButton(
          onPressed: isAndroid
              ? () async {
                  var googleSignInAccount =
                      await GoogleSignIn().signInSilently();
                  if (googleSignInAccount == null) {
                    try {
                      googleSignInAccount = await GoogleSignIn().signIn();
                    } catch (e) {
                      print('Failed to sign-in with error: $e');
                    }
                  }

                  if (googleSignInAccount == null) {
                    print('Failed googleSignInAccount');
                  }

                  final user = await _getUser(googleSignInAccount!);
                  if (user == null) {
                    print('Failed _getUser()');
                  }

                  //   // Obtain the auth details from the request
                  //   final GoogleSignInAuthentication? googleAuth =
                  //       await googleUser?.authentication;
                  //   print('skata #3');

                  //   // Create a new credential
                  //   final credential = GoogleAuthProvider.credential(
                  //     accessToken: googleAuth?.accessToken,
                  //     idToken: googleAuth?.idToken,
                  //   );
                  //   print('skata #4');

                  //   // Once signed in, return the UserCredential
                  //   await FirebaseAuth.instance.signInWithCredential(credential);
                  //   context.read<UserModel>().login();
                  //   context.goNamed('home');
                }
              : () async {
                  GoogleAuthProvider googleProvider = GoogleAuthProvider();
                  googleProvider
                      .setCustomParameters({'login_hint': 'user@example.com'});
                  await FirebaseAuth.instance.signInWithPopup(googleProvider);
                  context.read<UserModel>().login();
                  context.goNamed('home');

                  // Or use signInWithRedirect
                  // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
                },
          child: const Text('Sign in')),
    );
  }
}
