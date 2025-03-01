import 'package:flutter/material.dart';

class AlbumsGridDelegate extends SliverGridDelegateWithMaxCrossAxisExtent {
  AlbumsGridDelegate()
      : super(
          maxCrossAxisExtent: 180,
          childAspectRatio: 4.0 / 5,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        );
}
