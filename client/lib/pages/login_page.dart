import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/documents/user_data.dart';
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

class ProfilePage extends StatefulWidget {
  ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  _ProfilePageState() : _syncLog = '';

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
        storefrontCodeBoxes(context),
        SizedBox(height: 16),
        syncButtons(context),
        SizedBox(height: 32),
        manualEditBoxes(context),
        SizedBox(height: 16),
        uploadButtons(context),
        SizedBox(height: 32),
        syncLog(),
      ],
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _gogTextController = TextEditingController();
  final _steamTextController = TextEditingController();
  final _egsTextController = TextEditingController();

  Widget storefrontCodeBoxes(BuildContext context) {
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

  Widget storefrontTokenEditBox({
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

  Widget syncButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text("Sync"),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final keys = Keys(
                gogToken: GogToken(
                  oauthCode: _gogTextController.text,
                ),
                steamUserId: _steamTextController.text,
                egsAuthCode: _egsTextController.text,
              );

              await context.read<UserDataModel>().setUserKeys(keys);
              final response =
                  await context.read<UserDataModel>().syncLibrary(keys);
              setState(() {
                _syncLog = response;
              });
            }
          },
        ),
      ],
    );
  }

  Widget manualEditBoxes(BuildContext context) {
    return Form(
      // key: _formKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            manualUploadEditBox(
              label: 'Add Epic Games Store titles manually...',
              token: '',
              logoAsset: 'assets/images/egs-128.png',
              textController: _egsTextController,
            ),
          ],
        ),
      ),
    );
  }

  Widget manualUploadEditBox({
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
                maxLines: 5,
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

  Widget uploadButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text("Upload"),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final titles = Upload(
                  entries: _egsTextController.text
                      .split('\n')
                      .map((line) =>
                          StoreEntry(id: '', title: line, storefront: 'egs'))
                      .toList());

              final response =
                  await context.read<UserDataModel>().uploadLibrary(titles);
              setState(() {
                _syncLog = response;
              });
            }
          },
        ),
      ],
    );
  }

  String _syncLog;

  Widget syncLog() {
    return Expanded(
      child: Container(
        width: 300,
        child: Text(_syncLog),
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
