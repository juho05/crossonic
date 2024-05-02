import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:crossonic/repositories/subsonic/models/media_model.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum SongPopupMenuValue {
  addToPriorityQueue,
  addToQueue,
  remove,
  gotoAlbum,
  gotoArtist
}

enum SongLeadingItem { none, track, cover }

class Song extends StatefulWidget {
  final Media song;
  final SongLeadingItem leadingItem;
  final bool showArtist;
  final bool showAlbum;
  final bool showYear;
  final bool showGotoAlbum;
  final bool showGotoArtist;
  final bool showAddToQueue;
  final int? reorderIndex;
  final void Function()? onRemove;
  final void Function()? onTap;
  const Song({
    super.key,
    required this.song,
    this.leadingItem = SongLeadingItem.none,
    this.showArtist = false,
    this.showAlbum = false,
    this.showYear = false,
    this.showGotoAlbum = true,
    this.showGotoArtist = true,
    this.showAddToQueue = true,
    this.reorderIndex,
    this.onRemove,
    this.onTap,
  });

  @override
  State<Song> createState() => _SongState();
}

class _SongState extends State<Song> {
  var _playbackStatus = CrossonicPlaybackStatus.stopped;
  var _isCurrent = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final duration = widget.song.duration != null
        ? Duration(seconds: widget.song.duration!)
        : null;
    return BlocBuilder<NowPlayingCubit, NowPlayingState>(
      buildWhen: (previous, current) {
        final isCurrent = current.hasMedia && current.songID == widget.song.id;
        bool rebuild = isCurrent != _isCurrent ||
            current.playbackState.status != _playbackStatus;
        _isCurrent = isCurrent;
        _playbackStatus = current.playbackState.status;
        return rebuild;
      },
      builder: (context, state) {
        final isCurrent = state.hasMedia && state.songID == widget.song.id;
        _isCurrent = isCurrent;
        _playbackStatus = state.playbackState.status;
        final leadingChildren = [
          if (widget.reorderIndex != null)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.drag_handle),
            ),
          if (widget.song.track != null &&
              widget.leadingItem == SongLeadingItem.track &&
              !_isCurrent)
            Text(
              widget.song.track.toString().padLeft(2, '0'),
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          if (widget.song.coverArt != null &&
              widget.leadingItem == SongLeadingItem.cover)
            CoverArt(
              size: 40,
              coverID: widget.song.coverArt!,
              resolution: const CoverResolution.tiny(),
              borderRadius: BorderRadius.circular(5),
            ),
        ];
        final theme = Theme.of(context);
        return ListTile(
          leading: widget.reorderIndex == null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isCurrent)
                      IconButton(
                        onPressed: () {
                          context.read<CrossonicAudioHandler>().playPause();
                        },
                        icon: Icon(
                            _playbackStatus == CrossonicPlaybackStatus.playing
                                ? Icons.pause
                                : (_playbackStatus ==
                                        CrossonicPlaybackStatus.loading
                                    ? Icons.hourglass_empty
                                    : Icons.play_arrow),
                            color: theme.colorScheme.primary),
                      ),
                    ...leadingChildren,
                  ],
                )
              : ReorderableDragStartListener(
                  index: widget.reorderIndex!,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: leadingChildren,
                  ),
                ),
          title: Row(
            children: [
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      style: textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.w400, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.song.artist != null && widget.showArtist ||
                        widget.song.album != null && widget.showAlbum ||
                        widget.song.year != null && widget.showYear)
                      Text(
                        [
                          if (widget.song.artist != null && widget.showArtist)
                            widget.song.artist,
                          if (widget.song.album != null && widget.showAlbum)
                            widget.song.album,
                          if (widget.song.year != null && widget.showYear)
                            widget.song.year.toString(),
                        ].join(" • "),
                        style: textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w300, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              )),
              if (widget.song.starred != null)
                const Icon(Icons.favorite, size: 15),
              if (widget.song.duration != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${duration!.inHours > 0 ? '${duration.inHours}:' : ''}${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                    style: textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          horizontalTitleGap: 0,
          contentPadding: EdgeInsets.only(
              left: widget.reorderIndex != null ? 8 : (_isCurrent ? 0 : 16),
              right: 5),
          trailing: widget.showAddToQueue ||
                  widget.onRemove != null ||
                  widget.showGotoAlbum ||
                  widget.showGotoArtist
              ? PopupMenuButton<SongPopupMenuValue>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    final audioHandler = context.read<CrossonicAudioHandler>();
                    switch (value) {
                      case SongPopupMenuValue.addToPriorityQueue:
                        audioHandler.mediaQueue.addToPriorityQueue(widget.song);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Added "${widget.song.title}" to priority queue'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(milliseconds: 1250),
                        ));
                      case SongPopupMenuValue.addToQueue:
                        audioHandler.mediaQueue.add(widget.song);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('Added "${widget.song.title}" to queue'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(milliseconds: 1250),
                        ));
                      case SongPopupMenuValue.remove:
                        widget.onRemove!();
                      case SongPopupMenuValue.gotoAlbum:
                        context.push("/home/album/${widget.song.albumId}");
                      case SongPopupMenuValue.gotoArtist:
                        context.push("/home/artist/${widget.song.artistId}");
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    if (widget.showAddToQueue)
                      const PopupMenuItem(
                        value: SongPopupMenuValue.addToPriorityQueue,
                        child: ListTile(
                          leading: Icon(Icons.playlist_play),
                          title: Text('Add to priority queue'),
                        ),
                      ),
                    if (widget.showAddToQueue)
                      const PopupMenuItem(
                        value: SongPopupMenuValue.addToQueue,
                        child: ListTile(
                          leading: Icon(Icons.playlist_add),
                          title: Text('Add to queue'),
                        ),
                      ),
                    if (widget.onRemove != null)
                      const PopupMenuItem(
                        value: SongPopupMenuValue.remove,
                        child: ListTile(
                          leading: Icon(Icons.playlist_remove),
                          title: Text('Remove'),
                        ),
                      ),
                    if (widget.showGotoAlbum && widget.song.albumId != null)
                      const PopupMenuItem(
                        value: SongPopupMenuValue.gotoAlbum,
                        child: ListTile(
                          leading: Icon(Icons.album),
                          title: Text('Go to album'),
                        ),
                      ),
                    if (widget.showGotoArtist && widget.song.artistId != null)
                      const PopupMenuItem(
                        value: SongPopupMenuValue.gotoArtist,
                        child: ListTile(
                          leading: Icon(Icons.person),
                          title: Text('Go to artist'),
                        ),
                      ),
                  ],
                )
              : const SizedBox(),
          onTap: widget.onTap,
        );
      },
    );
  }
}