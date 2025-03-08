import 'package:intl/intl.dart';

String formatDuration(Duration d) {
  return '${d.inHours > 0 ? '${d.inHours}:' : ''}${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime d) {
  d = d.toLocal();
  DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");
  return format.format(d);
}
