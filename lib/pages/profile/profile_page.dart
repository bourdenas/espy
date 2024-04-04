import 'package:espy/modules/models/user_model.dart';
import 'package:espy/pages/profile/login_page.dart';
import 'package:espy/pages/profile/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return context.watch<UserModel>().isSignedIn
        ? const Settings()
        : const LoginPage();
  }
}
