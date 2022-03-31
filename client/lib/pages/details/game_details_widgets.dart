import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/home/home_slate.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:flutter/material.dart';

class GameEntryActionBar extends StatelessWidget {
  const GameEntryActionBar({
    Key? key,
    required this.libraryEntry,
    required this.gameEntry,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            actionButtons(context),
            SizedBox(width: 16.0),
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 2.0,
                horizontal: 8.0,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '${DateTime.fromMillisecondsSinceEpoch(gameEntry.releaseDate * 1000).year}',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        linkButtons(context, gameEntry),
      ],
    );
  }

  Widget actionButtons(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => AppConfigModel.isMobile(context)
              ? Navigator.pushNamed(context, '/edit',
                  arguments: '${libraryEntry.id}')
              : EditEntryDialog.show(context, libraryEntry),
          icon: Icon(
            Icons.edit,
            size: 24.0,
          ),
          splashRadius: 20.0,
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.favorite_border_outlined,
            color: Colors.red,
            size: 24.0,
          ),
          splashRadius: 20.0,
        ),
      ],
    );
  }

  Widget linkButtons(BuildContext context, GameEntry gameEntry) {
    return Row(
      children: [
        for (final website in gameEntry.websites)
          if (website.authority != "Null" && website.authority != "Youtube")
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/web', arguments: website.url),
              icon: websiteIcon(website.authority),
              splashRadius: 20.0,
            )
      ],
    );
  }

  Widget websiteIcon(String website) {
    switch (website) {
      case "Official":
        return Icon(Icons.web);
      case "Wikipedia":
        return Image.asset('assets/images/wikipedia-128.png');
      case "Igdb":
        return Image.asset('assets/images/igdb-128.png');
      case "Gog":
        return Image.asset('assets/images/gog-128.png');
      case "Steam":
        return Image.asset('assets/images/steam-128.png');
      case "Egs":
        return Image.asset('assets/images/egs-128.png');
      case "Youtube":
        return Image.asset('assets/images/youtube-128.png');
    }
    return Icon(Icons.error);
  }
}

class GameEntryExpansions extends StatelessWidget {
  const GameEntryExpansions(this.gameEntry, {Key? key, this.idPath = const []})
      : super(key: key);

  final GameEntry gameEntry;
  final List<String> idPath;

  @override
  Widget build(BuildContext context) {
    return HomeSlate(
      title: 'Expansions & DLC',
      tiles: [gameEntry.expansions, gameEntry.dlcs]
          .expand((e) => e)
          .map((dlc) => SlateTileData(
                image: dlc.cover != null
                    ? '${Urls.imageProvider}/t_cover_big/${dlc.cover!.imageId}.jpg'
                    : null,
                title: dlc.cover == null ? dlc.name : null,
                onTap: () => Navigator.pushNamed(context, '/details',
                    arguments: [...idPath, dlc.id].join(',')),
              ))
          .toList(),
    );
  }
}

class GameEntryRemakes extends StatelessWidget {
  const GameEntryRemakes(this.gameEntry, {Key? key, this.idPath = const []})
      : super(key: key);

  final GameEntry gameEntry;
  final List<String> idPath;

  @override
  Widget build(BuildContext context) {
    return HomeSlate(
      title: 'Remakes',
      tiles: [gameEntry.remakes, gameEntry.remasters]
          .expand((e) => e)
          .map((remake) => SlateTileData(
                image: remake.cover != null
                    ? '${Urls.imageProvider}/t_cover_big/${remake.cover!.imageId}.jpg'
                    : null,
                title: remake.cover == null ? remake.name : null,
                onTap: () => Navigator.pushNamed(context, '/details',
                    arguments: [...idPath, remake.id].join(',')),
              ))
          .toList(),
    );
  }
}
