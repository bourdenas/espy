import 'package:espy/firebase_options.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/calendar_model.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/unresolved_model.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/modules/models/user_data_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/modules/models/years_model.dart';
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
      calendarProvider(),
      yearsProvider(),
      customViewProvider(),
      userProvider(),
      userLibraryProvider(),
      libraryIndexProvider(),
      failedMatchesProvider(),
      wishlistProvider(),
      gameTagsProvider(),
      userDataProvider(),
      libraryFilterProvider(),
      refinementProvider(),
      libraryEntriesProvider(),
      homeSlatesProvider(),
    ],
    child: const EspyApp(),
  ));
}

ChangeNotifierProvider<AppConfigModel> appConfigProvider() =>
    ChangeNotifierProvider(create: (_) => AppConfigModel()..loadLocalPref());

ChangeNotifierProvider<FrontpageModel> frontpageProvider() =>
    ChangeNotifierProvider(create: (_) => FrontpageModel()..load());

ChangeNotifierProvider<CalendarModel> calendarProvider() =>
    ChangeNotifierProvider(create: (_) => CalendarModel());

ChangeNotifierProvider<YearsModel> yearsProvider() =>
    ChangeNotifierProvider(create: (_) => YearsModel());

ChangeNotifierProvider<CustomViewModel> customViewProvider() =>
    ChangeNotifierProvider(create: (_) => CustomViewModel());

ChangeNotifierProvider<UserModel> userProvider() =>
    ChangeNotifierProvider(create: (_) => UserModel());

ChangeNotifierProvider<LibraryFilterModel> libraryFilterProvider() =>
    ChangeNotifierProvider(create: (_) => LibraryFilterModel());

ChangeNotifierProvider<RefinementModel> refinementProvider() =>
    ChangeNotifierProvider(create: (_) => RefinementModel());

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

ChangeNotifierProxyProvider<UserLibraryModel, LibraryIndexModel>
    libraryIndexProvider() {
  return ChangeNotifierProxyProvider<UserLibraryModel, LibraryIndexModel>(
    create: (_) => LibraryIndexModel(),
    update: (
      _,
      libraryModel,
      libraryIndexModel,
    ) =>
        libraryIndexModel!..update(libraryModel.all),
  );
}

ChangeNotifierProxyProvider<UserModel, UnresolvedModel>
    failedMatchesProvider() {
  return ChangeNotifierProxyProvider<UserModel, UnresolvedModel>(
    create: (_) => UnresolvedModel(),
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

ChangeNotifierProxyProvider2<UserModel, LibraryIndexModel, GameTagsModel>
    gameTagsProvider() {
  return ChangeNotifierProxyProvider2<UserModel, LibraryIndexModel,
      GameTagsModel>(
    create: (_) => GameTagsModel(),
    update: (
      _,
      userModel,
      libraryIndexModel,
      gameTagsModel,
    ) {
      return gameTagsModel!
        ..update(
          userModel.userId,
          libraryIndexModel,
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

ChangeNotifierProxyProvider3<AppConfigModel, LibraryIndexModel, CustomViewModel,
    LibraryViewModel> libraryEntriesProvider() {
  return ChangeNotifierProxyProvider3<AppConfigModel, LibraryIndexModel,
      CustomViewModel, LibraryViewModel>(
    create: (_) => LibraryViewModel(),
    update: (
      _,
      appConfigModel,
      libraryIndexModel,
      customViewModel,
      libraryViewModel,
    ) {
      return libraryViewModel!
        ..update(
          appConfigModel,
          libraryIndexModel,
          customViewModel,
        );
    },
  );
}

ChangeNotifierProxyProvider4<AppConfigModel, UserLibraryModel, WishlistModel,
    GameTagsModel, HomeSlatesModel> homeSlatesProvider() {
  return ChangeNotifierProxyProvider4<AppConfigModel, UserLibraryModel,
      WishlistModel, GameTagsModel, HomeSlatesModel>(
    create: (_) => HomeSlatesModel(),
    update: (
      _,
      appConfigModel,
      libraryModel,
      wishlistModel,
      gameTagsModel,
      homeSlatesModel,
    ) {
      return homeSlatesModel!
        ..update(
          appConfigModel,
          libraryModel,
          wishlistModel,
          gameTagsModel,
        );
    },
  );
}
