import 'package:flutter/material.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import '../Resources/colors.dart';

class KSearchbar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String val)? onFieldSubmitted;
  final void Function()? onClear;
  final bool isFetching;
  final void Function(String val)? onChanged;

  const KSearchbar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onFieldSubmitted,
    this.onClear,
    this.isFetching = false,
    this.onChanged,
  });

  @override
  State<KSearchbar> createState() => _KSearchbarState();
}

class _KSearchbarState extends State<KSearchbar> {
  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: widget.controller,
      elevation: WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(Kolor.scaffold),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ).copyWith(right: 5)),
      hintText: widget.hintText,
      hintStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          color: Kolor.fadeText,
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontVariations: [FontVariation.weight(500)],
        ),
      ),
      leading: Icon(Icons.search),
      side: WidgetStatePropertyAll(BorderSide(color: Kolor.border)),
      trailing: [
        if (widget.isFetching)
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        width15,
      ],
      onChanged: widget.onChanged,
    );
  }
}
