import 'package:flutter/material.dart';

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
    'rogue-like',
    'rogue-lite',
    'souls-like',
    'boomer shooter',
    'looter shooter',
    'twin-stick shooter',
    'turn-based',
    'RTwP',
    'dungeon crawler',
    'metroidvania',
    'precision platformer',
    'bullet hell',
    'deckbuilder',
  ],
  'Visual Style': [
    'pixel art',
    'hand-drawn',
    'cartoon',
    'anime',
    'voxel',
    'FMV',
  ],
  'Setting': [
    'sci-fi',
    'cyberpunk',
    'steampunk',
    'dark fantasy',
    'lovecraftian',
    'post-apocalyptic',
    'dystopian',
    'heavy metal',
    'aliens',
    'vampires',
    'zombies',
    'mechs',
    'space',
    'noir',
    'time travel',
  ],
  'Historical Setting': [
    'WW1',
    'WW2',
    'cold war',
    'modern warefare',
    'ancient world',
    'mythology',
    'historical',
    'alternate history',
  ],
  'Maturity': [
    'mature',
    'horror',
    'psychological horror',
    'sexual content',
    'nudity',
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

const keywordsPalette = {
  'Gameplay': Colors.blue,
  'Visual Style': Colors.redAccent,
  'Setting': Colors.orange,
  'Historical Setting': Colors.green,
  'Maturity': Colors.purple,
  'Multiplayer': Colors.lime,
  'Warning': Colors.pink,
};
