extension StringDashExtensions on String? {
  /// Returns "-" when receiver is null or trimmed-empty, otherwise the trimmed value.
  /// Use in UI/display only. NEVER inside a mapper or repository.
  String orDash() {
    final value = this;
    if (value == null) {
      return '-';
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '-';
    }
    return trimmed;
  }
}

extension IntDashExtensions on int? {
  /// Returns "-" when receiver is null or `0`, otherwise `toString()`.
  String orDash() {
    final value = this;
    if (value == null || value == 0) {
      return '-';
    }
    return value.toString();
  }
}

extension DoubleDashExtensions on double? {
  /// Returns "-" when receiver is null or `0`, otherwise `toString()`.
  String orDash() {
    final value = this;
    if (value == null || value == 0) {
      return '-';
    }
    return value.toString();
  }
}

extension DateTimeDashExtensions on DateTime? {
  /// Returns "-" when receiver is null, otherwise the ISO calendar date `yyyy-MM-dd`.
  /// For human-facing dates, prefer a localized formatter (e.g. `DateFormat.yMMMd()`).
  String orDash() {
    final value = this;
    if (value == null) {
      return '-';
    }
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
