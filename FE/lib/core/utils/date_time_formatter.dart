class DateTimeFormatter {
  static String dateTime(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.day)}/${_two(local.month)}/${local.year} • ${_two(local.hour)}:${_two(local.minute)}';
  }

  static String time(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  static String date(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.day)}/${_two(local.month)}/${local.year}';
  }

  static String timeAgo(dynamic value) {
    if (value == null) return 'Vừa xong';
    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return 'Vừa xong';

    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return date(dt);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  const DateTimeFormatter._();
}
