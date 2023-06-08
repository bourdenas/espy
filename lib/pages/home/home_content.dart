import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/widgets/empty_library.dart';
import 'package:espy/pages/home/home_headline.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:espy/widgets/tiles/tile_stack.dart';
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
    final stacks = model.stacks;
    final isMobile = AppConfigModel.isMobile(context);
    final appConfig = context.watch<AppConfigModel>();

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
                onTitleTap: () => context.pushNamed(
                  'games',
                  queryParameters: slate.filter.params(),
                ),
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
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: InkWell(
                  onTap: () => appConfig.stacks.nextValue(),
                  child: Text(
                    'Browse by ${appConfig.stacks.value.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          sliver: SliverGrid.extent(
            maxCrossAxisExtent: 260,
            mainAxisSpacing: 64,
            crossAxisSpacing: 128,
            childAspectRatio: .7,
            children: [
              for (final stack in stacks)
                TileStack(
                  title: stack.title,
                  tileImages: stack.entries.map((libraryEntry) =>
                      '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg'),
                  onExpand: () => context.pushNamed('games',
                      queryParameters: stack.filter.params()),
                ),
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
