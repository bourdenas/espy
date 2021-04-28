import 'package:espy/proto/library.pb.dart';
import 'package:flutter/material.dart';

class GameEntryEditDialog extends StatelessWidget {
  static Future<void> show(BuildContext context, GameEntry entry) async {
    showDialog(
      context: context,
      builder: (context) => GameEntryEditDialog(entry),
    );
  }

  final GameEntry gameEntry;

  GameEntryEditDialog(this.gameEntry);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40.0,
            top: -40.0,
            child: InkResponse(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                child: Icon(Icons.close),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: TextEditingController()
                    ..text = gameEntry.game.name,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: TextEditingController()
                    ..text = '${gameEntry.game.firstReleaseDate}',
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Release Date',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _StorefrontDropdown(gameEntry.storeEntry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorefrontDropdown extends StatefulWidget {
  _StorefrontDropdown(this._entries);

  final List<StoreEntry> _entries;

  @override
  _StorefrontDropdownState createState() => _StorefrontDropdownState(_entries);
}

class _StorefrontDropdownState extends State<_StorefrontDropdown> {
  _StorefrontDropdownState(this._entries) : _chosenValue = _entries[0];

  final List<StoreEntry> _entries;
  StoreEntry _chosenValue;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      child: Column(
        children: [
          DropdownButton<StoreEntry>(
            value: _chosenValue,
            //elevation: 5,
            items: [
              for (final storeEntry in _entries)
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
              onPressed: () {},
              child: Text('Unmatch'),
            ),
          ),
        ],
      ),
    );
  }
}
