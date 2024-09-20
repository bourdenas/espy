import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/keyword_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/filters/sliding_chip.dart';
import 'package:espy/widgets/gametags/espy_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Refinements extends StatelessWidget {
  const Refinements({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<LibraryFilterModel>().filter;

    return SlidingChip(
      label: 'Keywords',
      color: filter.keyword == null ? KeywordChip.color : null,
      backgroundColor: filter.keyword != null ? KeywordChip.color : null,
      closeIcon: Icons.close,
      initialOpen: true,
      expansion: const KeywordGroupChips(),
    );
  }
}

class KeywordGroupChips extends StatefulWidget {
  const KeywordGroupChips({super.key});

  @override
  State<KeywordGroupChips> createState() => _KeywordGroupChipsState();
}

class _KeywordGroupChipsState extends State<KeywordGroupChips> {
  String? activeKwGroup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: (activeKwGroup == null)
          ? buildKeywordGroups(context)
          : buildKeywords(context, activeKwGroup!),
    );
  }

  List<Widget> buildKeywordGroups(BuildContext context) {
    return [
      for (final group in Keywords.groups) ...[
        KeywordFilter(
          label: group,
          color: KeywordChip.color,
          onClick: () => setState(() {
            activeKwGroup = group;
          }),
        ),
        const SizedBox(width: 8),
      ],
    ];
  }

  List<Widget> buildKeywords(BuildContext context, String kwGroup) {
    final filter = context.watch<LibraryFilterModel>().filter;
    final selectedKeyword = filter.keyword;

    return [
      KeywordFilter(
        label: kwGroup,
        backgroundColor: KeywordChip.color,
        open: true,
        onClick: () => setState(() {
          activeKwGroup = null;
        }),
      ),
      const SizedBox(width: 4),
      for (final kw in Keywords.keywordsInGroup(kwGroup) ?? [])
        if (kw.isNotEmpty) ...[
          KeywordChip(
            kw,
            onPressed: () {
              final updated = filter.add(LibraryFilter(keyword: kw));
              context.read<LibraryFilterModel>().filter = updated;
            },
            filled: selectedKeyword == kw,
          ),
          const SizedBox(width: 8),
        ],
    ];
  }
}

class KeywordFilter extends StatelessWidget {
  const KeywordFilter({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.openIcon = Icons.keyboard_arrow_right,
    this.closeIcon = Icons.keyboard_arrow_left,
    required this.onClick,
    this.open = false,
  });

  final String label;
  final Color? color;
  final Color? backgroundColor;
  final IconData openIcon;
  final IconData closeIcon;
  final void Function() onClick;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Row(
        children: [
          Icon(
            open ? closeIcon : openIcon,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(color: color),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      onPressed: onClick,
    );
  }
}
