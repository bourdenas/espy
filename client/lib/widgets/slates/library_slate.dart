import 'package:animate_do/animate_do.dart';
import 'package:espy/widgets/slates/slate_tile.dart';
import 'package:flutter/material.dart';

class LibrarySlate extends StatelessWidget {
  final String text;
  final Function() onExpand;
  final List<SlateTileData> tiles;

  const LibrarySlate({
    Key? key,
    required this.text,
    required this.onExpand,
    required this.tiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        header(context),
        carousel(),
      ],
    );
  }

  Widget carousel() {
    return FadeIn(
      duration: Duration(milliseconds: 500),
      child: Container(
        height: 170.0,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            return SlateTile(data: tiles[index]);
          },
        ),
      ),
    );
  }

  Widget header(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: Theme.of(context).textTheme.headline6),
          InkWell(
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text('Expand'),
                  Icon(Icons.arrow_forward_ios, size: 16.0)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
