class Queue {
  final String id;
  final String name;
  final int songCount;
  final int currentIndex;
  final bool isDefault;

  Queue({
    required this.id,
    required this.name,
    required this.songCount,
    required this.currentIndex,
    required this.isDefault,
  });
}
