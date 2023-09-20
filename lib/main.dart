import 'package:espy/firebase_options.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/failed_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:espy/modules/models/user_data_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:espy/pages/espy_app.dart'
    if (dart.library.js) 'package:espy/pages/espy_app_web.dart';

Future<void> main() async {
  // usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // NOTE: Bug in the Firebase library. Adding the name attibute fails to connect.
    // name: 'espy',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MultiProvider(
    providers: [
      appConfigProvider(),
      userProvider(),
      userLibraryProvider(),
      failedMatchesProvider(),
      wishlistProvider(),
      gameTagsProvider(),
      userDataProvider(),
      libraryFilterProvider(),
      remoteLibraryProvider(),
      libraryEntriesProvider(),
      homeSlatesProvider(),
    ],
    child: const EspyApp(),
  ));
}

ChangeNotifierProvider<AppConfigModel> appConfigProvider() =>
    ChangeNotifierProvider(create: (_) => AppConfigModel()..loadLocalPref());

ChangeNotifierProvider<UserModel> userProvider() =>
    ChangeNotifierProvider(create: (_) => UserModel());

ChangeNotifierProxyProvider<UserModel, UserLibraryModel> userLibraryProvider() {
  return ChangeNotifierProxyProvider<UserModel, UserLibraryModel>(
    create: (_) => UserLibraryModel(),
    update: (
      _,
      userModel,
      userLibraryModel,
    ) =>
        userLibraryModel!..update(userModel.userData),
  );
}

ChangeNotifierProxyProvider<UserModel, FailedModel> failedMatchesProvider() {
  return ChangeNotifierProxyProvider<UserModel, FailedModel>(
    create: (_) => FailedModel(),
    update: (
      _,
      userModel,
      failedModel,
    ) =>
        failedModel!..update(userModel.userData),
  );
}

ChangeNotifierProxyProvider<UserModel, WishlistModel> wishlistProvider() {
  return ChangeNotifierProxyProvider<UserModel, WishlistModel>(
    create: (_) => WishlistModel(),
    update: (
      _,
      userModel,
      wishlistModel,
    ) =>
        wishlistModel!..update(userModel.userData),
  );
}

ChangeNotifierProxyProvider2<UserLibraryModel, WishlistModel, GameTagsModel>
    gameTagsProvider() {
  return ChangeNotifierProxyProvider2<UserLibraryModel, WishlistModel,
      GameTagsModel>(
    create: (_) => GameTagsModel(),
    update: (
      _,
      libraryModel,
      wishlistModel,
      gameTagsModel,
    ) {
      return gameTagsModel!
        ..update(
          libraryModel.userId,
          libraryModel.entries,
          wishlistModel.wishlist,
        );
    },
  );
}

ChangeNotifierProxyProvider<UserModel, UserDataModel> userDataProvider() {
  return ChangeNotifierProxyProvider<UserModel, UserDataModel>(
    create: (_) => UserDataModel(),
    update: (
      _,
      userModel,
      userDataModel,
    ) {
      return userDataModel!..update(userModel.userId);
    },
  );
}

ChangeNotifierProxyProvider<AppConfigModel, LibraryFilterModel>
    libraryFilterProvider() {
  return ChangeNotifierProxyProvider<AppConfigModel, LibraryFilterModel>(
    create: (_) => LibraryFilterModel(),
    update: (_, appConfig, libraryFilterModel) =>
        libraryFilterModel!..update(appConfig),
  );
}

ChangeNotifierProxyProvider2<AppConfigModel, LibraryFilterModel,
    RemoteLibraryModel> remoteLibraryProvider() {
  return ChangeNotifierProxyProvider2<AppConfigModel, LibraryFilterModel,
      RemoteLibraryModel>(
    create: (_) => RemoteLibraryModel(),
    update: (
      _,
      appConfig,
      libraryFilter,
      remoteLibraryModel,
    ) =>
        remoteLibraryModel!..update(appConfig, libraryFilter.filter),
  );
}

ChangeNotifierProxyProvider5<
    AppConfigModel,
    UserLibraryModel,
    WishlistModel,
    GameTagsModel,
    RemoteLibraryModel,
    LibraryEntriesModel> libraryEntriesProvider() {
  return ChangeNotifierProxyProvider5<AppConfigModel, UserLibraryModel,
      WishlistModel, GameTagsModel, RemoteLibraryModel, LibraryEntriesModel>(
    create: (_) => LibraryEntriesModel(),
    update: (
      _,
      appConfigModel,
      userLibraryModel,
      wishlistModel,
      gameTagsModel,
      remoteLibraryModel,
      libraryEntriesModel,
    ) {
      return libraryEntriesModel!
        ..update(appConfigModel, userLibraryModel, wishlistModel, gameTagsModel,
            remoteLibraryModel);
    },
  );
}

ChangeNotifierProxyProvider4<LibraryEntriesModel, WishlistModel, GameTagsModel,
    AppConfigModel, HomeSlatesModel> homeSlatesProvider() {
  return ChangeNotifierProxyProvider4<LibraryEntriesModel, WishlistModel,
      GameTagsModel, AppConfigModel, HomeSlatesModel>(
    create: (_) => HomeSlatesModel(),
    update: (
      _,
      gameEntriesModel,
      wishlistModel,
      gameTagsModel,
      appConfigModel,
      homeSlatesModel,
    ) {
      return homeSlatesModel!
        ..update(
          gameEntriesModel,
          wishlistModel,
          gameTagsModel,
          appConfigModel,
        );
    },
  );
}
