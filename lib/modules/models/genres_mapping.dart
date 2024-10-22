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
    'JRPG',
  ],
  'Adventure': [
    'PointAndClick',
    'NarrativeAdventure',
    'SurvivalAdventure',
    'PuzzleAdventure',
    'WalkingSimulator',
  ],
  'Arcade': [
    'Arcade',
    'Fighting',
    'BeatEmUp',
    'CardAndBoard',
    'Deckbuilder',
  ],
  'Casual': [
    'LifeSim',
    'FarmingSim',
    'DatingSim',
    'Puzzle',
    'VisualNovel',
    'Exploration',
    'Rhythm',
    'PartyGame',
  ],
  'Platformer': [
    'SideScroller',
    'Platformer3d',
    'ShooterPlatformer',
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
    'BattleRoyale',
  ],
  'Simulator': [
    'CityBuilder',
    'Tycoon',
    'GodGame',
    'Racing',
    'Sports',
    'Survival',
    'FlightSimulator',
    'CombatSimulator',
    'DrivingSimulator',
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
  'JRPG': 'JRPG',

  // Adventure
  'PointAndClick': 'Point & Click',
  'NarrativeAdventure': 'Narrative Adventure',
  'SurvivalAdventure': 'Survival Adventure',
  'PuzzleAdventure': 'Puzzle Adventure',
  'WalkingSimulator': 'Walking Simulator',

  // Arcade
  'Arcade': 'Arcade',
  'Fighting': 'Fighting',
  'BeatEmUp': "Beat'em Up",
  'CardAndBoard': 'Card & Board Game',
  'Deckbuilder': 'Deckbuilder',

  // Casual
  'LifeSim': 'Life Sim',
  'FarmingSim': 'Farming Sim',
  'FishingSim': 'Fishing Sim',
  'SailingSim': 'Sailing Sim',
  'DatingSim': 'Dating Sim',
  'Puzzle': 'Puzzle',
  'Rhythm': 'Rhythm',
  'PartyGame': 'Party Game',
  'VisualNovel': 'Visual Novel',
  'Exploration': 'Exploration',

  // Platformer
  'SideScroller': 'Side Scroller',
  'Metroidvania': 'Metroidvania',
  'Platformer3d': '3D Platformer',
  'ShooterPlatformer': 'Shooter Platformer',
  'PrecisionPlatformer': 'Precision Platformer',
  'PuzzlePlatformer': 'Puzzle Platformer',

  // RPG
  'CRPG': 'CRPG',
  'ARPG': 'ARPG',
  'FirstPersonRpg': 'First Person RPG',
  'TurnBasedRpg': 'Turn Based RPG',
  'RTwPRPG': 'RTwP RPG',
  'DungeonCrawler': 'Dungeon Crawler',
  'MMORPG': 'MMORPG',

  // Shooter
  'FirstPersonShooter': 'First Person Shooter',
  'TopDownShooter': 'Top-Down Shooter',
  'ThirdPersonShooter': '3rd Person Shooter',
  'SpaceShooter': 'Space Shooter',
  'Shmup': 'Shmup',
  'BattleRoyale': 'Battle Royale',

  // Simulator
  'CityBuilder': 'City Builder',
  'Tycoon': 'Tycoon',
  'GodGame': 'God Game',
  'Racing': 'Racing',
  'Sports': 'Sports',
  'FlightSimulator': 'Flight Simulator',
  'CombatSimulator': 'Combat Simulator',
  'NavalSimulator': 'Naval Simulator',
  'DrivingSimulator': 'Driving Simulator',
  'Survival': 'Survival',

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
  'JRPG': 'JRPG',

  // Adventure
  'Point & Click': 'PointAndClick',
  'Narrative Adventure': 'NarrativeAdventure',
  'Survival Adventure': 'SurvivalAdventure',
  'Puzzle Adventure': 'PuzzleAdventure',
  'Walking Simulator': 'WalkingSimulator',

  // Arcade
  'Fighting': 'Fighting',
  "Beat'em Up": 'BeatEmUp',
  'Arcade': 'Arcade',
  'Card & Board Game': 'CardAndBoard',
  'Deckbuilder': 'Deckbuilder',

  // Casual
  'Life Sim': 'LifeSim',
  'Farming Sim': 'FarmingSim',
  'Fishing Sim': 'FishingSim',
  'Sailing Sim': 'SailingSim',
  'Dating Sim': 'DatingSim',
  'Puzzle': 'Puzzle',
  'Rhythm': 'Rhythm',
  'Party Game': 'PartyGame',
  'Visual Novel': 'VisualNovel',
  'Exploration': 'Exploration',

  // Platformer
  'Side Scroller': 'SideScroller',
  'Metroidvania': 'Metroidvania',
  '3D Platformer': 'Platformer3d',
  'Shooter Platformer': 'ShooterPlatformer',
  'Precision Platformer': 'PrecisionPlatformer',
  'Puzzle Platformer': 'PuzzlePlatformer',

  // RPG
  'CRPG': 'CRPG',
  'ARPG': 'ARPG',
  'First Person RPG': 'FirstPersonRpg',
  'Turn Based RPG': 'TurnBasedRpg',
  'RTwP RPG': 'RTwPRPG',
  'Dungeon Crawler': 'DungeonCrawler',
  'MMORPG': 'MMORPG',

  // Shooter
  'First Person Shooter': 'FirstPersonShooter',
  'Top-Down Shooter': 'TopDownShooter',
  '3rd Person Shooter': 'ThirdPersonShooter',
  'Space Shooter': 'SpaceShooter',
  'Shmup': 'Shmup',
  'Battle Royale': 'BattleRoyale',

  // Simulator
  'City Builder': 'CityBuilder',
  'Tycoon': 'Tycoon',
  'God Game': 'GodGame',
  'Racing': 'Racing',
  'Sports': 'Sports',
  'Flight Simulator': 'FlightSimulator',
  'Combat Simulator': 'CombatSimulator',
  'Naval Simulator': 'NavalSimulator',
  'Driving Simulator': 'DrivingSimulator',
  'Survival': 'Survival',

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
