import 'package:espy/modules/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthDialog extends StatefulWidget {
  static Future<void> show(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AuthDialog(),
    );
  }

  @override
  _AuthDialogState createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Sign In',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: context.read<UserModel>().signedIn
                        ? Text(
                            'Signed in as ${context.read<UserModel>().user.email}',
                            style: Theme.of(context).textTheme.headline5,
                          )
                        : ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            child: Image.asset(
                              'assets/images/google_signin.png',
                              // height: 64,
                            ),
                            onPressed: () async {
                              await context
                                  .read<UserModel>()
                                  .signInWithGoogle();
                              Navigator.of(context).pop();
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
