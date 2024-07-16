class Keywords {
  static Iterable<String> get groups => _kwGroups;

  static List<String>? keywordsInGroup(String kwGroup) => _kwsInGroup[kwGroup];

  static String? groupOfKeyword(String? keyword) {
    if (keyword == null) {
      return null;
    }

    for (final entry in _kwsInGroup.entries) {
      for (final e in entry.value) {
        if (e == keyword) {
          return entry.key;
        }
      }
    }
    return null;
  }
}

const _kwGroups = [
  'Gameplay',
  'Visual Style',
  'Setting',
  'Historical Setting',
  'Maturity',
  'Multiplayer',
  'Warning',
];

const Map<String, List<String>> _kwsInGroup = {
  'Gameplay': [
    'turn-based',
    'RTwP',
    'dungeon crawler',
    'roguelike',
    'roguelite',
    'metroidvania',
    'precision platformer',
    'bullet hell',
    'boomer shooter',
    'looter shooter',
    'twin stick shooter',
    'souls-like',
  ],
  'Visual Style': [
    'indie',
    'pixel art',
    'hand-drawn',
    'cartoon',
    'anime',
    'voxel',
    'FMV',
  ],
  'Setting': [
    'aliens',
    'vampires',
    'zombies',
    'mechs',
    'sci-fi',
    'cyberpunk',
    'steampunk',
    'dark fantasy',
    'post-apocalyptic',
    'dystopian',
    'lovecraftian',
    'heavy metal',
    'space',
    'noir',
    'time travel',
  ],
  'Historical Setting': [
    'ancient world',
    'mythology',
    'WW1',
    'WW2',
    'cold war',
    'modern warefare',
    'historical',
    'alternate history',
  ],
  'Maturity': [
    'mature',
    'horror',
    'psychological horror',
    'NSFW',
    'nudity',
    'sexual content',
    'family friendly',
  ],
  'Multiplayer': [
    'co-op',
    'PvP',
  ],
  'Warning': [
    'free-to-play',
    'pay-to-play',
    'microtransaction',
  ],
};
