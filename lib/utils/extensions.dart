import 'dart:math';

// Taken from https://github.com/dart-lang/sdk/issues/8575#issuecomment-704111947
extension DoubleRounding on double {
  double floorDigits(int digits) {
    if (digits == 0) {
      return floorToDouble();
    } else {
      final divideBy = pow(10, digits);
      return ((this * divideBy).floorToDouble() / divideBy);
    }
  }

  double roundDigits(int digits) {
    if (digits == 0) {
      return roundToDouble();
    } else {
      final divideBy = pow(10, digits);
      return ((this * divideBy).roundToDouble() / divideBy);
    }
  }

  double ceilDigits(int digits) {
    if (digits == 0) {
      return ceilToDouble();
    } else {
      final divideBy = pow(10, digits);
      return ((this * divideBy).ceilToDouble() / divideBy);
    }
  }
}

extension DateTimeX on DateTime {
  DateTime date() {
    return DateTime(year, month, day);
  }
}
