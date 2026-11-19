/// Format angka ke Rupiah: 1052000 → "Rp 1.052.000".
String rupiah(num value, {bool decimals = false, bool sign = false}) {
  final negative = value < 0;
  final abs = value.abs();
  final whole = abs.floor();
  final digits = whole.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  var out = 'Rp ${buf.toString()}';
  if (decimals) {
    final cents = ((abs - whole) * 100).round();
    out += ',${cents.toString().padLeft(2, '0')}';
  }
  if (negative) {
    out = '-$out';
  } else if (sign) {
    out = '+$out';
  }
  return out;
}

/// Format ringkas untuk grafik: 280000 → "280k", 1500000 → "1,5 jt".
String compactRp(num value) {
  if (value >= 1000000) {
    final jt = value / 1000000;
    final text = jt == jt.roundToDouble()
        ? jt.toStringAsFixed(0)
        : jt.toStringAsFixed(1).replaceAll('.', ',');
    return '$text jt';
  }
  if (value >= 1000) return '${(value / 1000).round()}k';
  return value.round().toString();
}

/// Ambil angka dari input teks: "Rp 25.000" → 25000.
double? parseAmountInput(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return double.tryParse(digits);
}

const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String shortDate(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';
String dayMonth(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';
String monthYear(DateTime d) => '${_monthsLong[d.month - 1]} ${d.year}';
String monthLong(DateTime d) => _monthsLong[d.month - 1];
String hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

/// "Today 12:30", "Yesterday 08:10", atau "3 Nov 2026".
String friendlyTime(DateTime d) {
  final today = dayOnly(DateTime.now());
  final day = dayOnly(d);
  if (day == today) return 'Today · ${hhmm(d)}';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday · ${hhmm(d)}';
  return shortDate(d);
}
