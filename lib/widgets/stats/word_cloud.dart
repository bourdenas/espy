import 'dart:math';

import 'package:flutter/material.dart';

class WordCloud extends StatelessWidget {
  final List<WordSpec> words;
  final WordCloudConfig config;

  final Color? backgroundColor;
  final Decoration? decoration;

  final void Function(String word)? onClick;

  const WordCloud({
    super.key,
    required this.words,
    required this.config,
    this.backgroundColor,
    this.decoration,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    words.sort((a, b) => b.weight.compareTo(a.weight));
    final layout = WordCloudLayout(config);
    layout.build(words);

    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        if (onClick == null) {
          return;
        }

        for (final word in layout.wordBoxes) {
          if (word.offset == null) {
            continue;
          }

          final (x, y) = (details.localPosition.dx, details.localPosition.dy);
          final (left, top) = (word.offset!.dx, word.offset!.dy);
          final (w, h) = (word.painter.width, word.painter.height);
          if (left <= x && x < left + w && top <= y && y <= top + h) {
            onClick!(word.text);
          }
        }
      },
      child: Container(
        width: config.mapWidth,
        height: config.mapHeight,
        color: backgroundColor,
        decoration: decoration,
        child: CustomPaint(
          painter: WordCloudPainter(layout),
        ),
      ),
    );
  }
}

class WordSpec {
  WordSpec(this.text, this.weight, {this.color});

  String text;
  double weight;
  Color? color;
}

class WordBox {
  WordBox(this.text, this.painter, [this.offset]);

  final String text;
  final TextPainter painter;
  Offset? offset;
}

class WordCloudConfig {
  WordCloudConfig({
    this.mapWidth = 500,
    this.mapHeight = 250,
    this.minTextSize = 10,
    this.maxTextSize = 42,
    this.attempts = 30,
    this.fontFamily,
    this.fontStyle,
    this.fontWeight,
    this.colorList = const [Colors.black],
  });

  final double mapWidth;
  final double mapHeight;
  final double minTextSize;
  final double maxTextSize;
  final int attempts;
  final String? fontFamily;
  final FontStyle? fontStyle;
  final FontWeight? fontWeight;
  final List<Color>? colorList;
}

class WordCloudLayout {
  WordCloudLayout(this.config);

  final WordCloudConfig config;
  late Offset center;
  List<List<int>> bitMap = [];
  List<WordBox> wordBoxes = [];

  void build(List<WordSpec> words) {
    center = Offset(config.mapWidth / 2, config.mapHeight / 2);

    _initBitMap(config.mapWidth.toInt(), config.mapHeight.toInt());
    _buildTextBoxes(words);
    _positionText();
  }

  void _initBitMap(int width, int height) {
    // Build an empty bitmap of size WxH.
    bitMap = List.generate(width, (_) => List.filled(height, 0));
    final halfWidthSq = pow(width / 2, 2);
    final halfHeightSq = pow(height / 2, 2);

    // Block the corners outside the ellipse.
    for (int i = 0; i < width; ++i) {
      for (int j = 0; j < height; ++j) {
        if (pow(i - center.dx, 2) / halfWidthSq +
                pow(j - center.dy, 2) / halfHeightSq >
            1) {
          bitMap[i][j] = 1;
        }
      }
    }
  }

  void _buildTextBoxes(List<WordSpec> words) {
    double maxWeight = words.first.weight;
    double minWeight = words.last.weight;
    double normalizer = maxWeight - minWeight;

    for (final word in words) {
      // Normalize weights to assign sizes linearly.
      double textSize = normalizer != 0
          ? (config.minTextSize * (maxWeight - word.weight) +
                  config.maxTextSize * (word.weight - minWeight)) /
              normalizer
          : (config.minTextSize + config.maxTextSize) / 2;

      final textSpan = TextSpan(
        text: word.text,
        style: TextStyle(
          color: word.color ??
              config.colorList?[Random().nextInt(config.colorList!.length)],
          fontSize: textSize,
          fontWeight: config.fontWeight,
          fontFamily: config.fontFamily,
          fontStyle: config.fontStyle,
        ),
      );

      final textPainter = TextPainter()
        ..text = textSpan
        ..textDirection = TextDirection.ltr
        ..textAlign = TextAlign.center
        ..layout();

      wordBoxes.add(WordBox(word.text, textPainter));
    }
  }

  void _positionText() {
    _place(
        wordBoxes.first,
        center -
            Offset(
              wordBoxes.first.painter.width / 2,
              wordBoxes.first.painter.height / 2,
            ));

    for (final text in wordBoxes.skip(1)) {
      final (w, h) = (text.painter.width, text.painter.height);

      for (int attempts = 0; attempts < config.attempts; ++attempts) {
        int x = Random().nextInt(config.mapWidth.toInt() - w.toInt());
        int y = Random().nextInt(config.mapHeight.toInt() - h.toInt());

        if (_hasNoOverlap(x, y, w, h)) {
          _place(text, Offset(x.toDouble(), y.toDouble()));
          break;
        }
      }
    }
  }

  void _place(WordBox textBox, Offset at) {
    textBox.offset = at;
    final (x, y) = (at.dx.toInt(), at.dy.toInt());
    final (w, h) =
        (textBox.painter.width.toInt(), textBox.painter.height.toInt());

    for (int i = x; i < x + w; ++i) {
      for (int j = y; j < y + h; ++j) {
        bitMap[i][j] = 1;
      }
    }
  }

  bool _hasNoOverlap(int x, int y, double w, double h) {
    if (x + w >= config.mapWidth) {
      return false;
    }
    if (y + h >= config.mapHeight) {
      return false;
    }

    for (int i = x; i < x + w; ++i) {
      if (bitMap[i][y] == 1) {
        return false;
      }
      if (bitMap[i][y + h.toInt() - 1] == 1) {
        return false;
      }
    }
    return true;
  }
}

class WordCloudPainter extends CustomPainter {
  WordCloudPainter(this.layout);

  final WordCloudLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    for (final word in layout.wordBoxes) {
      if (word.offset != null) {
        word.painter.paint(canvas, word.offset!);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
