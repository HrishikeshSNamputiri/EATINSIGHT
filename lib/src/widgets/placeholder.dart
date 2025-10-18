import 'package:flutter/material.dart';

class PlaceholderTile extends StatelessWidget {
  final String title;
  const PlaceholderTile(this.title, {super.key});
  @override
  Widget build(BuildContext context) => ListTile(title: Text(title));
}
