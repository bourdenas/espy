import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/widgets/autocomplete_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTagsField extends StatelessWidget {
  final LibraryEntry entry;

  const GameTagsField(this.entry, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AutocompleteField(
      width: 200,
      hintText: 'Label...',
      icon: Icon(Icons.label),
      createSuggestions: (text) {
        final searchTerms = text.toLowerCase().split(' ');
        return [
          ...context
              .read<GameTagsModel>()
              .tags
              .where(
                (tag) => searchTerms.every((term) => tag
                    .toLowerCase()
                    .split(' ')
                    .any((word) => word.startsWith(term))),
              )
              .take(3)
              .map(
                (tag) => Suggestion(
                  text: tag,
                  onTap: () => _addTag(context, tag),
                ),
              ),
          Suggestion(text: text, onTap: () => _addTag(context, text)),
        ];
      },
      onSubmit: (text, suggestion) => _addTag(
        context,
        suggestion?.text ?? text,
      ),
    );
  }

  void _addTag(BuildContext context, String tag) {
    if (tag.isEmpty) return;

    // NB: I don't get it why just "entry.userData.tags.add(tag);" fails and I
    // need to clone GameDetails to edit it.
    entry.userData = GameUserData(tags: entry.userData.tags + [tag]);
    context.read<GameLibraryModel>().postDetails(entry);
  }
}
