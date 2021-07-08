import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/proto/library.pb.dart';
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
                          controller: TextEditingController()
                            ..text = 'xyfywdfjlk23sdx3',
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
                          controller: TextEditingController()
                            ..text = 'ex82dsdb02cpqwj2',
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
              print('TODO: send tokens to backend');
            }
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

class _StorefrontDropdown extends StatefulWidget {
  _StorefrontDropdown(this._entry);

  final GameEntry _entry;

  @override
  _StorefrontDropdownState createState() => _StorefrontDropdownState(_entry);
}

class _StorefrontDropdownState extends State<_StorefrontDropdown> {
  _StorefrontDropdownState(this._entry) : _chosenValue = _entry.storeEntry[0];

  final GameEntry _entry;
  StoreEntry _chosenValue;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      child: Column(
        children: [
          DropdownButton<StoreEntry>(
            value: _chosenValue,
            items: [
              for (final storeEntry in _entry.storeEntry)
                DropdownMenuItem<StoreEntry>(
                  value: storeEntry,
                  child: Text(storeEntry.store.toString()),
                ),
            ],
            hint: Text(
              "Storefront selection",
            ),
            onChanged: (StoreEntry? value) {
              setState(() {
                _chosenValue = value!;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: TextEditingController()..text = _chosenValue.title,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Store Title',
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text(
                            'Are you sure you want to unmatch this store entry?'),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        "Unmatching '${_chosenValue.title}'...")));
                                Navigator.of(context).pop();

                                if (_entry.storeEntry.length == 1) {
                                  context
                                      .read<EspyRouterDelegate>()
                                      .showLibrary();
                                }

                                await context
                                    .read<GameLibraryModel>()
                                    .unmatchEntry(_chosenValue, _entry.game);
                              },
                              child: Text('Confirm')),
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Cancel')),
                        ],
                      );
                    });
              },
              child: Text('Unmatch'),
            ),
          ),
        ],
      ),
    );
  }
}
