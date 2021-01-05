import 'package:mudder_dart/src/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('helpers tests', () {
    final digits = <int>[1, 2, 3];

    test('test iter', () {
      final result = iter('0', 3);
      expect(result, ['0', '1', '2']);

      final result2 = iter('a', 3);
      expect(result2, ['a', 'b', 'c']);
    });

    test('test range', () {
      final result = range(3);
      expect(result, [0, 1, 2]);
    });

    test('test leftPad', () {
      final result = leftPad(digits, digits.length + 3);
      expect(result, [0, 0, 0, 1, 2, 3]);
    });

    test('test rightPad', () {
      final result = rightPad(digits, digits.length + 3);
      expect(result, [1, 2, 3, 0, 0, 0]);
    });

    test('test zip', () {
      final result = zip(["a", "b"], [1, 2]);
      expect(
          result.toString(), [MapEntry("a", 1), MapEntry("b", 2)].toString());
    });
  });
}
