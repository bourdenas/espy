import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/pages/library_page.dart';
import 'package:espy/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class EspyMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'espy',
      theme: context.watch<AppConfigModel>().theme,
      home:
          context.watch<UserModel>().user == null ? LoginPage() : LibraryPage(),
      routes: {
        '/profile': (context) {
          return ProfilePage();
        },
      },
    );
  }
}
