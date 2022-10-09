import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChoiceTags extends StatefulWidget {
  final LibraryEntry entry;

  ChoiceTags(this.entry);

  @override
  State<ChoiceTags> createState() => _ChoiceTagsState();
}

class _ChoiceTagsState extends State<ChoiceTags> {
  Set<String> selectedTags = {};
  String filter = '';

  @override
  Widget build(BuildContext context) {
    // Forces the widget to rebuild when library entries update (e.g. tags).
    context.watch<GameLibraryModel>();

    final onSelected = (bool selected, String tag) {
      setState(() {
        if (selected)
          selectedTags.add(tag);
        else
          selectedTags.remove(tag);

        widget.entry.userData = GameUserData(tags: selectedTags.toList());
        context.read<GameLibraryModel>().postDetails(widget.entry);
      });
    };

    selectedTags.addAll(widget.entry.userData.tags);
    final filteredTags =
        context.read<GameTagsModel>().filterTags(filter.split(' '));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 350),
            child: ListView(
              shrinkWrap: true,
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    for (final tag in filteredTags)
                      ChoiceChip(
                        label: Text(tag),
                        selected: selectedTags.contains(tag),
                        selectedColor: Colors.blueGrey,
                        onSelected: (selected) => onSelected(selected, tag),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextFormField(
            autofocus: !AppConfigModel.isMobile(context),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.label),
              hintText: 'Label...',
            ),
            controller: _textController,
            onChanged: (text) {
              setState(() {
                filter = text;
              });
            },
            onFieldSubmitted: (text) {
              setState(() {
                selectedTags.add(text);

                widget.entry.userData =
                    GameUserData(tags: selectedTags.toList());
                context.read<GameLibraryModel>().postDetails(widget.entry);
                _textController.text = '';
                filter = '';
              });
            },
          ),
        ),
      ],
    );
  }

  final TextEditingController _textController = TextEditingController();
}
