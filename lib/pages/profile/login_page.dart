import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SignInScreen(
      providerConfigs: _providerConfigs,
      actions: [],
    );
  }
}

const _providerConfigs = [
  // EmailProviderConfiguration(),
  GoogleProviderConfiguration(
    clientId:
        '478783154654-gq2jbr76gn0eggo0i71ak51bu9l3q7q5.apps.googleusercontent.com',
  ),
];
