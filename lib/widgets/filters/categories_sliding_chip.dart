import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/filters/sliding_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesSlidingChip extends StatelessWidget {
  const CategoriesSlidingChip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SlidingChip(
      label: 'Categories',
      color: Theme.of(context).colorScheme.onSecondaryContainer,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      initialOpen: true,
      expansion: const GameCategoryFilter(),
    );
  }
}

class GameCategoryFilter extends StatelessWidget {
  const GameCategoryFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();
    return Row(
      children: [
        CategoryFilterChip('Main Games', appConfig.showMains),
        const SizedBox(width: 8),
        CategoryFilterChip('Expansions', appConfig.showExpansions),
        const SizedBox(width: 8),
        CategoryFilterChip('Remakes', appConfig.showRemakes),
        const SizedBox(width: 8),
        CategoryFilterChip('Early Access', appConfig.showEarlyAccess),
        const SizedBox(width: 8),
        CategoryFilterChip('DLCs', appConfig.showDlcs),
        const SizedBox(width: 8),
        CategoryFilterChip('Versions', appConfig.showVersions),
        const SizedBox(width: 8),
        CategoryFilterChip('Bundles', appConfig.showBundles),
        const SizedBox(width: 8),
        CategoryFilterChip('Casual', appConfig.showCasual),
        const SizedBox(width: 8),
      ],
    );
  }
}

class CategoryFilterChip extends StatelessWidget {
  const CategoryFilterChip(
    this.label,
    this.option, {
    super.key,
  });

  final String label;
  final BoolOption option;

  @override
  Widget build(BuildContext context) {
    final appConfig = context.read<AppConfigModel>();
    return GestureDetector(
      onSecondaryTap: () {
        appConfig.showMains.value = false;
        appConfig.showExpansions.value = false;
        appConfig.showRemakes.value = false;
        appConfig.showEarlyAccess.value = false;
        appConfig.showDlcs.value = false;
        appConfig.showVersions.value = false;
        appConfig.showBundles.value = false;
        appConfig.showCasual.value = false;
        option.value = true;
      },
      child: ChoiceChip(
        label: SizedBox(width: 82, child: Text(label)),
        selected: option.value,
        onSelected: (selected) => option.value = selected,
      ),
    );
  }
}
