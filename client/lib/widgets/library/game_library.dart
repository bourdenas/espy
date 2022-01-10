import 'package:espy/modules/models/config_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/library/filter_chips.dart';
import 'package:espy/widgets/library/library_expanded_list_view.dart';
import 'package:espy/widgets/library/library_grid_view.dart';
import 'package:espy/widgets/library/library_list_view.dart';
import 'package:espy/widgets/library/tags_cloud.dart';
import 'package:espy/widgets/library/unmatched_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameLibrary extends StatelessWidget {
  final LibraryLayout view;

  const GameLibrary({Key? key, required this.view}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final path = context.watch<EspyRouterDelegate>().currentConfiguration;

    if (path.isUnmatchedPage) {
      return UnmatchedView();
    } else if (path.isTagsPage) {
      return TagsCloud();
    }

    final filter =
        context.select((EspyRouterDelegate delegate) => delegate.filter);

    return Column(
      children: [
        if (filter != null)
          Container(
            padding: EdgeInsets.all(16),
            child: FilterChips(),
          ),
        Expanded(
          child: view == LibraryLayout.GRID
              ? LibraryGridView()
              : view == LibraryLayout.EXPANDED_LIST
                  ? LibraryExpandedListView()
                  : LibraryListView(),
        ),
      ],
    );
  }
}
