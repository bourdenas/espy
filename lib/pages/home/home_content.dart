import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/pages/home/home_headline.dart';
import 'package:espy/pages/timeline/timeline_carousel.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:espy/widgets/tiles/tile_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return library(context);
  }

  Widget library(BuildContext context) {
    final slates = context
        .watch<HomeSlatesModel>()
        .slates
        .where((slate) => slate.entries.isNotEmpty)
        .toList();
    final frontpageSlates = context
        .watch<FrontpageModel>()
        .slates
        .where((slate) => slate.entries.isNotEmpty)
        .toList();
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
                onTitleTap: () => slate.onTap(context),
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
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return TileCarousel(
                title: frontpageSlates[index].title,
                onTitleTap: () => frontpageSlates[index].onTap(context),
                tileSize: AppConfigModel.isMobile(context)
                    ? const TileSize(width: 133, height: 190)
                    : const TileSize(width: 227, height: 320),
                tiles: frontpageSlates[index]
                    .entries
                    .map((digest) => TileData(
                          image:
                              '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
                          onTap: () => context.pushNamed('details',
                              pathParameters: {'gid': '${digest.id}'}),
                        ))
                    .toList(),
              );
            },
            childCount: frontpageSlates.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 32.0),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              TimelineCarousel(
                tileSize: AppConfigModel.isMobile(context)
                    ? const TileSize(width: 133, height: 190)
                    : const TileSize(width: 227, height: 320),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 32.0),
        ),
      ],
    );
  }
}
