import 'package:flutter/material.dart';

class MyDateTime {
  static String getFormattedTime(
      {required BuildContext context, required String time}) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    return TimeOfDay.fromDateTime(date).format(context);
  }

  //formatted time for sent and read
  static String getFormattedMessageTime({
    required BuildContext context,
    required String time,
  }) {
    final DateTime send = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();
    final formattedTime = TimeOfDay.fromDateTime(send).format(context);
    if (now.day == send.day &&
        now.month == send.month &&
        now.year == send.year) {
      return formattedTime;
    }

    return now.year == send.year
        ? '$formattedTime - ${send.day} ${_getmonth(send)}'
        : '$formattedTime - ${send.day} ${_getmonth(send)} ${send.year}';
  }

  //getting last message time
  static String getLastMessageTime(
      {required BuildContext context,
      required String time,
      bool showYear = false}) {
    final DateTime send = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();
    if (now.day == send.day &&
        now.month == send.month &&
        now.year == send.year) {
      return TimeOfDay.fromDateTime(send).format(context);
    }

    return showYear
        ? '${send.day} ${_getmonth(send)} ${send.year}'
        : '${send.day} ${_getmonth(send)}';
  }

  //get last active time
  static String getLastActiveTime(
      {required BuildContext context, required String lastActive}) {
    final int i = int.tryParse(lastActive) ?? -1;
    if (i == -1) return 'Last seen not available';

    DateTime time = DateTime.fromMillisecondsSinceEpoch(i);
    final DateTime now = DateTime.now();

    String formattedTime = TimeOfDay.fromDateTime(time).format(context);
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == time.year) {
      return 'last Seen today at $formattedTime';
    }
    if ((now.difference(time).inHours / 24).round() == 1) {
      return 'last Seen yesterday at $formattedTime';
    }
    String month = _getmonth(time);
    return 'Last seen on ${time.day} $month on $formattedTime';
  }

  //get month nme
  static String _getmonth(DateTime date) {
    switch (date.month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'Aug';
      case 9:
        return 'Sept';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
    }
    return 'NA';
  }
}
