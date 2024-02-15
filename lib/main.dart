import 'package:espy/firebase_options.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/failed_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/modules/models/user_data_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
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

  FirebaseUIAuth.configureProviders([
    GoogleProvider(
        clientId:
            '478783154654-gq2jbr76gn0eggo0i71ak51bu9l3q7q5.apps.googleusercontent.com'),
  ]);

  runApp(MultiProvider(
    providers: [
      appConfigProvider(),
      frontpageProvider(),
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

ChangeNotifierProvider<TimelineModel> frontpageProvider() =>
    ChangeNotifierProvider(create: (_) => TimelineModel()..load());

ChangeNotifierProvider<UserModel> userProvider() =>
    ChangeNotifierProvider(create: (_) => UserModel());

ChangeNotifierProvider<LibraryFilterModel> libraryFilterProvider() =>
    ChangeNotifierProvider(create: (_) => LibraryFilterModel());

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
          libraryModel,
          wishlistModel,
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

ChangeNotifierProxyProvider6<
    AppConfigModel,
    GameTagsModel,
    UserLibraryModel,
    WishlistModel,
    RemoteLibraryModel,
    LibraryFilterModel,
    LibraryViewModel> libraryEntriesProvider() {
  return ChangeNotifierProxyProvider6<
      AppConfigModel,
      GameTagsModel,
      UserLibraryModel,
      WishlistModel,
      RemoteLibraryModel,
      LibraryFilterModel,
      LibraryViewModel>(
    create: (_) => LibraryViewModel(),
    update: (
      _,
      appConfigModel,
      gameTagsModel,
      userLibraryModel,
      wishlistModel,
      remoteLibraryModel,
      libraryFilterModel,
      libraryViewModel,
    ) {
      return libraryViewModel!
        ..update(
          appConfigModel,
          gameTagsModel,
          userLibraryModel,
          wishlistModel,
          remoteLibraryModel,
          libraryFilterModel,
        );
    },
  );
}

ChangeNotifierProxyProvider5<AppConfigModel, TimelineModel, UserLibraryModel,
    WishlistModel, GameTagsModel, HomeSlatesModel> homeSlatesProvider() {
  return ChangeNotifierProxyProvider5<AppConfigModel, TimelineModel,
      UserLibraryModel, WishlistModel, GameTagsModel, HomeSlatesModel>(
    create: (_) => HomeSlatesModel(),
    update: (
      _,
      appConfigModel,
      timelineModel,
      libraryModel,
      wishlistModel,
      gameTagsModel,
      homeSlatesModel,
    ) {
      return homeSlatesModel!
        ..update(
          appConfigModel,
          timelineModel,
          libraryModel,
          wishlistModel,
          gameTagsModel,
        );
    },
  );
}
