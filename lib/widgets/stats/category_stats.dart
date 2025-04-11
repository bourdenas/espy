import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/filters/categories_sliding_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryStats extends StatelessWidget {
  const CategoryStats({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CategoryFilterChip('Main Games', appConfig.showMains),
            const SizedBox(width: 8),
            CategoryFilterChip('Expansions', appConfig.showExpansions),
            const SizedBox(width: 8),
            CategoryFilterChip('Early Access', appConfig.showEarlyAccess),
            const SizedBox(width: 8),
            CategoryFilterChip('Versions', appConfig.showVersions),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CategoryFilterChip('Remakes', appConfig.showRemakes),
            const SizedBox(width: 8),
            CategoryFilterChip('DLCs', appConfig.showDlcs),
            const SizedBox(width: 8),
            CategoryFilterChip('Casual', appConfig.showCasual),
            const SizedBox(width: 8),
            CategoryFilterChip('Bundles', appConfig.showBundles),
          ],
        ),
      ],
    );
  }
}
