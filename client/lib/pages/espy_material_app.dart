import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/login_page.dart';
import 'package:espy/pages/top_level_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class EspyMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'espy',
      theme: context.watch<AppConfigModel>().theme,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print('authStateChanges = ${snapshot.connectionState}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            // TODO: Show a loading screen.
            return Scaffold();
          }

          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return TopLevelPage();
            } else {
              return LoginPage();
            }
          }
          return Scaffold();
        },
      ),
      routes: {
        '/profile': (context) {
          return ProfilePage();
        },
      },
    );
  }
}
