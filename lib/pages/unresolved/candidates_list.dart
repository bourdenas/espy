import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/unresolved.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';

class CandidatesList extends StatelessWidget {
  const CandidatesList(this.unresolved, {super.key});

  final Unresolved unresolved;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: SizedBox(
        height: AppConfigModel.gridCardContraints.maxCardWidth * 1.25 + 8,
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
                      image: digest.cover != null
                          ? '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg'
                          : null,
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
