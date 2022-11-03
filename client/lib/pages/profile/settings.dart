import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:espy/modules/models/user_data_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  _SettingsState() : _syncLog = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16),
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headline6!.copyWith(
                color: Colors.white70,
              ),
        ),
        SizedBox(height: 16),
        storefrontCodeBoxes(context),
        SizedBox(height: 16),
        syncButton(context),
        SizedBox(height: 32),
        manualEditBoxes(context),
        SizedBox(height: 16),
        uploadButton(context),
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

  Widget syncButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _syncLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                child: Text("Sync"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _syncLog = 'Syncing storefronts...';
                      _syncLoading = true;
                    });

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
                      _syncLoading = false;
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

  Widget uploadButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _uploadLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                child: Text("Upload"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _syncLog = 'uploading...';
                      _uploadLoading = true;
                    });

                    final titles = Upload(
                        entries: _egsTextController.text
                            .split('\n')
                            .map((line) => StoreEntry(
                                id: '', title: line, storefront: 'egs'))
                            .toList());

                    final response = await context
                        .read<UserDataModel>()
                        .uploadLibrary(titles);

                    setState(() {
                      _syncLog = response;
                      _uploadLoading = false;
                    });
                  }
                },
              ),
      ],
    );
  }

  String _syncLog;
  bool _syncLoading = false;
  bool _uploadLoading = false;

  Widget syncLog() {
    return Expanded(
      child: Container(
        width: 400,
        child: Text(
          _syncLog,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.white70,
              ),
        ),
      ),
    );
  }
}
