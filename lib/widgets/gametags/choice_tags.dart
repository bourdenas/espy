import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/utils/edit_distance.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Chips used for user tag selection for a `LibraryEntry`.
class ChoiceTags extends StatefulWidget {
  final LibraryEntry entry;
  final List<String> keywords;

  const ChoiceTags(this.entry, this.keywords, {Key? key}) : super(key: key);

  @override
  State<ChoiceTags> createState() => _ChoiceTagsState();
}

class _ChoiceTagsState extends State<ChoiceTags> {
  Set<UserTag> selectedTags = {};
  String filter = '';

  @override
  Widget build(BuildContext context) {
    void onSelected(bool selected, UserTag tag) {
      if (selected) {
        context.read<GameTagsModel>().userTags.add(tag, widget.entry.id);
      } else {
        context.read<GameTagsModel>().userTags.remove(tag, widget.entry.id);
      }
    }

    final tagsModel = context.watch<GameTagsModel>();
    final filteredTags = tagsModel.userTags.filter(filter.split(' '));
    selectedTags.clear();
    selectedTags.addAll(tagsModel.userTags.byGameId(widget.entry.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 350),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      for (final tag in filteredTags)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              if (matchInDict(tag.name, widget.keywords))
                                BoxShadow(
                                  color: tag.color,
                                  blurRadius: 6.0,
                                  spreadRadius: 2.0,
                                ),
                            ],
                          ),
                          child: ChoiceChip(
                            label: Text(
                              tag.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      color: selectedTags
                                              .any((e) => e.name == tag.name)
                                          ? Colors.white
                                          : tag.color[300]),
                            ),
                            selected:
                                selectedTags.any((e) => e.name == tag.name),
                            selectedColor: tag.color,
                            onSelected: (selected) => onSelected(selected, tag),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextFormField(
            autofocus: !AppConfigModel.isMobile(context),
            decoration: const InputDecoration(
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
              context
                  .read<GameTagsModel>()
                  .userTags
                  .add(UserTag(name: text), widget.entry.id);
              setState(() {
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
