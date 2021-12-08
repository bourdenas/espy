import 'package:espy/modules/models/appbar_search_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Searchbar extends StatefulWidget {
  const Searchbar({Key? key}) : super(key: key);

  @override
  _SearchbarState createState() => _SearchbarState();
}

class _SearchbarState extends State<Searchbar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Icon _searchIcon = Icon(Icons.search);

  @override
  void initState() {
    super.initState();

    context.read<AppBarSearchModel>().controller = _searchController;

    _searchController.addListener(() {
      final text = _searchController.text.toLowerCase();
      if (text.isNotEmpty && _searchIcon.icon != Icons.close) {
        setState(() {
          _searchIcon = Icon(Icons.close);
        });
      }
      if (text.isEmpty && _searchIcon.icon != Icons.search) {
        setState(() {
          _searchIcon = Icon(Icons.search);
        });
      }
      context.read<AppBarSearchModel>().text = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      decoration: InputDecoration(
        prefixIcon: IconButton(
          icon: _searchIcon,
          onPressed: () => _searchController.clear(),
        ),
        hintText: 'Title search...',
      ),
    );
  }
}
