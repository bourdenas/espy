import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/library/library_grid_view.dart';
import 'package:espy/widgets/library/library_list_view.dart';
import 'package:espy/widgets/library/tags_cloud.dart';
import 'package:espy/widgets/library/unmatched_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum LibraryLayout {
  GRID,
  LIST,
}

class GameLibrary extends StatelessWidget {
  final LibraryLayout view;

  const GameLibrary({Key? key, required this.view}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget viewWidget =
        view == LibraryLayout.GRID ? LibraryGridView() : LibraryListView();

    final path = context.watch<EspyRouterDelegate>().path;

    if (path.isUnmatchedPage) {
      viewWidget = UnmatchedView();
    } else if (path.isTagsPage) {
      viewWidget = TagsCloud();
    }

    return viewWidget;
  }
}
