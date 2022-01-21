import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LibrarySlate extends StatelessWidget {
  final String text;
  final Function() onExpand;

  const LibrarySlate({
    Key? key,
    required this.text,
    required this.onExpand,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                      Text('See More'),
                      Icon(Icons.arrow_forward_ios, size: 16.0)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        FadeIn(
          duration: Duration(milliseconds: 500),
          child: Container(
            height: 170.0,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: 16,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {},
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      child: CachedNetworkImage(
                        width: 120.0,
                        fit: BoxFit.cover,
                        imageUrl:
                            'https://images.igdb.com/igdb/image/upload/t_cover_big/co27az.jpg',
                        placeholder: (context, url) => Shimmer.fromColors(
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
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
