import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/widgets/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class GameDetailsPage extends StatelessWidget {
  const GameDetailsPage({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final libraryEntry = context.read<GameEntriesModel>().getEntryById(id);

    return Scaffold(
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('games').doc(id).get(),
        builder: (context, snapshot) {
          // if (snapshot.connectionState != ConnectionState.done) {}

          if (snapshot.hasError) {
            return Center(
                child: Text("Something went wrong: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasData) {
            return Center(child: Text("Document does not exist"));
          }

          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final jData = (snapshot.data! as DocumentSnapshot).data()
                as Map<String, dynamic>;
            final gameEntry = GameEntry.fromJson(jData);

            return GameDetailsContent(
              libraryEntry: libraryEntry!,
              gameEntry: gameEntry,
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class GameDetailsContent extends StatelessWidget {
  const GameDetailsContent({
    Key? key,
    required this.libraryEntry,
    required this.gameEntry,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: Key('gameDetailsScrollView'),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 250.0,
          flexibleSpace: FlexibleSpaceBar(
            background: FadeIn(
              duration: Duration(milliseconds: 500),
              child: _fadeShader(
                CachedNetworkImage(
                  width: MediaQuery.of(context).size.width,
                  imageUrl:
                      '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeInUp(
            from: 20,
            duration: Duration(milliseconds: 500),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameEntry.name,
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  SizedBox(height: 8.0),
                  subtitle(),
                  SizedBox(height: 16.0),
                  GameTags(libraryEntry),
                  SizedBox(height: 16.0),
                  Text(
                    gameEntry.summary,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Franchise: Foo, Bar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Row subtitle() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            vertical: 2.0,
            horizontal: 8.0,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            '${DateTime.fromMillisecondsSinceEpoch(gameEntry.releaseDate * 1000).year}',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 16.0),
        Row(
          children: [
            Icon(
              Icons.favorite_border_outlined,
              color: Colors.red,
              size: 24.0,
            ),
            SizedBox(width: 16.0),
            Container(
              child: Image.asset('assets/images/gog-128.png'),
              height: 24.0,
            ),
            SizedBox(width: 16.0),
            Container(
              child: Image.asset('assets/images/steam-128.png'),
              height: 24.0,
            ),
          ],
        ),
      ],
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
          stops: [0.0, 0.5, 1.0, 1.0],
        ).createShader(
          Rect.fromLTRB(0.0, 0.0, rect.width, rect.height),
        );
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
