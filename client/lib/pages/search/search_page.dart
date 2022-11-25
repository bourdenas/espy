import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/pages/search/search_results.dart';
import 'package:espy/pages/search/search_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    final ngrams = _text.toLowerCase().split(' ');

    final titleMatches = _text.isNotEmpty
        ? context
            .read<GameLibraryModel>()
            .entries
            .where((entry) => ngrams.every((term) => entry.name
                .toLowerCase()
                .split(' ')
                .any((word) => word.startsWith(term))))
            .toList()
        : <LibraryEntry>[];

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        SliverPersistentHeader(
          delegate: searchBox(),
        ),
        SliverPersistentHeader(
          pinned: true,
          floating: true,
          delegate: section('Tag Matches', Colors.indigo),
        ),
        TagSearchResults(query: _text),
        if (titleMatches.isNotEmpty) ...[
          SliverPersistentHeader(
            pinned: true,
            floating: true,
            delegate: section('Title Matches', Colors.blue),
          ),
          GameSearchResults(entries: titleMatches),
        ],
      ],
    );
  }

  _SectionHeader section(String title, Color color) {
    return _SectionHeader(
      minHeight: 50.0,
      maxHeight: 50.0,
      child: Stack(
        children: [
          Expanded(
              child: Container(
            color: color,
          )),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(title),
          ),
        ],
      ),
    );
  }

  _SectionHeader searchBox() {
    return _SectionHeader(
      minHeight: 80.0,
      maxHeight: 120.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SearchTextField(
          onChanged: (text) {
            text.toLowerCase().split(' ');
            setState(() {
              _text = text;
            });
          },
        ),
      ),
    );
  }

  String _text = '';
}

class _SectionHeader extends SliverPersistentHeaderDelegate {
  _SectionHeader({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(_SectionHeader oldSearchBar) {
    return maxHeight != oldSearchBar.maxHeight ||
        minHeight != oldSearchBar.minHeight ||
        child != oldSearchBar.child;
  }
}
