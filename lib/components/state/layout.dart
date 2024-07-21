import 'package:flutter/material.dart';

enum LayoutSize {
  mobile,
  desktop,
}

class Layout with ChangeNotifier {
  LayoutSize _size;
  LayoutSize get size => _size;
  set size(LayoutSize size) {
    _size = size;
    notifyListeners();
  }

  Layout({required size}) : _size = size;
}
