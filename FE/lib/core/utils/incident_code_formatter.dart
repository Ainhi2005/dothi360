class IncidentCodeFormatter {
  const IncidentCodeFormatter._();

  static String format(String id, DateTime date) {
    if (id.startsWith('#PA-')) return id;
    final clean = id.replaceAll('-', '');
    final suffix = clean.length >= 3
        ? clean.substring(clean.length - 3).toUpperCase()
        : clean.padLeft(3, '0').toUpperCase();
    final yy = (date.year % 100).toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '#PA-$yy$mm-$suffix';
  }
}
