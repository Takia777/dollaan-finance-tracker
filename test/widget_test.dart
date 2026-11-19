import 'package:dollaan/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('format rupiah', () {
    expect(rupiah(1052000), 'Rp 1.052.000');
    expect(rupiah(8776000.55, decimals: true), 'Rp 8.776.000,55');
    expect(rupiah(25000, sign: true), '+Rp 25.000');
    expect(rupiah(-5000), '-Rp 5.000');
  });

  test('parse input nominal', () {
    expect(parseAmountInput('Rp 25.000'), 25000);
    expect(parseAmountInput(''), isNull);
  });

  test('compact', () {
    expect(compactRp(280000), '280k');
    expect(compactRp(1500000), '1,5 jt');
    expect(compactRp(2000000), '2 jt');
  });
}
