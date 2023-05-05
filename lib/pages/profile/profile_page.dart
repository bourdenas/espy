import 'package:espy/pages/profile/settings.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return Column(
    //   children: [
    //     ProfileScreen(
    //       providerConfigs: _providerConfigs,
    //       actions: [
    //         SignedOutAction((context) {
    //           Navigator.pushReplacementNamed(context, '/');
    //         }),
    //       ],
    //     ),
    //   ],
    // );
    return const Settings();
  }
}
