extension StringExtensions on String? {
  String orEmpty() => this ?? '';
}

extension ListExtensions<T> on List<T>? {
  List<T> orEmpty() => this ?? [];
}

extension IntExtensions on int? {
  int orZero() => this ?? 0;
}

extension DoubleExtensions on double? {
  double orZero() => this ?? 0.0;
}

extension BoolExtensions on bool? {
  bool orFalse() => this ?? false;
  bool? orNull() => this == false ? null : this;
}

extension StringOrNullExtensions on String {
  String? orNull() => isNotEmpty ? this : null;
}

extension ListOrNullExtensions<T> on List<T> {
  List<T>? orNull() => isNotEmpty ? this : null;
}

extension IntOrNullExtensions on int {
  int? orNull() => this == 0 ? null : this;
}

extension DoubleOrNullExtensions on double {
  double? orNull() => this == 0 ? null : this;
}

extension DateTimeOrNullExtensions on DateTime? {
  /// ISO-8601 calendar date `yyyy-MM-dd`, or null when receiver is null.
  /// Use in Request mappers to send a date string or omit the field.
  String? toIsoDate() {
    final value = this;
    if (value == null) {
      return null;
    }
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
