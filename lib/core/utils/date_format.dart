const _kstOffset = Duration(hours: 9);

/// [dateTime]을 KST 기준 `YYYY.MM.DD`로 쓴다. 기기 시간대와 상관없이 같은 날짜가 나온다.
///
/// API의 일시는 `DateTime.parse`로 읽으면 된다. offset이 있는 값은 UTC로 바뀌므로
/// 그대로 넘겨도 KST 날짜로 표시된다.
String formatDate(DateTime dateTime) {
  final kst = dateTime.toUtc().add(_kstOffset);
  return '${kst.year}.${_twoDigits(kst.month)}.${_twoDigits(kst.day)}';
}

/// 이용 시간(`HH:mm`)을 `09:00 – 22:00`으로 쓴다.
///
/// 24시간 운영은 `00:00 – 24:00`이다. 자정을 넘기는 시간(`22:00`–`02:00`)은 받은 그대로 쓴다.
String formatHours(String open, String close) {
  if (open == close) return '00:00 – 24:00';
  return '$open – $close';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
