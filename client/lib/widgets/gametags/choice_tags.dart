import 'dart:math';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChoiceTags extends StatefulWidget {
  final LibraryEntry entry;
  final List<String> keywords;

  ChoiceTags(this.entry, this.keywords);

  @override
  State<ChoiceTags> createState() => _ChoiceTagsState();
}

class _ChoiceTagsState extends State<ChoiceTags> {
  Set<UserTag> selectedTags = {};
  String filter = '';

  @override
  Widget build(BuildContext context) {
    final onSelected = (bool selected, UserTag tag) {
      if (selected) {
        context.read<GameTagsModel>().userTags.add(tag, widget.entry.id);
      } else {
        context.read<GameTagsModel>().userTags.remove(tag, widget.entry.id);
      }
    };

    final tagsModel = context.watch<GameTagsModel>();
    final filteredTags = tagsModel.userTags.filter(filter.split(' '));
    selectedTags.clear();
    selectedTags.addAll(tagsModel.userTags.byEntry(widget.entry.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 350),
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
                              if (matchKws(tag.name))
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
                                  .bodyText1!
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

  bool matchKws(String tag) {
    for (final kw in widget.keywords) {
      final distance = _editDistance(tag.toLowerCase(), kw.toLowerCase()) /
          max(tag.length, kw.length);
      if (distance < .3) {
        return true;
      }
    }
    return false;
  }
}

int _editDistance(String a, String b) {
  if (a == b) {
    return 0;
  } else if (a.isEmpty) {
    return b.length;
  } else if (b.isEmpty) {
    return a.length;
  }

  var v0 = List<int>.generate(b.length + 1, (i) => i, growable: false);
  var v1 = List<int>.filled(b.length + 1, 0, growable: false);

  for (var i = 0; i < a.length; ++i) {
    v1[0] = i + 1;

    for (var j = 0; j < b.length; ++j) {
      int distance = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + distance));
    }

    var vtemp = v0;
    v0 = v1;
    v1 = vtemp;
  }

  return v0.last;
}
