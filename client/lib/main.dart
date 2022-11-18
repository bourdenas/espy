import 'package:espy/firebase_options.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/modules/models/failed_entries_model.dart';
import 'package:espy/modules/models/user_data_model.dart';
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
      ChangeNotifierProvider(create: (_) => UserDataModel()),
      ChangeNotifierProxyProvider<UserDataModel, GameLibraryModel>(
        create: (_) => GameLibraryModel(),
        update: (_, userDataModel, model) =>
            model!..update(userDataModel.userData),
      ),
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
      ChangeNotifierProxyProvider2<GameLibraryModel, GameTagsModel,
          HomeSlatesModel>(
        create: (_) => HomeSlatesModel(),
        update: (_, libraryModel, gameTagsModel, model) {
          return model!..update(libraryModel.entries, gameTagsModel.tags);
        },
      ),
      ChangeNotifierProxyProvider<UserDataModel, FailedEntriesModel>(
        create: (_) => FailedEntriesModel(),
        update: (_, userDataModel, model) {
          if (userDataModel.userData != null) {
            return model!..update(userDataModel.userId);
          } else {
            return model!;
          }
        },
      ),
      ChangeNotifierProxyProvider<FailedEntriesModel, UnmatchedEntriesModel>(
        create: (_) => UnmatchedEntriesModel(),
        update: (_, unmatchedLibraryModel, model) {
          return model!..update(unmatchedLibraryModel, '');
        },
      ),
    ],
    child: EspyApp(),
  ));
}
