String formatDuration(Duration d) {
  return '${d.inHours > 0 ? '${d.inHours}:' : ''}${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}
