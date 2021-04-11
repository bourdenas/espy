import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:espy/widgets/espy_app.dart'
    if (dart.library.js) 'package:espy/widgets/espy_app_web.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) {
          final model = GameLibraryModel();
          model.fetch();
          return model;
        },
      ),
      ChangeNotifierProvider(create: (context) => EspyRouterDelegate()),
    ],
    child: EspyApp(),
  ));
}
