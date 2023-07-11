import 'dart:math';

bool matchInDict(String input, List<String> dict, {double threshold = .3}) {
  for (final kw in dict) {
    final distance = _editDistance(input.toLowerCase(), kw.toLowerCase()) /
        max(input.length, kw.length);
    if (distance < threshold) {
      return true;
    }
  }
  return false;
}

int _editDistance(String a, String b) {
  if (a == b) {
    return 0;
  } else if (a.isEmpty) {
    return b.length;
  } else if (b.isEmpty) {
    return a.length;
  }

  var v0 = List<int>.generate(b.length + 1, (i) => i, growable: false);
  var v1 = List<int>.filled(b.length + 1, 0, growable: false);

  for (var i = 0; i < a.length; ++i) {
    v1[0] = i + 1;

    for (var j = 0; j < b.length; ++j) {
      int distance = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + distance));
    }

    var vtemp = v0;
    v0 = v1;
    v1 = vtemp;
  }

  return v0.last;
}
