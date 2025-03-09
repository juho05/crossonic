import 'package:intl/intl.dart';

String formatDuration(Duration d, {bool long = false}) {
  if (long) {
    return '${d.inHours > 0 ? '${d.inHours}h ' : ''}${d.inMinutes.remainder(60).toString().padLeft(2, '0')}min ${d.inSeconds.remainder(60).toString().padLeft(2, '0')}s';
  }
  return '${d.inHours > 0 ? '${d.inHours}:' : ''}${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime d) {
  d = d.toLocal();
  DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");
  return format.format(d);
}
