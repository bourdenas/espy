import 'package:espy/modules/models/app_config_model.dart';
import 'package:flutter/material.dart';

class SearchTextField extends StatefulWidget {
  const SearchTextField({
    Key? key,
    required this.onChanged,
    required this.onSubmitted,
  }) : super(key: key);

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (AppConfigModel.isDesktop(context)) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Focus(
            child: TextField(
              key: const Key('searchTextField'),
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ],
    );
  }

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
}
