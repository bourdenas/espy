import 'package:espy/proto/library.pb.dart';
import 'package:espy/widgets/game_details.dart' show GameDetails;
import 'package:flutter/material.dart';

class GameDetailsPage extends Page {
  final GameEntry entry;

  GameDetailsPage({required this.entry}) : super(key: ValueKey(entry));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) {
        return GameDetails(entry: entry);
      },
    );
  }
}
