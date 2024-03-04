import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_tags.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/modules/models/tags/genre_tag_manager.dart';
import 'package:espy/modules/models/tags/label_manager.dart';
import 'package:espy/modules/models/tags/user_tag_manager.dart';
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
  GenreTagManager _genreTagsManager =
      GenreTagManager('', UserTags(), (_) => null);
  UserTagManager _userTagsManager = UserTagManager('', UserTags(), (_) => null);

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

  void update(
    String userId,
    LibraryIndexModel indexModel,
  ) async {
    _indexModel = indexModel;

    final entries = indexModel.entries;
    _storesManager = LabelManager(
      entries,
      (entry) => entry.storeEntries.map((store) => store.storefront),
      _getEntryById,
    );
    _developersManager = LabelManager(
      entries,
      (entry) => entry.digest.developers,
      _getEntryById,
    );
    _publishersManager = LabelManager(
      entries,
      (entry) => entry.digest.publishers,
      _getEntryById,
    );
    _collectionsManager = LabelManager(
      entries,
      (entry) => entry.digest.collections,
      _getEntryById,
    );
    _franchisesManager = LabelManager(
      entries,
      (entry) => entry.digest.franchises,
      _getEntryById,
    );
    _genresManager = LabelManager(
      entries,
      (entry) => entry.digest.genres,
      _getEntryById,
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
      _genreTagsManager = GenreTagManager(_userId, userTags, _getEntryById)
        ..build();
      _userTagsManager = UserTagManager(_userId, userTags, _getEntryById)
        ..build();
      notifyListeners();
    });
  }

  late LibraryIndexModel _indexModel;
  LibraryEntry? _getEntryById(int id) => _indexModel.getEntryById(id);
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
