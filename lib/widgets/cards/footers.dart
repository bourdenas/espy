import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/game_pulse.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';

class InfoTileBar extends StatelessWidget {
  const InfoTileBar(this.title, {super.key, this.year, this.stores = const []});

  final String title;
  final int? year;
  final List<String> stores;

  @override
  Widget build(BuildContext context) {
    return GridTileBar(
      backgroundColor: Colors.black45,
      title: _GameTitleText(title),
      subtitle: Row(children: [
        if (year != null) ...[
          _GameTitleText('$year'),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
        ],
        if (stores.isNotEmpty) _GameTitleText(stores.join(', ')),
      ]),
    );
  }
}

class PulseTileBar extends StatelessWidget {
  const PulseTileBar(this.libraryEntry, {super.key});

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    return GridTileBar(
      backgroundColor: Colors.black54,
      title: GamePulse(libraryEntry, null),
    );
  }
}

class TagsTileBar extends StatelessWidget {
  const TagsTileBar(this.libraryEntry, {super.key});

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    return GridTileBar(
      backgroundColor: Colors.black45,
      title: GameCardChips(
        libraryEntry: libraryEntry,
        includeCollections: false,
        includeCompanies: false,
      ),
    );
  }
}

class _GameTitleText extends StatelessWidget {
  const _GameTitleText(
    this.text,
  );

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(text),
    );
  }
}
