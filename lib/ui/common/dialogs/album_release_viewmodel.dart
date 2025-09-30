import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:flutter/material.dart';

class AlbumReleaseDialogViewModel extends ChangeNotifier {
  final String _albumName;
  String get albumName => _albumName;
  final Date? _originalDate;
  Date? get originalDate => _originalDate;
  final Date? _releaseDate;
  Date? get releaseDate => _releaseDate;
  final String? _albumVersion;
  String? get albumVersion => _albumVersion;

  AlbumReleaseDialogViewModel({
    required String albumName,
    required Date? releaseDate,
    required Date? originalDate,
    required String? albumVersion,
  })  : _albumName = albumName,
        _releaseDate = releaseDate,
        _originalDate = originalDate,
        _albumVersion = albumVersion;
}
