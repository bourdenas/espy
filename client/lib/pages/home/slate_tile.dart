import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SlateTileData {
  const SlateTileData({this.title, this.image, this.onTap});

  final String? title;
  final String? image;
  final VoidCallback? onTap;
}

class SlateTile extends StatelessWidget {
  const SlateTile({
    Key? key,
    required this.data,
  }) : super(key: key);

  final SlateTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: data.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          child: Stack(
            children: [
              if (data.image != null)
                CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: data.image!,
                  placeholder: (context, url) => PlaceholderShimmer(),
                  errorWidget: (context, url, error) =>
                      Center(child: Icon(Icons.help_outline)),
                )
              else
                SizedBox(
                    width: 120,
                    child: Center(
                      child: Icon(Icons.help_outline),
                    )),
              if (data.title != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 120,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(data.title!),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderShimmer extends StatelessWidget {
  const PlaceholderShimmer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      child: Container(
        height: 170.0,
        width: 120.0,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
    );
  }
}
