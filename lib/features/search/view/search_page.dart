import 'package:crossonic/page_transition.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  static Route route(BuildContext context, Object? arguments) {
    return PageTransition(const SearchPage());
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Search'),
    );
  }
}
