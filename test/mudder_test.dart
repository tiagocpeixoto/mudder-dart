import 'package:mudder_dart/mudder.dart';
import 'package:mudder_dart/src/helpers.dart';
import 'package:mudder_dart/src/js_shim.dart';
import 'package:test/test.dart';

void main() {
  group('mudderjs original tests', () {
    test('readme', () {
      final hex = SymbolTable(symbolsString: '0123456789abcdef');
      final hexStrings = hex.mudder(start: 'ffff', end: 'fe0f', numStrings: 3);
      print(hexStrings);
    });


    test('Reasonable values', () {
      final decimal = SymbolTable(symbolsString: '0123456789');
      final res = decimal.mudder(start: '1', end: '2');
      expect(res[0], "15");
    });

    test('Reversing start/end reverses outputs: controlled cases', () {
      final decimal = SymbolTable(symbolsString: '0123456789');
      for (var num in List.generate(12, (i) => i + 1)) {
        final fwd = decimal.mudder(start: '1', end: '2', numStrings: num);
        final rev = decimal.mudder(start: '2', end: '1', numStrings: num);
        expect(rev.toList().reversed.join(''), fwd.join(''));
        expect(
            fwd.fold(true, (accum, curr) {
              final i = fwd.indexWhere((e) => e == curr);
              return i > 0 && i < fwd.length && fwd[i - 1] != null
                  ? accum && (fwd[i - 1].compareTo(curr) < 0)
                  : true;
            }),
            true);
        expect(
            rev.fold(true, (accum, curr) {
              final i = rev.indexWhere((e) => e == curr);
              return i > 0 && i < rev.length && rev[i - 1] != null
                  ? accum && (rev[i - 1].compareTo(curr) > 0)
                  : true;
            }),
            true);
      }
    });

    test('Constructor with maps', () {
      final arr = '_,I,II,III,IV,V'.split(',');
      final map = Map.of({
        "_": 0,
        "I": 1,
        "i": 1,
        "II": 2,
        "ii": 2,
        "III": 3,
        "iii": 3,
        "IV": 4,
        "iv": 4,
        "V": 5,
        "v": 5
      });
      final romanMap = SymbolTable(symbolsArray: arr, symbolsMap: map);

      expect(
        romanMap.mudder(start: ['i'], end: ['ii'], numStrings: 2),
        ["III", "IIV"],
      );
    });

    test('Matches parseInt/toString', () {
      expect(base36.numberToString(123), (123).toRadixString(36));
      expect(base36.stringToNumber('FE0F'), int.tryParse('FE0F', radix: 36));
    });

    test('Fixes #1: repeated recursive subdivision', () {
      var right = 'z';
      for (var i = 0; i < 50; i++) {
        var newRes = alphabet.mudder(start: 'a', end: right)[0];
        expect('a' != newRes, true);
        expect(right != newRes, true);
        right = newRes;
      }
      expect(right, "aaaaaaaaaaaag");
    });

    test('Fixes #2: throws when fed lexicographically-adjacent strings', () {
      for (var i = 2; i < 10; i++) {
        expect(
            () =>
                alphabet.mudder(start: 'x${JSShim.repeat('a', i)}', end: 'xa'),
            throwsException);
        expect(
            () =>
                alphabet.mudder(start: 'xa', end: 'x${JSShim.repeat('a', i)}'),
            throwsException);
      }
    });

    test('Fixes #3: allow calling mudder with just number', () {
      final values = [
        alphabet.mudder(numStrings: 100),
        base36.mudder(numStrings: 100),
        base62.mudder(numStrings: 100)
      ];
      for (final abc in values) {
        var index = 0;
        expect(abc.every((c) {
          final result = index == 0 || (abc[index - 1].compareTo(c) < 0);
          index++;
          return result;
        }), true);
      }
      expect(alphabet.mudder() != null, true);
    });

    test('More #3: no need to define start/end', () {
      var result = base36.mudder(start: '', end: 'foo', numStrings: 30);
      expect(result.length, 30);
      result = base36.mudder(start: 'foo', end: '', numStrings: 30);
      expect(result.length, 30);
    });

    test('Fix #7: specify number of divisions', () {
      final decimal = SymbolTable(symbolsString: '0123456789');

      var fine = decimal.mudder(start: '9', numStrings: 100);
      var partialFine =
          decimal.mudder(start: '9', numStrings: 5, numDivisions: 101);
      var coarse = decimal.mudder(start: '9', numStrings: 5);

      expect(allLessThan(fine), true);
      expect(allLessThan(partialFine), true);
      expect(allLessThan(coarse), true);
      expect(fine.sublist(0, 5).toString(), partialFine.toString());
      expect(partialFine.length, coarse.length);
      expect(partialFine.toString() != coarse.toString(), true);

      fine = decimal.mudder(start: '9', end: '8', numStrings: 100);
      partialFine = decimal.mudder(
          start: '9', end: '8', numStrings: 5, numDivisions: 101);
      coarse = decimal.mudder(start: '9', end: '8', numStrings: 5);

      expect(allGreaterThan(fine), true);
      expect(allGreaterThan(partialFine), true);
      expect(allGreaterThan(coarse), true);
      // omit last because when going from high to low, the final might be
      // rounded
      expect(
        fine.sublist(0, 4).toString(),
        partialFine.sublist(0, 4).toString(),
      );
    });

    test('Fix #8: better default end', () {
      var result = base36.mudder(start: JSShim.repeat('z', 10))[0] !=
          base36.mudder(start: JSShim.repeat('z', 15))[0];
      expect(result, true);
    });
  });

  group('mudder tests', () {
    group('test mudder', () {
      test('test invalid prev and next', () {
        expect(() => base62.mudder(start: 1), throwsException);
        expect(() => base62.mudder(start: 1), throwsException);
      });

      test('test alphabet mudder simple ', () {
        final result = alphabet.mudder();
        expect(result.length, 1);
        expect(result[0], "m");
      });

      test('test base62 mudder simple', () {
        final result = base62.mudder();
        expect(result.length, 1);
        expect(result[0], "U");
      });

      test('test base62 mudder prev 1', () {
        expect(base62.mudder(start: "1"), ["V"]);
      });

      test('test base62 mudder prev [1]', () {
        expect(base62.mudder(start: ["1"]), ["V"]);
      });

      test('test base62 mudder next 1', () {
        expect(base62.mudder(end: "1"), ["0V"]);
      });

      test('test base62 mudder next [1]', () {
        expect(base62.mudder(end: ["1"]), ["0V"]);
      });

      test('test base62 mudder 3 values ', () {
        final result = base62.mudder(numStrings: 3);
        expect(result.length, 3);
        expect(result, ["F", "U", "k"]);
      });

      test('test base10 mudder', () {
        final result = base10.mudder(start: "0", end: "2");
        expect(result.length, 1);
        expect(result[0], "1");

        final result2 = base10.mudder(start: "0", end: "9");
        expect(result2.length, 1);
        expect(result2[0], "4");
      });

      test('test base36 mudder', () {
        final result = base36.mudder(start: "a", end: "c");
        expect(result.length, 1);
        expect(result[0], "b");
      });
    });

    group('test SymbolTable constructor', () {
      test('test base62', () {
        expect(base62.maxBase == 62, true);
      });

      test('test base36', () {
        expect(base36.maxBase == 36, true);
      });

      test('test base10', () {
        expect(base10.maxBase == 10, true);
      });

      test('test SymbolTable constructor with string', () {
        final string = "abcdefg";
        final symbolTable = SymbolTable(symbolsString: string);
        expect(symbolTable.maxBase == string.length, true);
      });
    });

    group('test SymbolTable methods', () {
      test('test numberToDigits', () {
        expect(base10.numberToDigits(49), [4, 9]);
        expect(base10.numberToDigits(49, 10), [4, 9]);
        expect(base10.numberToDigits(49, 5), [1, 4, 4]);
        expect(base10.numberToDigits(51), [5, 1]);
        expect(base10.numberToDigits(51, 10), [5, 1]);
        expect(base10.numberToDigits(510), [5, 1, 0]);
        expect(base10.numberToDigits(1), [1]);
        expect(base10.numberToDigits(0), [0]);
        expect(base36.numberToDigits(49), [1, 13]);
        expect(base62.numberToDigits(49), [49]);
      });

      test('test digitsToString', () {
        expect(base10.digitsToString([3, 2, 1]), "321");
        expect(base36.digitsToString([10, 11, 12]), "abc");
        expect(base36.digitsToString([3, 15]), "3f");
        expect(base62.digitsToString([10, 11, 12]), "ABC");
        expect(base62.digitsToString([1, 61]), "1z");
      });

      test('test stringToDigits base36', () {
        expect(base36.stringToDigits("a"), [10]);
        expect(base36.stringToDigits("c"), [12]);
      });

      test('test stringToDigits', () {
        expect(base10.stringToDigits("012"), [0, 1, 2]);
        expect(base62.stringToDigits("ABC"), [10, 11, 12]);
        expect(base62.stringToDigits("abc"), [36, 37, 38]);
        expect(base36.stringToDigits("ABC"), [10, 11, 12]);
        expect(base36.stringToDigits("3f"), [3, 15]);
        expect(base36.stringToDigits("abc"), [10, 11, 12]);
        expect(base62.stringToDigits("1z"), [1, 61]);
      });

      test('test digitsToNumber', () {
        expect(base10.digitsToNumber([1, 2]), 12);
        expect(base10.digitsToNumber([0, 1, 2]), 12);
        expect(base10.digitsToNumber([3, 2]), 32);
        expect(base10.digitsToNumber([0, 3, 2]), 32);
        expect(base10.digitsToNumber([1, 2], 5), 7);
        expect(base36.digitsToNumber([1, 2]), 38);
        expect(base62.digitsToNumber([1, 2]), 64);
      });

      test('test numberToString', () {
        expect(base10.numberToString(49), "49");
        expect(base10.numberToString(123), "123");
        expect(base36.numberToString(123), "3f");
        expect(base62.numberToString(123), "1z");
      });

      test('test stringToNumber', () {
        expect(base10.stringToNumber("49"), 49);
        expect(base36.stringToNumber("3f"), 123);
        expect(base62.stringToNumber("1z"), 123);
      });
    });
  });
}
