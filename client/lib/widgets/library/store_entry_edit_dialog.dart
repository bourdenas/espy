import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StoreEntryEditDialog extends StatefulWidget {
  final StoreEntry storeEntry;

  StoreEntryEditDialog(this.storeEntry);

  @override
  _StoreEntryEditDialogState createState() =>
      _StoreEntryEditDialogState(storeEntry);
}

class _StoreEntryEditDialogState extends State<StoreEntryEditDialog> {
  final StoreEntry storeEntry;

  _StoreEntryEditDialogState(this.storeEntry);

  final _formKey = GlobalKey<FormState>();

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
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    initialValue: storeEntry.title,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      hintText: 'match...',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    autofocus: kIsWeb,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'match...',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    child: Text("Ok"),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showEntryEditModalView(
    BuildContext context, StoreEntry entry) async {
  showDialog(
    context: context,
    builder: (context) => StoreEntryEditDialog(entry),
  );
}
