import 'package:espy/modules/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsDialog extends StatelessWidget {
  static Future<void> show(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(),
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _steamTextController = TextEditingController();
  final _gogTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Settings'),
      content: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40.0,
            top: -80.0,
            child: InkResponse(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                child: Icon(Icons.close),
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
                        child: Image.asset(
                          'assets/images/gog-128.png',
                          width: 48,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _gogTextController
                            ..text = context.watch<UserModel>().gogAuthCode,
                          decoration: InputDecoration(
                            labelText: 'GOG auth token',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
                        child: Image.asset(
                          'assets/images/steam-128.png',
                          width: 48,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _steamTextController
                            ..text = context.watch<UserModel>().steamUserId,
                          decoration: InputDecoration(
                            labelText: 'Steam auth token',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          child: Text("Ok"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<UserModel>().updateUserInformation(
                    steamUserId: _steamTextController.text,
                    gogAuthCode: _gogTextController.text,
                  );
              Navigator.of(context).pop();
            }
          },
        ),
        TextButton(
          child: Text("Sync"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<UserModel>().updateUserInformation(
                    steamUserId: _steamTextController.text,
                    gogAuthCode: _gogTextController.text,
                  );
            }
            context.read<UserModel>().syncLibrary();
          },
        ),
        TextButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
