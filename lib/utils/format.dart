part of u_app_utils;

class Format {
  static String numberStr(double? number, {bool simple = false, String format = '#,##0.00'}) {
    return number != null ?
      (simple ? number.toString().replaceAll('.', ',') : NumberFormat(format, 'ru_RU').format(number)) :
      '';
  }

  static String dateStr(DateTime? date) {
    return date != null ? DateFormat.yMd('ru').format(date) : '';
  }

  static String dateTimeStr(DateTime? dateTime) {
    return dateTime != null ? DateFormat.yMd('ru').add_Hm().format(dateTime) : '';
  }

  static String timeStr(DateTime? dateTime) {
    return dateTime != null ? DateFormat.Hm('ru').format(dateTime) : '';
  }

  static String timeStrFromInt(int value) {
    final int hour = value ~/ 60;
    final int minutes = value % 60;

    return '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Courtesy https://stackoverflow.com/a/71263526/5382447
  /// Wrap your string.
  /// @param line - String line which need to be wrapped.
  /// @param wrapLength - Wrapping threshold. Must be greater than 1.
  /// @return
  ///
  static List<String> wrapLine(String line, int wrapLength) {
    List<String> resultList = [];

    if (line.isEmpty) {
      resultList.add("");
      return resultList;
    }

    if (line.length <= wrapLength) {
      resultList.add(line);
      return resultList;
    }

    List<String> words = line.split(" ");

    for (String word in words) {
      if (resultList.isEmpty) {
        _addNewWord(resultList, word, wrapLength);
      } else {
        String lastLine = resultList.last;

        if (lastLine.length + word.length < wrapLength) {
          lastLine = "$lastLine$word ";
          resultList.last = lastLine;
        } else if (lastLine.length + word.length == wrapLength) {
          lastLine = lastLine + word;
          resultList.last = lastLine;
        } else {
          if (_isThereMuchSpace(lastLine, wrapLength.toDouble())) {
            _breakLongWord(resultList, word, wrapLength, lastLine.length);
          } else {
            _addNewWord(resultList, word, wrapLength);
          }
        }
      }
    }

    return resultList;
  }

  static void _addNewWord(List<String> resultList, String word, int wrapLength) {
    if (word.length < wrapLength) {
      resultList.add("$word ");
    } else if (word.length == wrapLength) {
      resultList.add(word);
    } else {
      _breakLongWord(resultList, word, wrapLength, 0);
    }
  }

  static void _breakLongWord(List<String> resultList, String word, int wrapLength, int offset) {
    String part = word.substring(0, (wrapLength - offset) - 1);

    if (offset > 1) {
      String lastLine = resultList.last;
      lastLine = "$lastLine$part-";
      resultList.last = lastLine;
    } else {
      resultList.add("$part-");
    }

    String nextPart = word.substring((wrapLength - offset) - 1, word.length);

    if (nextPart.length > wrapLength) return _breakLongWord(resultList, nextPart, wrapLength, 0);
    if (nextPart.length == wrapLength) return resultList.add(nextPart);

    return resultList.add("$nextPart ");
  }

  static bool _isThereMuchSpace(String line, double lineLength) {
    double expectedPercent = (lineLength * 65) / 100;
    if (line.length <= expectedPercent) return true;
    return false;
  }
}
