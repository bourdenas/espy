import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/widgets/stats/filter_side_pane.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewPage extends StatefulWidget {
  const ViewPage({super.key, required this.title});

  final String title;

  @override
  State<ViewPage> createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  LibraryView libraryView = LibraryView.stream;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomViewModel>();

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Scaffold(
                appBar: libraryAppBar(context, viewModel.length),
                body: libraryBody(viewModel),
              ),
            ),
            // Add some space for the side pane.
            SizedBox(
              width: context.watch<AppConfigModel>().showBottomSheet ? 500 : 40,
            ),
          ],
        ),
        FilterSidePane(viewModel.entries),
      ],
    );
  }

  Widget libraryBody(CustomViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: switch (libraryView) {
            LibraryView.stream => CustomScrollView(
                primary: true,
                shrinkWrap: true,
                slivers: [
                  LibraryEntriesView(viewModel.entries),
                ],
              ),
          },
        ),
      ],
    );
  }

  AppBar libraryAppBar(BuildContext context, int libraryViewLength) {
    return AppBar(
      leading: badges.Badge(
        badgeContent: Text(
          '$libraryViewLength',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        badgeStyle: badges.BadgeStyle(
          shape: badges.BadgeShape.circle,
          badgeColor: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(8),
        ),
        position: badges.BadgePosition.center(),
        child: Container(),
      ),
      title: Stack(
        children: [
          Text(widget.title),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentedButton<LibraryView>(
                segments: const <ButtonSegment<LibraryView>>[
                  ButtonSegment<LibraryView>(
                    value: LibraryView.stream,
                    label: Text('Stream'),
                    icon: Icon(Icons.view_stream),
                  ),
                ],
                selected: <LibraryView>{libraryView},
                onSelectionChanged: (Set<LibraryView> newSelection) {
                  setState(() {
                    libraryView = newSelection.first;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      elevation: 0.0,
    );
  }
}

enum LibraryView {
  stream,
}
