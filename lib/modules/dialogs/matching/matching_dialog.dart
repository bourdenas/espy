import 'package:espy/modules/dialogs/matching/matching_dialog_content.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MatchingDialog extends StatefulWidget {
  static void show(
    BuildContext context, {
    StoreEntry? storeEntry,
    void Function(StoreEntry, GameEntry)? onMatch,
  }) {
    showDialog(
      context: context,
      builder: (context) => MatchingDialog(
        storeEntry: storeEntry,
        onMatch: onMatch,
      ),
    );
  }

  const MatchingDialog({
    Key? key,
    this.storeEntry,
    this.onMatch,
  }) : super(key: key);

  final StoreEntry? storeEntry;
  final void Function(StoreEntry, GameEntry)? onMatch;

  @override
  State<MatchingDialog> createState() => _MatchingDialogState();
}

/// Handling initial request to matches.
///
/// Separated in a top level widget because the pop-up animatino of the dialog
/// would otherwise cause to send this request multiple times.
class _MatchingDialogState extends State<MatchingDialog> {
  @override
  Widget build(BuildContext context) {
    return MatchingDialogAnimation(
        widget.storeEntry,
        context
            .read<GameLibraryModel>()
            .searchByTitle(widget.storeEntry?.title ?? ''),
        widget.onMatch);
  }
}

class MatchingDialogAnimation extends StatefulWidget {
  const MatchingDialogAnimation(this.storeEntry, this.matches, this.onMatch,
      {Key? key})
      : super(key: key);

  final StoreEntry? storeEntry;
  final Future<List<GameEntry>> matches;
  final void Function(StoreEntry, GameEntry)? onMatch;

  @override
  State<MatchingDialogAnimation> createState() =>
      _MatchingDialogAnimationState();
}

class _MatchingDialogAnimationState extends State<MatchingDialogAnimation>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scalingAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.elasticInOut);
    _animationController.addListener(() {
      setState(() {});
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scalingAnimation,
      child: MatchingDialogContent(
        widget.storeEntry,
        widget.matches,
        onMatch: widget.onMatch,
      ),
    );
  }

  late AnimationController _animationController;
  late Animation<double> _scalingAnimation;
}
