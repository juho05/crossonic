import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

abstract interface class MediaQueue extends ChangeNotifier {
  // The currently playing song. [fromAdvance] is `true` if the change resulted from a `queue.advance()` call.
  ValueStream<Song?> get current;
  // The currently playing song and the next song. [fromAdvance] is `true` if the change resulted from a `queue.advance()` call.
  ValueStream<
          ({Song? current, Song? next, bool currentChanged, bool fromAdvance})>
      get currentAndNext;

  /// Adds [song] to the end of the regular queue if [priority] is `false`
  /// or to the end of the priority queue if [priority] is `true`.
  void add(Song song, bool priority);

  /// Adds all [songs] to the end of the regular queue if [priority] is `false`
  /// or to the end of the priority queue if [priority] is `true`.
  void addAll(Iterable<Song> songs, bool priority);

  /// Insert [song] at position [index] in the regular queue if [priority] is `false`
  /// or in the priority queue if [priority] is `true`.
  void insert(int index, Song song, bool priority);

  /// Inserts all [songs] at position [index] in the regular queue if [priority] is `false`
  /// or in the priority queue if [priority] is `true`.
  void insertAll(int index, Iterable<Song> songs, bool priority);

  /// Replaces the contents of the regular queue with [songs] and sets the current index to [startIndex].
  /// [songs] must not be empty and `0 <= startIndex < songs.length`.
  void replace(Iterable<Song> songs, [int startIndex = 0]);

  /// Removes the song at position [index] from the regular queue.
  void remove(int index);

  /// Removes the song at position [index] from the priority queue.
  void removeFromPriorityQueue(int index);

  /// Removes all elements in the regular queue after and including [fromIndex] if [queue] is `true`.
  /// Removes all elements in the priority queue if [priorityQueue] is `true`.
  /// If the current index is >= [fromIndex] the next song in the priority queue is set as the current song, otherwise it becomes `null`.
  void clear({bool queue = true, int fromIndex = 0, bool priorityQueue = true});

  /// Sets the current index to [index]. [index] must be a valid position with `0 <= index < queue.length`
  void goTo(int index);

  /// Sets the current song to the song at position [index] in the priority queue
  /// and discards all songs with index < [index] in the priority queue.
  /// [index] must be a valid position with `0 <= index < queue.length`
  void goToPriority(int index);

  /// Shuffle the songs in the regular queue after the current song.
  void shuffleFollowing();

  /// Shuffle the songs in the priority queue.
  void shufflePriority();

  /// Skips to the next song.
  void skipNext();

  // Skips to the previous song.
  void skipPrev();

  /// Advances the queue by one. Only call to update queue in case the player has already started playing the next song.
  void advance();

  // Whether there is a song before the current one.
  bool get canGoBack;
  // Whether there is a song after the current one.
  bool get canAdvance;

  // Whether the first song will be played after the last song in the regular queue.
  ValueStream<bool> get looping;

  // Enable/disable looping.
  void setLoop(bool loop);

  // The number of songs in the regular queue.
  int get length;

  // The number of songs in the priority queue.
  int get priorityLength;

  /// Iterator over the regular queue.
  Iterable<Song> get regular;

  /// The current index in the regular queue.
  int get currentIndex;

  /// Iterator over the priority queue.
  Iterable<Song> get priority;
}
