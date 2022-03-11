import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/storefront_dropdown.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/gametags/choice_tags.dart';
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
        SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                foregroundImage: CachedNetworkImageProvider(
                  '${Urls.imageProvider}/t_thumb/${entry.cover}.jpg',
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  entry.name,
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
                children: [
                  ChoiceTags(entry),
                  SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
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
