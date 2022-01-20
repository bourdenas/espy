import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/pages/library_page.dart';
import 'package:espy/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class EspyMaterialApp extends StatefulWidget {
  @override
  State<EspyMaterialApp> createState() => _EspyMaterialAppState();
}

class _EspyMaterialAppState extends State<EspyMaterialApp> {
  bool signed = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'espy',
      debugShowCheckedModeBanner: false,
      theme: context.watch<AppConfigModel>().theme,
      initialRoute:
          context.watch<UserModel>().user != null ? '/sign-in' : '/home',
      routes: {
        '/home': (context) {
          return LibraryPage();
        },
        '/sign-in': (context) {
          return LoginPage();
        },
        '/profile': (context) {
          return ProfilePage();
        },
      },
    );
  }
}
