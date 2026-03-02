import 'package:crossonic/data/services/methodchannel/android_mediaitem.dart';

enum AndroidLibraryResultCode {
  success(0),
  unknown(-1);

  final int value;
  const AndroidLibraryResultCode(this.value);
}

class AndroidLibraryResult {
  final AndroidLibraryResultCode resultCode;
  final AndroidLibraryParams params;
  final AndroidMediaItem? mediaItem;
  final List<AndroidMediaItem>? mediaItems;

  const AndroidLibraryResult({
    this.resultCode = AndroidLibraryResultCode.success,
    this.params = const AndroidLibraryParams(),
    this.mediaItem,
    this.mediaItems,
  });

  Map<String, dynamic> toMsgData() {
    return {
      "resultCode": resultCode.value,
      "params": params.toMsgData(),
      if (mediaItem != null) "mediaItem": mediaItem!.toMsgData(),
      if (mediaItems != null)
        "mediaItems": mediaItems!.map((m) => m.toMsgData()).toList(),
    };
  }
}

enum AndroidLibraryContentStyle { list, grid }

class AndroidLibraryParams {
  final bool isOffline;
  final bool isRecent;
  final bool isSuggested;
  final AndroidLibraryContentStyle? contentStyle;

  const AndroidLibraryParams({
    this.isOffline = false,
    this.isRecent = false,
    this.isSuggested = false,
    this.contentStyle,
  });

  AndroidLibraryParams.fromMsgData(Map<Object?, dynamic>? data)
    : isOffline = data?["isOffline"] ?? false,
      isRecent = data?["isRecent"] ?? false,
      isSuggested = data?["isSuggested"] ?? false,
      contentStyle = null;

  Map<String, dynamic> toMsgData() {
    return {
      "isOffline": isOffline,
      "isRecent": isRecent,
      "isSuggested": isSuggested,
      if (contentStyle != null) "contentStyle": contentStyle!.name,
    };
  }
}
