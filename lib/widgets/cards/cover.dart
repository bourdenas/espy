import 'package:espy/constants/urls.dart';
import 'package:flutter/material.dart';

class CardCover extends StatelessWidget {
  const CardCover({
    super.key,
    this.cover,
    this.grayedOut = false,
    this.overlays = const [],
  });

  final String? cover;
  final bool grayedOut;
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          cover != null
              ? !grayedOut
                  ? Image.network(
                      '${Urls.imageProvider}/t_cover_big/$cover.jpg')
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child: Image.network(
                          '${Urls.imageProvider}/t_cover_big/$cover.jpg'),
                    )
              : const Center(
                  child: Icon(Icons.question_mark),
                ),
          ...overlays
        ],
      ),
    );
  }
}
