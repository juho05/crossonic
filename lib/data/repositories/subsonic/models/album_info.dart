import 'package:crossonic/data/services/opensubsonic/models/album_info_model.dart';

class AlbumInfo {
  final String? description;

  AlbumInfo({required this.description});

  factory AlbumInfo.fromAlbumInfoModel(AlbumInfoModel a) {
    return AlbumInfo(
      description: a.notes,
    );
  }
}
