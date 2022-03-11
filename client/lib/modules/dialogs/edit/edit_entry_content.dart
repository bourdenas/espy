import 'package:espy/modules/dialogs/edit/storefront_dropdown.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class EditEntryContent extends StatelessWidget {
  const EditEntryContent({
    Key? key,
    required this.entry,
  }) : super(key: key);

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            entry.name,
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
        SizedBox(height: 16.0),
        GameTags(entry),
        SizedBox(height: 16.0),
        Card(
          child: ExpandablePanel(
            header: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Storefronts'),
            ),
            collapsed: Container(),
            expanded: StorefrontDropdown(entry),
          ),
        ),
      ],
    );
  }
}
