import 'package:espy/pages/search/search_results.dart';
import 'package:espy/pages/search/search_text_field.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: CustomScrollView(
        primary: true,
        shrinkWrap: true,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: SearchBar(
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
            ),
          ),
          TagSearchResults(query: _text),
          GameSearchResults(query: _text),
        ],
      ),
    );
  }

  String _text = '';
}

class SearchBar extends SliverPersistentHeaderDelegate {
  SearchBar({
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
    return SizedBox.expand(child: child);
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(SearchBar oldSearchBar) {
    return maxHeight != oldSearchBar.maxHeight ||
        minHeight != oldSearchBar.minHeight ||
        child != oldSearchBar.child;
  }
}
