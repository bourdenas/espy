import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageDialog extends StatelessWidget {
  const ImageDialog({
    super.key,
    required this.imageUrl,
    this.scale = 1,
  });

  final String imageUrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(2),
      title: CachedNetworkImage(
        scale: scale,
        fit: BoxFit.cover,
        imageUrl: imageUrl,
        placeholder: (context, url) => Container(),
        errorWidget: (context, url, error) =>
            const Center(child: Icon(Icons.error_outline)),
      ),
    );
  }
}
