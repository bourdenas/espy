import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/unresolved.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CandidatesList extends StatelessWidget {
  const CandidatesList(this.unresolved, {super.key});

  final Unresolved unresolved;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: SizedBox(
        height: AppConfigModel.gridCardContraints.maxCardWidth /
            AppConfigModel.gridCardContraints.cardAspectRatio,
        child: Row(
          children: [
            SizedBox(
              width: AppConfigModel.gridCardContraints.maxCardWidth,
              child: ListTile(
                title: Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(unresolved.storeEntry.title),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TileCarousel(
                tiles: [
                  for (final digest in unresolved.candidates)
                    TileData(
                      title: digest.name,
                      subtitle: '${digest.release.year}',
                      image: digest.cover != null
                          ? '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg'
                          : null,
                      onTap: () => context.pushNamed('details',
                          pathParameters: {'gid': '${digest.id}'}),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
