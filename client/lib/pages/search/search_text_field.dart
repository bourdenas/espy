import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  SearchTextField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: TextField(
            key: Key('searchTextField'),
            controller: _searchController,
            onChanged: onChanged,
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
        SizedBox(width: 16.0),
        Expanded(
          child: IconButton(
            icon: Icon(Icons.filter_alt_outlined),
            onPressed: () {},
            splashRadius: 20.0,
          ),
        ),
      ],
    );
  }

  final TextEditingController _searchController = TextEditingController();
}
