class Genres {
  static Iterable<String> get groups => _genreGroups;

  static List<String>? genresInGroup(String genreGroup) =>
      _genresInGroup[genreGroup];

  static String? groupOfGenre(String? genre) {
    if (genre == null) {
      return null;
    }

    for (final entry in _genresInGroup.entries) {
      for (final e in entry.value) {
        if (e == genre) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static String genreLabel(String genre) => _genreToLabel[genre] ?? '';
  static String genreFromLabel(String label) => _labelToGenre[label] ?? '';
}

const _genreGroups = [
  'Adventure',
  'RPG',
  'Strategy',
  'Action',
  'Shooter',
  'Platformer',
  'Simulator',
  'Arcade',
  'Casual',
];

const Map<String, List<String>> _genresInGroup = {
  'Action': [
    'Action',
    'ActionRpg',
    'IsometricAction',
    'SurvivalAdventure',
    'JRPG',
  ],
  'Adventure': [
    'PointAndClick',
    'NarrativeAdventure',
    'PuzzleAdventure',
    'WalkingSimulator',
  ],
  'Arcade': [
    'Arcade',
    'Fighting',
    'BeatEmUp',
    'CardAndBoard',
  ],
  'Casual': [
    'LifeSim',
    'DatingSim',
    'VisualNovel',
    'Puzzle',
    'PartyGame',
    'Rhythm',
  ],
  'Platformer': [
    'SideScroller',
    'Platformer3d',
    'PuzzlePlatformer',
  ],
  'RPG': [
    'CRPG',
    'ARPG',
    'FirstPersonRpg',
    'MMORPG',
  ],
  'Shooter': [
    'FirstPersonShooter',
    'TopDownShooter',
    'ThirdPersonShooter',
    'SpaceShooter',
    'Shmup',
  ],
  'Simulator': [
    'CityBuilder',
    'Tycoon',
    'Racing',
    'Sports',
    'Survival',
    'BusinessSimulator',
    'FlightSimulator',
    'NavalSimulator',
  ],
  'Strategy': [
    'TurnBasedStrategy',
    'RealTimeStrategy',
    'TurnBasedTactics',
    'RealTimeTactics',
    'GradStrategy',
    'FourX',
    'TowerDefense',
    'MOBA',
  ],
  'Unknown': [
    'Unknown',
  ]
};

const Map<String, String> _genreToLabel = {
  // Action
  'Action': 'Action',
  'ActionRpg': 'Action RPG',
  'IsometricAction': 'Isometric Action',
  'SurvivalAdventure': 'Survival Adventure',
  'JRPG': 'JRPG',

  // Adventure
  'PointAndClick': 'Point & Click',
  'NarrativeAdventure': 'Narrative Adventure',
  'PuzzleAdventure': 'Puzzle Adventure',
  'WalkingSimulator': 'Walking Simulator',

  // Arcade
  'Arcade': 'Arcade',
  'Fighting': 'Fighting',
  'BeatEmUp': "Beat'em Up",
  'CardAndBoard': 'Card & Board Game',

  // Casual
  'LifeSim': 'Life Sim',
  'DatingSim': 'Dating Sim',
  'VisualNovel': 'Visual Novel',
  'Puzzle': 'Puzzle',
  'Rhythm': 'Rhythm',
  'PartyGame': 'Party Game',

  // Platformer
  'SideScroller': 'Side Scroller',
  'Platformer3d': '3D Platformer',
  'PuzzlePlatformer': 'Puzzle Platformer',

  // RPG
  'CRPG': 'CRPG',
  'ARPG': 'ARPG',
  'FirstPersonRpg': 'First Person RPG',
  'MMORPG': 'MMORPG',

  // Shooter
  'FirstPersonShooter': 'First Person Shooter',
  'TopDownShooter': 'Top-Down Shooter',
  'ThirdPersonShooter': 'Third Person Shooter',
  'SpaceShooter': 'Space Shooter',
  'Shmup': 'Shmup',

  // Simulator
  'CityBuilder': 'City Builder',
  'Tycoon': 'Tycoon',
  'Racing': 'Racing',
  'Sports': 'Sports',
  'Survival': 'Survival',
  'BusinessSimulator': 'Business Simulator',
  'FlightSimulator': 'Flight Simulator',
  'NavalSimulator': 'Naval Simulator',

  // Strategy
  'TurnBasedStrategy': 'Turn Based Strategy',
  'RealTimeStrategy': 'Real-Time Strategy',
  'TurnBasedTactics': 'Turn Based Tactics',
  'RealTimeTactics': 'Real-Time Tactics',
  'GradStrategy': 'Grand Strategy',
  'FourX': '4X',
  'TowerDefense': 'Tower Defense',
  'MOBA': 'MOBA',
};

const Map<String, String> _labelToGenre = {
  // Action
  'Action': 'Action',
  'Action RPG': 'ActionRpg',
  'Isometric Action': 'IsometricAction',
  'Survival Adventure': 'SurvivalAdventure',
  'JRPG': 'JRPG',

  // Adventure
  'Point & Click': 'PointAndClick',
  'Narrative Adventure': 'NarrativeAdventure',
  'Puzzle Adventure': 'PuzzleAdventure',
  'Walking Simulator': 'WalkingSimulator',

  // Arcade
  'Fighting': 'Fighting',
  "Beat'em Up": 'BeatEmUp',
  'Arcade': 'Arcade',
  'Card & Board Game': 'CardAndBoard',

  // Casual
  'Life Sim': 'LifeSim',
  'Dating Sim': 'DatingSim',
  'Visual Novel': 'VisualNovel',
  'Puzzle': 'Puzzle',
  'Party Game': 'PartyGame',
  'Rhythm': 'Rhythm',

  // Platformer
  'Side Scroller': 'SideScroller',
  '3D Platformer': 'Platformer3d',
  'Puzzle Platformer': 'PuzzlePlatformer',

  // RPG
  'CRPG': 'CRPG',
  'ARPG': 'ARPG',
  'First Person RPG': 'FirstPersonRpg',
  'MMORPG': 'MMORPG',

  // Shooter
  'First Person Shooter': 'FirstPersonShooter',
  'Top-Down Shooter': 'TopDownShooter',
  '3rd Person Shooter': 'ThirdPersonShooter',
  'Space Shooter': 'SpaceShooter',
  'Shmup': 'Shmup',

  // Simulator
  'City Builder': 'CityBuilder',
  'Tycoon': 'Tycoon',
  'Racing': 'Racing',
  'Sports': 'Sports',
  'Survival': 'Survival',
  'Business Simulator': 'BusinessSimulator',
  'Flight Simulator': 'FlightSimulator',
  'Naval Simulator': 'NavalSimulator',

  // Strategy
  'Turn Based Strategy': 'TurnBasedStrategy',
  'Real-Time Strategy': 'RealTimeStrategy',
  'Turn Based Tactics': 'TurnBasedTactics',
  'Real-Time Tactics': 'RealTimeTactics',
  'Grand Strategy': 'GradStrategy',
  '4X': 'FourX',
  'Tower Defense': 'TowerDefense',
  'MOBA': 'MOBA',
};
