import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:espy/pages/home/home_headline.dart';
import 'package:espy/widgets/tiles/tile_stack.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HomeSlatesModel>();
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
                  onExpand: () => updateLibraryView(context, stack.filter),
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
