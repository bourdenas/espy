import 'package:espy/modules/documents/game_digest.dart';

class CalendarGridEntry {
  static CalendarGridEntry empty = CalendarGridEntry(null, [], onClick: (_) {});

  const CalendarGridEntry(
    this.label,
    this.digests, {
    required this.onClick,
  });

  final String? label;
  final List<GameDigest> digests;
  final void Function(CalendarGridEntry) onClick;

  Iterable<GameDigest> get covers => digests.take(5).toList();
}
