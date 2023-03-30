import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/widgets/autocomplete_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTagsField extends StatelessWidget {
  final int gameId;

  const GameTagsField(this.gameId, {Key? key}) : super(key: key);

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
              .userTags
              .filter(searchTerms)
              .take(3)
              .map(
                (tag) => Suggestion(
                  text: tag.name,
                  onTap: () => _addTag(context, tag),
                ),
              ),
          Suggestion(
              text: text, onTap: () => _addTag(context, UserTag(name: text))),
        ];
      },
      onSubmit: (text, suggestion) => _addTag(
        context,
        UserTag(name: suggestion?.text ?? text),
      ),
    );
  }

  void _addTag(BuildContext context, UserTag tag) {
    if (tag.name.isNotEmpty) {
      context.read<GameTagsModel>().userTags.add(tag, gameId);
    }
  }
}
