import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_tags.dart';
import 'package:espy/modules/models/tags/genre_tag_manager.dart';
import 'package:espy/modules/models/tags/label_manager.dart';
import 'package:espy/modules/models/tags/user_tag_manager.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:flutter/material.dart' show ChangeNotifier;

/// Index of tags extracted from user's library.
///
/// The index is computed on-the-fly in the client.
class GameTagsModel extends ChangeNotifier {
  String _userId = '';

  late LabelManager _storesManager;
  late LabelManager _developersManager;
  late LabelManager _publishersManager;
  late LabelManager _collectionsManager;
  late LabelManager _franchisesManager;
  late LabelManager _genresManager;
  late GenreTagManager _genreTagsManager;
  late UserTagManager _userTagsManager;

  LabelManager get stores => _storesManager;
  LabelManager get developers => _developersManager;
  LabelManager get publishers => _publishersManager;
  LabelManager get collections => _collectionsManager;
  LabelManager get franchises => _franchisesManager;
  LabelManager get genres => _genresManager;
  GenreTagManager get genreTags => _genreTagsManager;
  UserTagManager get userTags => _userTagsManager;

  List<String> get espyGenres => _genres;
  Iterable<String> filterEspyGenres(Iterable<String> genres) => genres
      .map((genre) => _IgdbToEspyGenres[genre])
      .where((e) => e != null)
      .cast<String>()
      .toSet();
  List<String>? espyGenreTags(String genre) => _genreTags[genre];

  late UserLibraryModel _libraryModel;
  late WishlistModel _wishlistModel;

  LibraryEntry? getEntryById(int id) =>
      _libraryModel.getEntryById(id) ?? _wishlistModel.getEntryById(id);

  void update(
    String userId,
    UserLibraryModel libraryModel,
    WishlistModel wishlistModel,
  ) async {
    _libraryModel = libraryModel;
    _wishlistModel = wishlistModel;

    final allEntries =
        [libraryModel.entries, wishlistModel.entries].expand((e) => e);
    _storesManager = LabelManager(
      allEntries,
      (entry) => entry.storeEntries.map((store) => store.storefront),
      getEntryById,
    );
    _developersManager = LabelManager(
      allEntries,
      (entry) => entry.digest.developers,
      getEntryById,
    );
    _publishersManager = LabelManager(
      allEntries,
      (entry) => entry.digest.publishers,
      getEntryById,
    );
    _collectionsManager = LabelManager(
      allEntries,
      (entry) => entry.digest.collections,
      getEntryById,
    );
    _franchisesManager = LabelManager(
      allEntries,
      (entry) => entry.digest.franchises,
      getEntryById,
    );
    _genresManager = LabelManager(
      allEntries,
      (entry) => entry.digest.genres,
      getEntryById,
    );

    if (userId.isNotEmpty && _userId != userId) {
      _userId = userId;
      _loadUserTags(userId);
    }
  }

  Future<void> _loadUserTags(String userId) async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('user_data')
        .doc('tags')
        .withConverter<UserTags>(
          fromFirestore: (snapshot, _) => UserTags.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<UserTags> snapshot) {
      final userTags = snapshot.data() ?? UserTags();
      _genreTagsManager = GenreTagManager(_userId, userTags, getEntryById)
        ..build();
      _userTagsManager = UserTagManager(_userId, userTags, getEntryById)
        ..build();
      notifyListeners();
    });
  }
}

const _genres = [
  'Adventure',
  'RPG',
  'Strategy',
  'Arcade',
  'Online',
  'Platformer',
  'Shooter',
  'Simulator',
];

const Map<String, String> _IgdbToEspyGenres = {
  'Point-and-click': 'Adventure',
  'Adventure': 'Adventure',
  'Pinball': 'Arcade',
  'Arcade': 'Arcade',
  'Fighting': 'Arcade',
  'Card & Board Game': 'Arcade',
  'MOBA': 'Online',
  'Platform': 'Platformer',
  'Role-playing (RPG)': 'RPG',
  'Shooter': 'Shooter',
  'Racing': 'Simulator',
  'Simulator': 'Simulator',
  'Sport': 'Simulator',
  'Real Time Strategy (RTS)': 'Strategy',
  'Strategy': 'Strategy',
  'Turn-based strategy (TBS)': 'Strategy',
  'Tactical  ': 'Strategy',
};

const Map<String, List<String>> _genreTags = {
  'Adventure': [
    'Point-and-Click',
    'Action',
    'First-Person Adventure',
    'Isometric Action',
    'Isometric Adventure',
    'Narrative Adventure',
    'Puzzle Adventure',
  ],
  'Arcade': [
    'Fighting',
    'Pinball',
    'Beat\'em Up',
    'Puzzle',
    'Tower Defense',
    'Endless Runner',
    'Card & Board Game',
  ],
  'Online': [
    'MMORPG',
    'MOBA',
    'Battle Royale',
    'Co-op',
    'PvP',
  ],
  'Platformer': [
    'Side-Scroller',
    'Metroidvania',
    '3D Platformer',
    'Shooter Platformer',
    'Puzzle Platformer',
  ],
  'RPG': [
    'Isometric RPG',
    'Turn-Based RPG',
    'RTwP RPG',
    'First-Person RPG',
    'Action RPG',
    'Hack & Slash',
    'JRPG',
  ],
  'Shooter': [
    'First Person Shooter',
    'Top-Down Shooter',
    '3rd Person Shooter',
    'Space Shooter',
    'Stealth Shooter',
    'First Person Melee',
  ],
  'Simulator': [
    'City Builder',
    'God Game',
    'Racing',
    'Sport',
    'Flight Simulator',
    'Management',
    'Survival',
  ],
  'Strategy': [
    'Turn-Based Strategy',
    'Real-Time Strategy',
    'Turn-Based Tactics',
    'Real-Time Tactics',
    'Isometric Tactics',
    'Grand Strategy',
    '4X',
  ],
};
