import 'package:espy/pages/edit/edit_entry_content.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/material.dart';

class EditEntryDialog extends StatelessWidget {
  static Future<void> show(BuildContext context, LibraryEntry entry) async {
    showDialog(
      context: context,
      builder: (context) => EditEntryDialog(entry),
    );
  }

  final LibraryEntry entry;

  EditEntryDialog(this.entry);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: EditEntryContent(entry: entry),
    );
  }
}
