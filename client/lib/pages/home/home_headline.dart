import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class HomeHeadline extends StatelessWidget {
  const HomeHeadline({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameEntriesModel>().getEntries(null);

    return FadeIn(
      duration: Duration(milliseconds: 500),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 575.0,
          viewportFraction: 1.0,
          onPageChanged: (index, reason) {},
        ),
        items: [
          for (final entry in entries.take(8))
            GestureDetector(
              onTap: () {},
              child: Stack(
                children: [
                  _fadeShader(
                    CachedNetworkImage(
                      height: 560.0,
                      imageUrl:
                          '${Urls.imageProvider}/t_cover_big/${entry.cover}.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  _carouselLabel(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _carouselLabel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16.0,
                ),
                SizedBox(width: 4.0),
                Text(
                  'latest release'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _fadeShader(Widget child) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0, 0.3, 0.5, 1],
        ).createShader(
          Rect.fromLTRB(0, 0, rect.width, rect.height),
        );
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
