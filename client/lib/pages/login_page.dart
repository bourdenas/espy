import 'package:espy/modules/models/user_data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providerConfigs: _providerConfigs,
      actions: [],
    );
  }
}

class ProfilePage extends StatelessWidget {
  ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ProfileScreen(
        //   providerConfigs: _providerConfigs,
        //   actions: [
        //     SignedOutAction((context) {
        //       Navigator.pushReplacementNamed(context, '/');
        //     }),
        //   ],
        // ),
        editBoxes(context),
        buttons(context),
      ],
    );
  }

  Widget buttons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text("Sync"),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await context.read<UserDataModel>().setUserKeys(
                    steamUserId: _steamTextController.text,
                    gogAuthCode: _gogTextController.text,
                  );
              await context.read<UserDataModel>().syncLibrary();
            }
          },
        ),
        SizedBox(width: 24),
        TextButton(
          child: Text("Cancel"),
          onPressed: () => context.goNamed('home'),
        ),
      ],
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _steamTextController = TextEditingController();
  final _gogTextController = TextEditingController();

  Widget editBoxes(BuildContext context) {
    final user = context.watch<UserDataModel>();

    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            storefrontTokenEditBox(
              label: 'GOG auth token',
              token: user.gogAuthCode,
              logoAsset: 'assets/images/gog-128.png',
              textController: _gogTextController,
            ),
            storefrontTokenEditBox(
              label: 'Steam user id',
              token: user.steamUserId,
              logoAsset: 'assets/images/steam-128.png',
              textController: _steamTextController,
            ),
          ],
        ),
      ),
    );
  }

  Padding storefrontTokenEditBox({
    required String logoAsset,
    required String label,
    required String token,
    required TextEditingController textController,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
            child: Image.asset(logoAsset, width: 48),
          ),
          Expanded(
            child: Container(
              width: 200.0,
              child: TextFormField(
                controller: textController..text = token,
                decoration: InputDecoration(
                  labelText: label,
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
              ),
            ),
          ),
        ],
      ),
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
