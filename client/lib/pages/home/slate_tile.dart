import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SlateTileData {
  const SlateTileData({this.title, this.image, this.onTap});

  final String? title;
  final String? image;
  final VoidCallback? onTap;
}

class SlateTileSize {
  static const mobileWidth = 120.0;
  static const mobileHeight = 170.0;

  static const desktopWidth = 227.1;
  static const desktopHeight = 320.0;

  static double width(bool isMobile) {
    return isMobile ? mobileWidth : desktopWidth;
  }

  static double height(bool isMobile) {
    return isMobile ? mobileHeight : desktopHeight;
  }
}

class SlateTile extends StatelessWidget {
  const SlateTile({
    Key? key,
    required this.data,
  }) : super(key: key);

  final SlateTileData data;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);

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
                  placeholder: (context, url) => Container(),
                  errorWidget: (context, url, error) =>
                      Center(child: Icon(Icons.error_outline)),
                )
              else
                SizedBox(
                  width: SlateTileSize.width(isMobile),
                  child: Container(),
                ),
              if (data.title != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: SlateTileSize.width(isMobile),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(data.title!),
                      ),
                    ),
                  ],
                ),
              if (data.image == null && data.title == null)
                PlaceholderShimmer(),
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
    final isMobile = AppConfigModel.isMobile(context);

    return Shimmer.fromColors(
      child: Container(
        height: SlateTileSize.height(isMobile),
        width: SlateTileSize.width(isMobile),
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
