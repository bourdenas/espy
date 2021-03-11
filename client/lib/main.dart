import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/screens/espy_home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (_context) {
        final model = GameLibraryModel();
        model.fetch();
        return model;
      },
    ),
    ChangeNotifierProvider(create: (_context) => GameDetailsModel())
  ], child: const EspyApp()));
}

class EspyApp extends StatelessWidget {
  const EspyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'espy',
      theme: ThemeData.dark(),
      home: EspyHome(title: 'espy'),
    );
  }
}
