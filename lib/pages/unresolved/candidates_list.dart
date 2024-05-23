import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/igdb_game.dart';
import 'package:espy/modules/documents/unresolved.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/widgets/cards/cover.dart';
import 'package:espy/widgets/cards/footers.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
                title: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      const CardCover(),
                      InfoTileBar(
                        unresolved.storeEntry.title,
                        stores: [unresolved.storeEntry.storefront],
                      ),
                    ],
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
                      overlay: Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton(
                          iconSize: 32,
                          hoverColor: Colors.green.withOpacity(0.5),
                          onPressed: () =>
                              context.read<UserLibraryModel>().matchEntry(
                                    unresolved.storeEntry,
                                    GameEntry(
                                      id: digest.id,
                                      name: digest.name,
                                      category: digest.category ?? '',
                                      igdbGame: const IgdbGame(id: 0, name: ''),
                                    ),
                                  ),
                          icon: const Icon(Icons.check_circle_outline),
                        ),
                      ),
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
