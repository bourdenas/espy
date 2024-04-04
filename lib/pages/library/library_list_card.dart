import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/widgets/game_pulse.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:espy/widgets/release_date_chip.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LibraryListCard extends StatelessWidget {
  const LibraryListCard({
    super.key,
    required this.libraryEntry,
  });

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final userModel = context.watch<UserModel>();

    return GestureDetector(
      onTap: () => context
          .pushNamed('details', pathParameters: {'gid': '${libraryEntry.id}'}),
      onSecondaryTap: () => userModel.isSignedIn
          ? EditEntryDialog.show(context, libraryEntry, gameId: libraryEntry.id)
          : null,
      onLongPress: () => userModel.isSignedIn
          ? isMobile
              ? context.pushNamed('edit',
                  pathParameters: {'gid': '${libraryEntry.id}'})
              : EditEntryDialog.show(
                  context,
                  libraryEntry,
                  gameId: libraryEntry.id,
                )
          : null,
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            coverImage(),
            const SizedBox(width: 16.0),
            cardInfo(context),
          ],
        ),
      ),
    );
  }

  Widget coverImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: CachedNetworkImage(
        imageUrl: '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget cardInfo(BuildContext context) {
    return Flexible(
      flex: 1,
      fit: FlexFit.tight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8.0),
          Text(
            libraryEntry.name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
          ),
          const SizedBox(height: 4.0),
          SizedBox(
            height: 42,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: [
                ReleaseDateChip(libraryEntry),
                const SizedBox(width: 16.0),
                GamePulse(libraryEntry, null),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          GameCardChips(
            libraryEntry: libraryEntry,
            includeCompanies: false,
            includeCollections: false,
          ),
        ],
      ),
    );
  }
}
