import 'package:espy/firebase_options.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/unmatched_library_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:espy/pages/espy_app.dart'
    if (dart.library.js) 'package:espy/pages/espy_app_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppConfigModel()..loadLocalPref()),
      ChangeNotifierProvider(create: (_) => UserModel()),
      // ChangeNotifierProxyProvider<UserModel, GameLibraryModel>(
      //   create: (_) => GameLibraryModel(),
      //   update: (_, userModel, model) {
      //     if (userModel.signedIn) {
      //       return model!..update(userModel.userData);
      //     }
      //     return model!;
      //   },
      // ),
      ChangeNotifierProxyProvider<GameLibraryModel, GameEntriesModel>(
        create: (_) => GameEntriesModel(),
        update: (_, libraryModel, model) {
          return model!..update(libraryModel.entries);
        },
      ),
      ChangeNotifierProxyProvider<GameLibraryModel, GameTagsModel>(
        create: (_) => GameTagsModel(),
        update: (_, libraryModel, model) {
          return model!..update(libraryModel.entries);
        },
      ),
      ChangeNotifierProxyProvider<UserModel, UnmatchedLibraryModel>(
        create: (_) => UnmatchedLibraryModel(),
        update: (_, userModel, model) {
          return model!..update(userModel.user.uid);
        },
      ),
      ChangeNotifierProxyProvider<UnmatchedLibraryModel, UnmatchedEntriesModel>(
        create: (_) => UnmatchedEntriesModel(),
        update: (_, unmatchedLibraryModel, model) {
          return model!..update(unmatchedLibraryModel, '');
        },
      ),
    ],
    child: EspyApp(),
  ));
}
