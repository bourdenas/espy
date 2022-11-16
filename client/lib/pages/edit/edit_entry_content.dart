import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/storefront_dropdown.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/gametags/choice_tags.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class EditEntryContent extends StatelessWidget {
  const EditEntryContent({
    Key? key,
    required this.libraryEntry,
    this.gameEntry,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;

  @override
  Widget build(BuildContext context) {
    List<String> keywords =
        gameEntry != null ? gameEntry!.genres + gameEntry!.keywords : [];

    return ListView(
      shrinkWrap: true,
      children: [
        SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                foregroundImage: CachedNetworkImageProvider(
                  '${Urls.imageProvider}/t_thumb/${libraryEntry.cover}.jpg',
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  libraryEntry.name,
                  style: Theme.of(context).textTheme.headline5,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.0),
        Card(
          child: ExpandableNotifier(
            initialExpanded: true,
            child: ExpandablePanel(
              header: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Game Tags'),
              ),
              collapsed: Container(),
              expanded: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Keywords: ${keywords.join(", ")}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  ChoiceTags(libraryEntry, keywords),
                  SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
        Card(
          child: ExpandableNotifier(
            initialExpanded: true,
            child: ExpandablePanel(
              header: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Storefronts'),
              ),
              collapsed: Container(),
              expanded: StorefrontDropdown(libraryEntry),
            ),
          ),
        ),
      ],
    );
  }
}
