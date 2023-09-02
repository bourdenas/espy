import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/library/library_list_card.dart';
import 'package:flutter/material.dart';

class LibraryListView extends StatelessWidget {
  const LibraryListView(
    this.libraryView, {
    Key? key,
  }) : super(key: key);

  final LibraryView libraryView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeInUp(
        from: 20,
        duration: const Duration(milliseconds: 500),
        child: CustomScrollView(
          primary: true,
          shrinkWrap: true,
          slivers: [
            SliverGrid.extent(
              maxCrossAxisExtent: _maxCardWidth,
              childAspectRatio: _cardAspectRation,
              children: libraryView.all
                  .map((e) => LibraryListCard(libraryEntry: e))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  static const _maxCardWidth = 600.0;
  static const _cardAspectRation = 2.5;
}
