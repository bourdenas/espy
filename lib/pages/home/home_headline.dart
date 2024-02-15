import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeHeadline extends StatelessWidget {
  const HomeHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<WishlistModel>().entries;

    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 480.0,
          viewportFraction: 0.8,
          enlargeCenterPage: true,
          onPageChanged: (index, reason) {},
        ),
        items: [
          for (final entry in entries.take(16))
            GestureDetector(
              onTap: () => context
                  .pushNamed('details', pathParameters: {'gid': '${entry.id}'}),
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
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 16.0,
                ),
                const SizedBox(width: 4.0),
                Text(
                  'wishlisted'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _fadeShader(Widget child) {
    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
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
