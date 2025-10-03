import 'package:crossonic/data/repositories/subsonic/models/helpers.dart';
import 'package:crossonic/data/services/opensubsonic/models/artist_info2_model.dart';

class ArtistInfo {
  final String? description;

  ArtistInfo({required this.description});

  factory ArtistInfo.fromArtistInfo2Model(ArtistInfo2Model a) {
    return ArtistInfo(
      description: emptyToNull(a.biography),
    );
  }
}
