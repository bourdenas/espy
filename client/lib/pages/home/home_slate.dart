import 'package:animate_do/animate_do.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:flutter/material.dart';

class HomeSlate extends StatefulWidget {
  final String title;
  final VoidCallback? onExpand;
  final List<SlateTileData> tiles;

  const HomeSlate({
    Key? key,
    required this.title,
    this.onExpand,
    required this.tiles,
  }) : super(key: key);

  @override
  State<HomeSlate> createState() => _HomeSlateState();
}

class _HomeSlateState extends State<HomeSlate> {
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
            onTap: widget.onExpand,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  _scrollController.animateTo(
                    _scrollController.offset - 400.0,
                    curve: Curves.easeOut,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_back_ios, size: 16.0),
                ),
              ),
              InkWell(
                onTap: () {
                  _scrollController.animateTo(
                    _scrollController.offset + 400.0,
                    curve: Curves.easeOut,
                    duration: const Duration(milliseconds: 300),
                  );
                },
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
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: widget.tiles.length,
          itemBuilder: (context, index) {
            return SlateTile(data: widget.tiles[index]);
          },
        ),
      ),
    );
  }

  ScrollController _scrollController = new ScrollController();
}
