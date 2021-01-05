import 'package:mudder_dart/src/js_shim.dart';
import 'package:test/test.dart';

void main() {
  group('js_shim tests', () {
    final string = "abc";
    
    test('test repeat', () {
      final result = JSShim.repeat(string, 3);
      expect(result, string + string + string);

      final result2 = JSShim.repeat(string, 0);
      expect(result2, "");
    });

    test('test reduceRight', () {
      final array = [1, 2, 3];
      var result = JSShim.reduceRight(
          array, (prev, curr, index, list) => prev + curr, 20);
      expect(result, 26);
    });

    test('test reduceRight without reduced result', () {
      final array = [1, 2, 3];
      var result = 20;
      JSShim.reduceRight(array, (_, curr, index, list) {
        result += curr;
      }, null);
      expect(result, 26);
    });
  });
}
