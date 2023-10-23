import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LibraryListCard extends StatelessWidget {
  const LibraryListCard({
    Key? key,
    required this.libraryEntry,
  }) : super(key: key);

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);

    return GestureDetector(
      onTap: () => context
          .pushNamed('details', pathParameters: {'gid': '${libraryEntry.id}'}),
      onSecondaryTap: () =>
          EditEntryDialog.show(context, libraryEntry, gameId: libraryEntry.id),
      onLongPress: () => isMobile
          ? context
              .pushNamed('edit', pathParameters: {'gid': '${libraryEntry.id}'})
          : EditEntryDialog.show(context, libraryEntry,
              gameId: libraryEntry.id),
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
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget cardInfo(BuildContext context) {
    final rating = libraryEntry.rating;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  libraryEntry.digest.formatReleaseDate(),
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 18.0,
              ),
              const SizedBox(width: 4.0),
              Text(
                rating > 0 ? (rating / 20.0).toStringAsFixed(1) : '--',
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          GameCardChips(
            libraryEntry: libraryEntry,
            includeCompanies: true,
          ),
        ],
      ),
    );
  }
}
