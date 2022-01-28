import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/game_tags.dart';
import 'package:flutter/material.dart';

class GameListCard extends StatelessWidget {
  GameListCard({
    required this.entry,
  });

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/details',
          arguments: entry.id,
        );
      },
      child: Container(
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl:
                      '${Urls.imageProvider}/t_cover_big/${entry.cover}.jpg',
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
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
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                            '${DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000).year}'),
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
                  Container(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (entry.collection != null)
                          Padding(
                            padding: const EdgeInsets.all(2),
                            child: CollectionChip(entry.collection!),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
