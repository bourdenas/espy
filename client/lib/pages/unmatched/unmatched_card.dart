import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnmatchedCard extends StatelessWidget {
  UnmatchedCard({
    Key? key,
    required this.entry,
  }) : super(key: key);

  final StoreEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => MatchingDialog.show(
        context,
        storeEntry: entry,
        onMatch: (storeEntry, gameEntry) =>
            context.read<GameLibraryModel>().matchEntry(storeEntry, gameEntry),
      ),
      onSecondaryTap: () {},
      child: Container(
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 170,
              width: 120,
              child: Center(
                child: Icon(Icons.help_outline),
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headline6,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4.0),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text('???'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  StoreChip(entry.storefront),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
