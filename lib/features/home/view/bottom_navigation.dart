import 'package:flutter/material.dart';

typedef OnIndexChangedCallback = void Function(int newIndex);

class BottomNavigation extends StatelessWidget {
  final int _currentIndex;
  final OnIndexChangedCallback _onIndexChanged;
  const BottomNavigation(
      {super.key,
      required int currentIndex,
      required OnIndexChangedCallback onIndexChanged})
      : _currentIndex = currentIndex,
        _onIndexChanged = onIndexChanged;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music_outlined),
          label: "Browse",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.queue_music),
          label: "Playlists",
        ),
      ],
      onTap: _onIndexChanged,
    );
  }
}
