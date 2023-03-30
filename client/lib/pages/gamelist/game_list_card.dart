import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameListCard extends StatelessWidget {
  GameListCard({
    Key? key,
    required this.libraryEntry,
  }) : super(key: key);

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);

    return GestureDetector(
      onTap: () =>
          context.pushNamed('details', params: {'gid': '${libraryEntry.id}'}),
      onSecondaryTap: () =>
          EditEntryDialog.show(context, libraryEntry, gameId: libraryEntry.id),
      onLongPress: () => isMobile
          ? context.pushNamed('edit', params: {'gid': '${libraryEntry.id}'})
          : EditEntryDialog.show(context, libraryEntry,
              gameId: libraryEntry.id),
      child: Container(
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            coverImage(),
            SizedBox(width: 16.0),
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
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Icon(Icons.error),
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
          Text(
            libraryEntry.name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headline6,
            maxLines: 1,
          ),
          SizedBox(height: 4.0),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                    '${DateTime.fromMillisecondsSinceEpoch(libraryEntry.releaseDate * 1000).year}'),
              ),
              SizedBox(width: 16.0),
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 18.0,
              ),
              SizedBox(width: 4.0),
              Text('4.3'),
            ],
          ),
          SizedBox(height: 16.0),
          GameCardChips(libraryEntry: libraryEntry),
        ],
      ),
    );
  }
}
