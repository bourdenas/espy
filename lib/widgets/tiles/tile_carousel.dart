import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TileData {
  const TileData({this.title, this.image, this.onTap, this.onLongTap});

  final String? title;
  final String? image;
  final VoidCallback? onTap;
  final VoidCallback? onLongTap;
}

class TileSize {
  const TileSize({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;
}

class TileCarousel extends StatefulWidget {
  final String? title;
  final VoidCallback? onTitleTap;
  final List<TileData> tiles;
  final TileSize tileSize;

  const TileCarousel({
    super.key,
    this.title,
    this.onTitleTap,
    required this.tiles,
    this.tileSize = const TileSize(width: 227.0, height: 320.0),
  });

  @override
  State<TileCarousel> createState() => _TileCarouselState();
}

class _TileCarouselState extends State<TileCarousel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.title != null)
          _CarouselHeader(
            titleText: widget.title!,
            onTitleTap: widget.onTitleTap,
            scrollController: _scrollController,
          ),
        carousel(context),
      ],
    );
  }

  Widget carousel(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: SizedBox(
        height: widget.tileSize.height,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: widget.tiles.length,
          itemBuilder: (context, index) {
            return _Tile(
              data: widget.tiles[index],
              tileSize: widget.tileSize,
            );
          },
        ),
      ),
    );
  }

  final ScrollController _scrollController = ScrollController();
}

class _CarouselHeader extends StatelessWidget {
  const _CarouselHeader({
    Key? key,
    required this.titleText,
    this.onTitleTap,
    required ScrollController scrollController,
  })  : _scrollController = scrollController,
        super(key: key);

  final String titleText;
  final VoidCallback? onTitleTap;
  final ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          title(context),
          slideControllers(),
        ],
      ),
    );
  }

  Widget title(BuildContext context) {
    return InkWell(
      onTap: onTitleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 2.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          titleText,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }

  Widget slideControllers() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            _scrollController.animateTo(
              _scrollController.offset - 400.0,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
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
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.arrow_forward_ios, size: 16.0),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    Key? key,
    required this.data,
    required this.tileSize,
  }) : super(key: key);

  final TileData data;
  final TileSize tileSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: data.onTap,
        onSecondaryTap: data.onLongTap,
        onLongPress: data.onLongTap,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          child: Stack(
            children: [
              if (data.image != null)
                Center(
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: data.image!,
                    placeholder: (context, url) => Container(),
                    errorWidget: (context, url, error) =>
                        const Center(child: Icon(Icons.error_outline)),
                  ),
                )
              else
                SizedBox(
                  width: tileSize.width,
                  child: Container(),
                ),
              if (data.title != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: tileSize.width,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(data.title!),
                      ),
                    ),
                  ],
                ),
              if (data.image == null && data.title == null)
                _PlaceholderShimmer(tileSize),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderShimmer extends StatelessWidget {
  const _PlaceholderShimmer(
    this.tileSize, {
    Key? key,
  }) : super(key: key);

  final TileSize tileSize;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: Container(
        height: tileSize.height,
        width: tileSize.width,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
