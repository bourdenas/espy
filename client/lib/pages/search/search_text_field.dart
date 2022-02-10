import 'package:flutter/material.dart';

class SearchTextField extends StatefulWidget {
  SearchTextField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  final ValueChanged<String> onChanged;

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: TextField(
            key: Key('searchTextField'),
            autofocus: true,
            controller: _searchController,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white70,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            textInputAction: TextInputAction.search,
            cursorColor: Colors.white,
          ),
        ),
      ],
    );
  }

  final TextEditingController _searchController = TextEditingController();
}
