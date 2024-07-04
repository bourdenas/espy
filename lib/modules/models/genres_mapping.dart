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
  'Shooter',
  'Platformer',
  'Simulator',
  'Arcade',
  'Casual',
];

const Map<String, List<String>> _genresInGroup = {
  'Adventure': [
    'PointAndClick',
    'Action',
    'IsometricAction',
    'NarrativeAdventure',
    'SurvivalAdventure',
    'PuzzleAdventure',
    'WalkingSimulator',
  ],
  'Arcade': [
    'Fighting',
    'BeatEmUp',
    'Pinball',
    'CardAndBoard',
    'Deckbuilder',
  ],
  'Casual': [
    'LifeSim',
    'FarmingSim',
    'FishingSim',
    'SailingSim',
    'DatingSim',
    'Puzzle',
    'EndlessRunner',
    'Rhythm',
    'PartyGame',
    'VisualNovel',
    'Exploration',
  ],
  'Platformer': [
    'SideScroller',
    'Metroidvania',
    'Platformer3d',
    'ShooterPlatformer',
    'PrecisionPlatformer',
    'PuzzlePlatformer',
  ],
  'RPG': [
    'CRPG',
    'ARPG',
    'ActionRpg',
    'JRPG',
    'FirstPersonRpg',
    'TurnBasedRpg',
    'RTwPRPG',
    'DungeonCrawler',
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
    'FlightSimulator',
    'CombatSimulator',
    'NavalSimulator',
    'DrivingSimulator',
    'Survival',
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
    '',
  ]
};

const Map<String, String> _genreToLabel = {
  // Adventure
  'PointAndClick': 'Point & Click',
  'Action': 'Action',
  'IsometricAction': 'Isometric Action',
  'NarrativeAdventure': 'Narrative Adventure',
  'SurvivalAdventure': 'Survival Adventure',
  'PuzzleAdventure': 'Puzzle Adventure',
  'WalkingSimulator': 'Walking Simulator',

  // Arcade
  'Fighting': 'Fighting',
  'BeatEmUp': "Beat'em Up",
  'Pinball': 'Pinball',
  'CardAndBoard': 'Card & Board Game',
  'Deckbuilder': 'Deckbuilder',

  // Casual
  'LifeSim': 'Life Sim',
  'FarmingSim': 'Farming Sim',
  'FishingSim': 'Fishing Sim',
  'SailingSim': 'Sailing Sim',
  'DatingSim': 'Dating Sim',
  'Puzzle': 'Puzzle',
  'EndlessRunner': 'Endless Runner',
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
  'ActionRpg': 'Action RPG',
  'JRPG': 'JRPG',
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
  // Adventure
  'Point & Click': 'PointAndClick',
  'Action': 'Action',
  'Isometric Action': 'IsometricAction',
  'Narrative Adventure': 'NarrativeAdventure',
  'Survival Adventure': 'SurvivalAdventure',
  'Puzzle Adventure': 'PuzzleAdventure',
  'Walking Simulator': 'WalkingSimulator',

  // Arcade
  'Fighting': 'Fighting',
  "Beat'em Up": 'BeatEmUp',
  'Pinball': 'Pinball',
  'Card & Board Game': 'CardAndBoard',
  'Deckbuilder': 'Deckbuilder',

  // Casual
  'Life Sim': 'LifeSim',
  'Farming Sim': 'FarmingSim',
  'Fishing Sim': 'FishingSim',
  'Sailing Sim': 'SailingSim',
  'Dating Sim': 'DatingSim',
  'Puzzle': 'Puzzle',
  'Endless Runner': 'EndlessRunner',
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
  'Action RPG': 'ActionRpg',
  'JRPG': 'JRPG',
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
