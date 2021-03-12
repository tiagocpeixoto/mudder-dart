import 'dart:collection';
import 'dart:math';

import 'package:mudder_dart/src/helpers.dart';
import 'package:mudder_dart/src/js_shim.dart';

/* Constructor:
symbolsArr is a string (split into an array) or an array. In either case, it
maps numbers (array indexes) to stringy symbols. Its length defines the max
radix the symbol table can handle.

symbolsMap is optional, but goes the other way, so it can be an object or Map.
Its keys are stringy symbols and its values are numbers. If omitted, the
implied map goes from the indexes of symbolsArr to the symbols.

When symbolsMap is provided, its values are checked to ensure that each number
from 0 to max radix minus one is present. If you had a symbol as an entry in
symbolsArr, then number->string would use that symbol, but the resulting
string couldn't be parsed because that symbol wasn't in symbolMap.
*/
class SymbolTable {
  late List<String> num2sym;
  late Map<String, int> sym2num;
  late int maxBase;

  bool? _isPrefixCode;

  SymbolTable({
    String? symbolsString,
    List<String>? symbolsArray,
    Map<String, int>? symbolsMap,
  }) {
    // Condition the input `symbolsArr`
    if (symbolsArray != null) {
      num2sym = symbolsArray;
    } else {
      if (symbolsString != null && symbolsString.isNotEmpty) {
        num2sym = symbolsString.split('');
      } else {
        throw Exception('symbolsArr and symbolsStr must not be null or empty');
      }
    }

    // Condition the second input, `symbolsMap`. If no symbolsMap passed in,
    // make it by inverting symbolsArr. If it's an object (and not a Map),
    // convert its own-properties to a Map.
    if (symbolsMap != null) {
      sym2num = symbolsMap;
    } else {
      sym2num = HashMap();
      // for (var i = 0; i < num2sym.length; i++) {
      //   sym2num.putIfAbsent(num2sym[i], () => i);
      // }
      sym2num = HashMap.fromIterable(num2sym,
          key: (element) => element as String,
          value: (element) => num2sym.indexOf(element as String));
    }

    // `symbolsMap`
    var symbolsValuesSet = Set.of(sym2num.values);
    for (var i = 0; i < num2sym.length; i++) {
      if (!symbolsValuesSet.contains(i)) {
        throw Exception(
            '${num2sym.length} symbols given but $i not found in symbol table');
      }
    }

    maxBase = num2sym.length;
    _isPrefixCode = isPrefixCode(num2sym);
  }

  List<String> mudder({
    dynamic start,
    dynamic end,
    int? numStrings,
    int? base,
    int? numDivisions,
  }) {
    if (start != null && start is! String && start is! List<String>) {
      throw Exception('start param must be of type String or List<String>');
    }

    if (end != null && end is! String && end is! List<String>) {
      throw Exception('end param must be of type String or List<String>');
    }

    start = notEmptyString(start) ?? num2sym[0];

    int? length;
    if (start is String) {
      length = start.length;
    } else if (start is List) {
      length = start.length;
    } else {
      throw Exception('Illegal state. Length must not be null');
    }

    end = notEmptyString(end) ??
        JSShim.repeat(num2sym[num2sym.length - 1], length + 6);
    numStrings ??= 1;
    base ??= maxBase;
    numDivisions ??= numStrings + 1;

    final truncated = truncateLexHigher(start, end);
    start = truncated[0];
    end = truncated[1];
    final prevDigits = stringToDigits(start);
    final nextDigits = stringToDigits(end);
    final intermediateDigits =
        longLinspace(prevDigits, nextDigits, base, numStrings, numDivisions);
    final finalDigits = intermediateDigits
        .map((v) => v.res..addAll(roundFraction(v.rem, v.den!, base)))
        .toList();
    finalDigits.insert(0, prevDigits);
    finalDigits.add(nextDigits);
    return chopSuccessiveDigits(finalDigits)!
        .sublist(1, finalDigits.length - 1)
        .map(digitsToString)
        .toList();
  }

  List<int> roundFraction(int numerator, int denominator, int? base) {
    base = base ?? maxBase;
    var places = (log(denominator) / log(base)).ceil();
    var scale = pow(base, places);
    var scaled = (numerator / denominator * scale).round();
    var digits = numberToDigits(scaled, base);
    return leftPad(digits, places, 0);
  }

  List<int> numberToDigits(int num, [int? base]) {
    base ??= maxBase;
    var digits = <int>[];
    while (num >= 1) {
      digits.add(num % base);
      num = (num / base).floor();
    }
    return digits.isNotEmpty ? digits.reversed.toList() : [0];
  }

  String digitsToString(List<int> digits) {
    return digits.map((n) => num2sym[n]).join('');
  }

  List<int> stringToDigits(dynamic string) {
    if (string is String) {
      if (_isPrefixCode == null || !_isPrefixCode!) {
        throw Exception(
            'parsing string without prefix code is unsupported. Pass in array '
            'of stringy symbols?');
      }
      final re = RegExp('(${List.from(sym2num.keys).join('|')})');
      return re
          .allMatches(string)
          .map<String>((e) => e.input.substring(e.start, e.end))
          .map<int>((symbol) {
        final num = sym2num[symbol];
        if (num != null) return num;
        throw Exception('Undefined value for sym2num with key $symbol');
      }).toList();
    }

    if (string is List<String>) {
      return string.map((e) {
        final num = sym2num[e];
        if (num != null) return num;
        throw Exception('Undefined value for sym2num with key $e');
      }).toList();
    }

    throw Exception("param must be of type String or List<String>");
  }

  int? digitsToNumber(List<int> digits, [int? base]) {
    base ??= maxBase;
    var currBase = 1;
    return JSShim.reduceRight<dynamic, int>(digits, (prev, curr, index, list) {
      var ret = prev + curr * currBase;
      currBase *= base!;
      return ret;
    }, 0) as int?;
  }

  String numberToString(int num, [int? base]) {
    return digitsToString(numberToDigits(num, base));
  }

  int? stringToNumber(String num, [int? base]) {
    return digitsToNumber(stringToDigits(num), base);
  }
}

final base10 = SymbolTable(symbolsArray: iter('0', 10));

final base62 = SymbolTable(
    symbolsArray: iter('0', 10)..addAll(iter('A', 26))..addAll(iter('a', 26)));

// Base36 should use lowercase since that’s what Number.toString outputs.
final _base36arr = iter('0', 10)..addAll(iter('a', 26));
final _base36keys = [..._base36arr]..addAll(iter('A', 26));
final _base36vals = range(10)
  ..addAll(range(26).map((i) => i + 10))
  ..addAll(range(26).map((i) => i + 10));
final base36 = SymbolTable(
    symbolsArray: _base36arr,
    symbolsMap: Map.fromEntries(zip(_base36keys, _base36vals)));

final alphabet = SymbolTable(
  symbolsArray: iter('a', 26),
  symbolsMap: Map.fromEntries(
    zip(
      iter('a', 26)..addAll(iter('A', 26)),
      range(26)..addAll(range(26)),
    ),
  ),
);
