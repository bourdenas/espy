import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/unresolved_model.dart';
import 'package:espy/pages/unresolved/unknown_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnknownListView extends StatelessWidget {
  const UnknownListView({super.key});

  @override
  Widget build(BuildContext context) {
    final unknowns = context.watch<UnresolvedModel>().unknown;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeInUp(
        from: 20,
        duration: const Duration(milliseconds: 500),
        child: GridView.extent(
          maxCrossAxisExtent: AppConfigModel.gridCardContraints.maxCardWidth,
          childAspectRatio: AppConfigModel.gridCardContraints.cardAspectRatio,
          padding: const EdgeInsets.all(4),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final unknown in unknowns) UnknownCard(unknown),
          ],
        ),
      ),
    );
  }
}
