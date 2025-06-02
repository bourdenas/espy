import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/widgets/stats/filter_side_pane.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewPage extends StatelessWidget {
  const ViewPage({super.key, required this.title, required this.viewId});

  final String title;
  final String viewId;

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<LibraryViewModel>().getEntries(viewId);
    final libraryEntries =
        context.watch<FilterModel>().processLibraryEntries(entries);

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Scaffold(
                appBar: libraryAppBar(context, libraryEntries.length),
                body: libraryBody(libraryEntries),
              ),
            ),
            // Add some space for the side pane.
            SizedBox(
              width: context.watch<AppConfigModel>().showBottomSheet ? 500 : 40,
            ),
          ],
        ),
        FilterSidePane(entries),
      ],
    );
  }

  Widget libraryBody(Iterable<LibraryEntry> libraryEntries) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            primary: true,
            shrinkWrap: true,
            slivers: [
              LibraryEntriesView(libraryEntries),
            ],
          ),
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
      title: Text(title),
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      elevation: 0.0,
    );
  }
}
