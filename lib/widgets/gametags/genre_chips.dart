import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/material.dart';

/// Chips used for refining genres for a `LibraryEntry`.
class GenreChips extends StatefulWidget {
  const GenreChips(this.libraryEntry, {Key? key}) : super(key: key);

  final LibraryEntry libraryEntry;

  @override
  State<GenreChips> createState() => _GenreChipsState();
}

class _GenreChipsState extends State<GenreChips> {
  Set<String> selectedGenres = {};
  String filter = '';

  @override
  void initState() {
    super.initState();
    selectedGenres = Set.from(widget.libraryEntry.digest.genres);
  }

  @override
  Widget build(BuildContext context) {
    void onSelected(bool selected, String genre) {
      setState(() {
        if (selected) {
          selectedGenres.add(genre);
        } else {
          selectedGenres.remove(genre);
        }
      });
    }

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
                    alignment: WrapAlignment.center,
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      for (final genre in genres)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              // Halo effect for suggesting a genre.
                              if (widget.libraryEntry.digest.genres
                                  .contains(genre))
                                BoxShadow(
                                  color: Colors.blueAccent[200]!,
                                  blurRadius: 6.0,
                                  spreadRadius: 2.0,
                                ),
                            ],
                          ),
                          child: GenreSelection(
                            genre: genre,
                            selected:
                                selectedGenres.any((name) => name == genre),
                            onSelected: onSelected,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GenreSelection extends StatelessWidget {
  const GenreSelection({
    super.key,
    required this.genre,
    required this.selected,
    required this.onSelected,
  });

  final String genre;
  final bool selected;
  final void Function(bool, String) onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        genre,
        style: Theme.of(context)
            .textTheme
            .bodyLarge!
            .copyWith(color: selected ? Colors.white : Colors.blueAccent[300]),
      ),
      selected: selected,
      selectedColor: Colors.blueAccent[200],
      onSelected: (selected) => onSelected(selected, genre),
    );
  }
}

const genres = [
  'Adventure',
  'Arcade',
  'Card & Board Game',
  'MOBA',
  'Platformer',
  'Racing',
  'RPG',
  'Shooter',
  'Simulator',
  'Sport',
  'Strategy',
];
