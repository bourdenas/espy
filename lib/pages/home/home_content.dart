import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:espy/pages/home/empty_library.dart';
import 'package:espy/pages/home/home_headline.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return context.watch<LibraryEntriesModel>().isNotEmpty
        ? library(context)
        : const EmptyLibrary();
  }

  Widget library(BuildContext context) {
    final model = context.watch<HomeSlatesModel>();
    final slates =
        model.slates.where((slate) => slate.entries.isNotEmpty).toList();
    final isMobile = AppConfigModel.isMobile(context);

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        if (isMobile)
          const SliverToBoxAdapter(child: HomeHeadline())
        else
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final slate = slates[index];
              return TileCarousel(
                title: slate.title,
                onTitleTap: () => setLibraryView(context, slate.filter),
                tileSize: AppConfigModel.isMobile(context)
                    ? const TileSize(width: 133, height: 190)
                    : const TileSize(width: 227, height: 320),
                tiles: slate.entries
                    .map((libraryEntry) => TileData(
                          image:
                              '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
                          onTap: () => context.pushNamed('details',
                              pathParameters: {'gid': '${libraryEntry.id}'}),
                          onLongTap: () => isMobile
                              ? context.pushNamed('edit',
                                  pathParameters: {'gid': '${libraryEntry.id}'})
                              : EditEntryDialog.show(
                                  context,
                                  libraryEntry,
                                  gameId: libraryEntry.id,
                                ),
                        ))
                    .toList(),
              );
            },
            childCount: slates.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 32.0),
        ),
      ],
    );
  }
}
