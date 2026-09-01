import 'package:intl/intl.dart';

String formatTimestamp(int timestamp) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  DateTime now = DateTime.now();

  // Sprawdzamy, czy wiadomość jest z dzisiaj
  bool isToday = dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day;

  // Jeśli wiadomość jest z dzisiaj → tylko godzina
  if (isToday) {
    return DateFormat('HH:mm').format(dateTime);
  }
  // Jeśli starsza → tylko data
  else {
    return DateFormat('dd-MM').format(dateTime);
  }
}