import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/failed_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/pages/home/home_slate.dart';
import 'package:espy/pages/home/home_stack.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:espy/widgets/empty_library.dart';
import 'package:espy/pages/home/home_headline.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/src/provider.dart';

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameEntriesModel>().getEntries();
    final unmatchedEntries = context.watch<FailedModel>().entries;

    return entries.isNotEmpty || unmatchedEntries.isNotEmpty
        ? library(context)
        : EmptyLibrary();
  }

  Widget library(BuildContext context) {
    final model = context.watch<HomeSlatesModel>();
    final slates =
        model.slates.where((slate) => slate.entries.isNotEmpty).toList();
    final stacks = model.stacks;
    final isMobile = AppConfigModel.isMobile(context);

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        if (isMobile)
          SliverToBoxAdapter(child: HomeHeadline())
        else
          SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final slate = slates[index];
              return HomeSlate(
                title: slate.title,
                onExpand: slate.filter != null
                    ? () => context.pushNamed('games',
                        queryParams: slate.filter!.params())
                    : null,
                tiles: slate.entries
                    .map((libraryEntry) => SlateTileData(
                          image:
                              '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
                          onTap: () => context.pushNamed('details',
                              params: {'gid': '${libraryEntry.id}'}),
                          onLongTap: () => isMobile
                              ? context.pushNamed('edit',
                                  params: {'gid': '${libraryEntry.id}'})
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
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  "Browse by genre",
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              SizedBox(height: 32),
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
                HomeStack(
                  title: stack.title,
                  onExpand: stack.filter != null
                      ? () => context.pushNamed('games',
                          queryParams: stack.filter!.params())
                      : null,
                  tiles: stack.entries.map(
                    (libraryEntry) => SlateTileData(
                      image:
                          '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
                      onTap: () => context.pushNamed('details',
                          params: {'gid': '${libraryEntry.id}'}),
                      onLongTap: () => isMobile
                          ? context.pushNamed('edit',
                              params: {'gid': '${libraryEntry.id}'})
                          : EditEntryDialog.show(
                              context,
                              libraryEntry,
                              gameId: libraryEntry.id,
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 32.0),
        ),

        // ,
      ],
    );
  }
}
