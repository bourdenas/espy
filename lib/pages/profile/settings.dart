import 'package:espy/modules/documents/user_data.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _syncLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 16),
                  storefrontCodeBoxes(context),
                  const SizedBox(height: 64),
                  libraryStats(context),
                  const SizedBox(height: 32),
                  colorSelection(context),
                  const SizedBox(height: 32),
                  Center(
                    child: FilledButton(
                      child: const Text('Sign Out'),
                      onPressed: () {
                        context.read<UserModel>().logout();
                        context.goNamed('home');
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _gogTextController = TextEditingController();
  final _steamTextController = TextEditingController();
  final _egsTextController = TextEditingController();

  Widget storefrontCodeBoxes(BuildContext context) {
    final user = context.watch<UserModel>();

    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            storefrontTokenEditBox(
              storefrontId: 'gog',
              label: 'GOG auth code',
              token: user.gogAuthCode,
              logoAsset: 'assets/images/gog-128.png',
              textController: _gogTextController,
            ),
            storefrontTokenEditBox(
              storefrontId: 'steam',
              label: 'Steam user id',
              token: user.steamUserId,
              logoAsset: 'assets/images/steam-128.png',
              textController: _steamTextController,
            ),
            const SizedBox(height: 16),
            syncButton(context),
          ],
        ),
      ),
    );
  }

  Widget storefrontTokenEditBox({
    required String storefrontId,
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
            child: SizedBox(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
            child: IconButton(
              icon: const Icon(Icons.link_off),
              splashRadius: 16,
              onPressed: () async =>
                  await context.read<UserModel>().unlink(storefrontId),
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
            ? const CircularProgressIndicator()
            : FilledButton(
                child: const Text('Sync'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _syncLoading = true;
                    });

                    final keys = Keys(
                      gogAuthCode: _gogTextController.text,
                      steamUserId: _steamTextController.text,
                      egsAuthCode: _egsTextController.text,
                    );

                    final userModel = context.read<UserModel>();
                    await userModel.setUserKeys(keys);
                    final response = await userModel.syncLibrary(keys);

                    setState(() {
                      _syncLoading = false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response),
                        ),
                      );
                    });
                  }
                },
              ),
      ],
    );
  }

  Widget libraryStats(BuildContext context) {
    final entries = context.watch<UserLibraryModel>().entries;

    final mainCount = entries.where((e) => e.digest.isMain).length;
    final dlcCount = entries.where((e) => e.digest.isDlc).length;
    final expansionCount = entries.where((e) => e.digest.isExpansion).length;
    final bundleCount = entries.where((e) => e.digest.isBundle).length;
    final standaloneExpansionCount =
        entries.where((e) => e.digest.isStandaloneExpansion).length;
    final episodeCount = entries.where((e) => e.digest.isEpisode).length;
    final seasonCount = entries.where((e) => e.digest.isSeason).length;
    final remakeCount = entries.where((e) => e.digest.isRemake).length;
    final remasterCount = entries.where((e) => e.digest.isRemaster).length;
    final versionCount = entries.where((e) => e.digest.isVersion).length;
    final ignoreCount = entries.where((e) => e.digest.isIgnore).length;

    return Column(
      children: [
        Text(
          'Library Stats',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('Main Titles: $mainCount'),
        Text('Expansions: $expansionCount'),
        Text('Standalone Expansions: $standaloneExpansionCount'),
        Text('DLC: $dlcCount'),
        Text('Remakes: $remakeCount'),
        Text('Remaster: $remasterCount'),
        Text('Seasons: $seasonCount'),
        Text('Episodes: $episodeCount'),
        Text('Bundles: $bundleCount'),
        Text('Versions: $versionCount'),
        Text('Ignore: $ignoreCount'),
      ],
    );
  }

  Widget colorSelection(BuildContext context) {
    final appConfig = context.read<AppConfigModel>();

    return Column(
      children: [
        Text(
          'Theme Colour',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final color in [
              Colors.blueGrey,
              Colors.indigo,
              Colors.blue
            ]) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.circle,
                    color: color,
                    size: 32,
                  ),
                  onPressed: () => appConfig.seedColor = color,
                ),
              ),
            ],
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final color in [Colors.teal, Colors.green, Colors.amber]) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.circle,
                    color: color,
                    size: 32,
                  ),
                  onPressed: () => appConfig.seedColor = color,
                ),
              ),
            ],
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final color in [
              Colors.orange,
              Colors.deepOrange,
              Colors.pink
            ]) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.circle,
                    color: color,
                    size: 32,
                  ),
                  onPressed: () => appConfig.seedColor = color,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
