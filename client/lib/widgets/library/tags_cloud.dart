import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/widgets/details/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TagsCloud extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tags = context.read<GameTagsModel>().tags;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: [
              for (final tag in tags)
                TagChip(tag, LibraryEntry(id: 0, name: "foo")),
            ],
          ),
        ),
      ],
    );
  }
}
