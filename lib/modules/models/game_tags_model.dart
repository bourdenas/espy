import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_annotations.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/modules/models/tags/manual_genre_manager.dart';
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
  late LabelManager _keywordsManager;
  ManualGenreManager _manualGenresManager =
      ManualGenreManager('', UserAnnotations(), (_) => null);
  UserTagManager _userTagsManager =
      UserTagManager('', UserAnnotations(), (_) => null);

  LabelManager get stores => _storesManager;
  LabelManager get developers => _developersManager;
  LabelManager get publishers => _publishersManager;
  LabelManager get collections => _collectionsManager;
  LabelManager get franchises => _franchisesManager;
  LabelManager get genres => _genresManager;
  LabelManager get keywords => _keywordsManager;
  ManualGenreManager get manualGenres => _manualGenresManager;
  UserTagManager get userTags => _userTagsManager;

  List<String> get genreGroups => _genreGroups;
  List<String>? espyGenreTags(String genreGroup) => _genreTags[genreGroup];
  String? getGenreGroup(String genre) => _groupMapping[genre];

  void update(
    String userId,
    LibraryIndexModel indexModel,
  ) async {
    if (_groupMapping.isEmpty) {
      for (final groupEntry in _genreTags.entries) {
        for (final genre in groupEntry.value) {
          _groupMapping[genre] = groupEntry.key;
        }
      }
    }

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
      (entry) => entry.digest.espyGenres,
      _getEntryById,
    );
    _keywordsManager = LabelManager(
      entries,
      (entry) => entry.digest.keywords,
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
        .withConverter<UserAnnotations>(
          fromFirestore: (snapshot, _) =>
              UserAnnotations.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<UserAnnotations> snapshot) {
      final userTags = snapshot.data() ?? UserAnnotations();
      _manualGenresManager =
          ManualGenreManager(_userId, userTags, _getEntryById)..build();
      _userTagsManager = UserTagManager(_userId, userTags, _getEntryById)
        ..build();
      notifyListeners();
    });
  }

  late LibraryIndexModel _indexModel;
  LibraryEntry? _getEntryById(int id) => _indexModel.getEntryById(id);
}

const _genreGroups = [
  'Adventure',
  'RPG',
  'Shooter',
  'Platformer',
  'Strategy',
  'Simulator',
  'Arcade',
  'Casual',
];

const Map<String, List<String>> _genreTags = {
  'Adventure': [
    'Point & Click',
    'Action',
    'Isometric Action',
    'Narrative Adventure',
    'Survival Adventure',
    'Puzzle Adventure',
    'Walking Simulator',
  ],
  'Arcade': [
    'Fighting',
    'Beat\'em Up',
    'Pinball',
    'Card & Board Game',
    'Deckbuilder',
  ],
  'Casual': [
    'Life Sim',
    'Farming Sim',
    'Fishing Sim',
    'Sailing Sim',
    'Dating Sim',
    'Puzzle',
    'Endless Runner',
    'Rhythm',
    'Party Game',
    'Visual Novel',
    'Exploration',
  ],
  'Platformer': [
    'Side Scroller',
    'Metroidvania',
    '3D Platformer',
    'Shooter Platformer',
    'Precision Platformer',
    'Puzzle Platformer',
  ],
  'RPG': [
    'CRPG',
    'ARPG',
    'Action RPG',
    'JRPG',
    'First Person RPG',
    'Turn Based RPG',
    'RTwP RPG',
    'Dungeon Crawler',
    'MMORPG',
  ],
  'Shooter': [
    'First Person Shooter',
    'Top-Down Shooter',
    '3rd Person Shooter',
    'Space Shooter',
    'Shmup',
    'Battle Royale',
  ],
  'Simulator': [
    'City Builder',
    'Tycoon',
    'God Game',
    'Racing',
    'Sports',
    'Flight Simulator',
    'Combat Simulator',
    'Naval Simulator',
    'Driving Simulator',
    'Survival',
  ],
  'Strategy': [
    'Turn Based Strategy',
    'Real-Time Strategy',
    'Turn Based Tactics',
    'Real-Time Tactics',
    'Grand Strategy',
    '4X',
    'Tower Defense',
    'MOBA',
  ],
};

Map<String, String> _groupMapping = {};
