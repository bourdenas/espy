import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:espy/widgets/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TagsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tags = context.read<GameDetailsModel>().tags;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: [
              for (final tag in tags) TagChip(tag, GameEntry()),
            ],
          ),
        ),
      ],
    );
  }
}
