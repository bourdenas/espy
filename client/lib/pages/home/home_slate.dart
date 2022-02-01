import 'package:animate_do/animate_do.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:flutter/material.dart';

class HomeSlate extends StatelessWidget {
  final String title;
  final Function() onExpand;
  final List<SlateTileData> tiles;

  const HomeSlate({
    Key? key,
    required this.title,
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

  Widget header(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onExpand,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_back_ios, size: 16.0),
                ),
              ),
              InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_forward_ios, size: 16.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget carousel() {
    return FadeIn(
      duration: Duration(milliseconds: 500),
      child: Container(
        height: 170.0,
        child: ListView.builder(
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
}
