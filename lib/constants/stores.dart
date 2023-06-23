import 'package:flutter/material.dart';

class Stores {
  static const _ids = [
    'gog',
    'steam',
    'egs',
    'battle.net',
    'ea',
    'uplay',
    'disc',
  ];

  static List<String> get ids => _ids;

  static Widget getIcon(String storeId) =>
      Image.asset('assets/images/$storeId-128.png');
}
