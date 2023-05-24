import 'package:espy/firebase_options.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/failed_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/modules/models/user_data_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:espy/pages/espy_app.dart'
    if (dart.library.js) 'package:espy/pages/espy_app_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // NOTE: Bug in the Firebase library. Adding the name attibute fails to connect.
    // name: 'espy',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppConfigModel()..loadLocalPref()),
      ChangeNotifierProvider(create: (_) => UserDataModel()),
      ChangeNotifierProvider(create: (_) => LibraryFilterModel()),
      ChangeNotifierProxyProvider<UserDataModel, UserLibraryModel>(
        create: (_) => UserLibraryModel(),
        update: (_, userDataModel, model) =>
            model!..update(userDataModel.userData),
      ),
      ChangeNotifierProxyProvider<UserDataModel, FailedModel>(
        create: (_) => FailedModel(),
        update: (_, userDataModel, model) =>
            model!..update(userDataModel.userData),
      ),
      ChangeNotifierProxyProvider<UserDataModel, WishlistModel>(
        create: (_) => WishlistModel(),
        update: (_, userDataModel, model) =>
            model!..update(userDataModel.userData),
      ),
      ChangeNotifierProxyProvider2<UserLibraryModel, WishlistModel,
          GameTagsModel>(
        create: (_) => GameTagsModel(),
        update: (_, libraryModel, wishlistModel, model) {
          return model!
            ..update(
              libraryModel.userId,
              libraryModel.entries,
              wishlistModel.wishlist,
            );
        },
      ),
      ChangeNotifierProxyProvider3<UserLibraryModel, WishlistModel,
          GameTagsModel, LibraryEntriesModel>(
        create: (_) => LibraryEntriesModel(),
        update: (_, userLibraryModel, wishlistModel, gameTagsModel, model) {
          return model!..update(userLibraryModel, wishlistModel, gameTagsModel);
        },
      ),
      ChangeNotifierProxyProvider4<LibraryEntriesModel, WishlistModel,
          GameTagsModel, AppConfigModel, HomeSlatesModel>(
        create: (_) => HomeSlatesModel(),
        update: (_, gameEntriesModel, wishlistModel, gameTagsModel,
            appConfigModel, model) {
          return model!
            ..update(
              gameEntriesModel,
              wishlistModel,
              gameTagsModel,
              appConfigModel,
            );
        },
      ),
    ],
    child: const EspyApp(),
  ));
}
