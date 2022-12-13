import 'package:espy/pages/espy_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class EspyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EspyAppState();
}

class _EspyAppState extends State<EspyApp> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // print("Failed to connect to Firebase: ${snapshot.error}");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return EspyRouter();
        }

        return Text('loading...');
      },
    );
  }
}
