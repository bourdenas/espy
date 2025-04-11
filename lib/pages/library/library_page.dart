import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/widgets/stats/filter_bottom_sheet.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();
    final libraryViewModel = context.watch<LibraryViewModel>();

    return Scaffold(
      appBar: libraryAppBar(context, appConfig, libraryViewModel.length),
      body: Stack(
        children: [
          libraryBody(appConfig, libraryViewModel),
          FilterBottomSheet(libraryViewModel.entries),
        ],
      ),
    );
  }

  Widget libraryBody(
      AppConfigModel appConfig, LibraryViewModel libraryViewModel) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            primary: true,
            shrinkWrap: true,
            slivers: [
              if (appConfig.libraryGrouping.value == LibraryGrouping.none)
                LibraryEntriesView(
                  entries: libraryViewModel.entries,
                )
              else ...[
                for (final (label, entries) in libraryViewModel.groups)
                  TileShelve(
                    title: '$label (${entries.length})',
                    color: Colors.grey,
                    entries: entries,
                  ),
              ],
            ],
          ),
        ),
        // Add some space for the bottom sheet.
        SizedBox(height: 52),
      ],
    );
  }

  AppBar libraryAppBar(
      BuildContext context, AppConfigModel appConfig, int libraryViewLength) {
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
      title: Text(title),
      // backgroundColor: Colors.black.withOpacity(0.6),
      // elevation: 0.0,
    );
  }
}
