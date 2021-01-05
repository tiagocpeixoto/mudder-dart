import 'dart:math';

import 'package:mudder_dart/src/js_shim.dart';

class Div {
  final List<int> res;
  final int rem;
  final int den;
  final bool carry;

  Div({this.res, this.rem, this.den, this.carry});
}

// bool _isPrefixCode(List<String> strings) {
//   // Note: we skip checking for prefixness if two symbols are equal to each
//   // other. This implies that repeated symbols in the input are *silently
//   // ignored*!
//   for (final i in strings) {
//     for (final j in strings) {
//       if (j == i) {
//         // [🍅]
//         continue;
//       }
//       if (i.startsWith(j)) {
//         return false;
//       }
//     }
//   }
//   return true;
// }

bool _isPrefixCodeLogLinear(List<String> _strings) {
  final strings = [..._strings]..sort(); // set->array or array->copy
  // strings.sort();
  for (var i = 0; i < strings.length; i++) {
    final curr = strings[i];
    final prev = i > 0 ? strings[i - 1] : null; // undefined for first iteration
    if (prev == curr) {
      // Skip repeated entries, match quadratic API
      continue;
    }
    if (prev != null && curr.startsWith(prev)) {
      // str.startsWith(undefined) always false
      return false;
    }
  }
  return true;
}

bool Function(List<String>) isPrefixCode = _isPrefixCodeLogLinear;

List<String> iter(String char, int len) => List.generate(
      len,
      (i) => String.fromCharCode(char.codeUnitAt(0) + i),
    );

List<int> range(int len) {
  return List.generate(len, (i) => i);
}

List<int> leftPad(List<int> digits, int finalLength, [int val]) {
  final padLen = max(0, finalLength - digits.length);
  return List.filled(padLen, val ?? 0, growable: true)..addAll(digits);
}

List<int> rightPad(List<int> digits, int finalLength, [int val]) {
  final padLen = max(0, finalLength - digits.length);
  return digits.toList()..addAll(List.filled(padLen, val ?? 0));
}

List<MapEntry<String, int>> zip(List<String> a, List<int> b) {
  return List.generate(a.length, (i) => MapEntry(a[i], b[i]));
}

bool allLessThan(List<String> arr) {
  for (var i = 1; i < arr.length; i++) {
    if (arr[i - 1].compareTo(arr[i]) > 0) {
      return false;
    }
  }
  return true;
}

bool allGreaterThan(List<String> arr) {
  return allLessThan(arr.toList().reversed.toList());
}

Div longDiv(List<int> numeratorArr, int den, int base) {
  return numeratorArr.fold(Div(res: [], rem: 0, den: den), (prev, curr) {
    var newNum = curr + prev.rem * base;
    return Div(
      res: prev.res..add((newNum / den).floor()),
      rem: newNum % den,
      den: den,
    );
  });
}

const defaultList = <int>[];

///
/// @param {number[]} a larger number, as digits array
/// @param {number[]} b smaller number, as digits array
/// @param {number} base
/// @param {[number, number]} rem `a` and `b`'s remainders
/// @param {number} den denominator for the remainders
/// @returns {{res: number[], den: number, rem: number}}
Div longSubSameLen(
  List<int> a,
  List<int> b,
  int base, [
  List<int> rem = defaultList,
  int den = 0,
]) {
  if (a.length != b.length) {
    throw Exception('same length arrays needed');
  }
  if (rem.isNotEmpty && rem.length != 2) {
    throw Exception('zero or two remainders expected');
  }
  a = [...a]; // pre-emptively copy
  if (rem.isNotEmpty) {
    a = a..add(rem[0]);
    b = [...b]..add(rem[1]);
  }
  final ret = List.filled(a.length, 0);

  // this is a LOOP LABEL! https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/label
  OUTER:
  for (var i = a.length - 1; i >= 0; --i) {
    // console.log({a, ret})
    if (a[i] >= b[i]) {
      ret[i] = a[i] - b[i];
      continue;
    }
    if (i == 0) {
      throw Exception('cannot go negative');
    }
    // look for a digit to the left to borrow from
    for (var j = i - 1; j >= 0; --j) {
      if (a[j] > 0) {
        // found a non-zero digit. Decrement it
        a[j]--;
        // increment digits to its right by `base-1`
        for (var k = j + 1; k < i; ++k) {
          a[k] += base - 1;
        }
        // until you reach the digit you couldn't subtract
        ret[i] =
            a[i] + (rem.isNotEmpty && i == a.length - 1 ? den : base) - b[i];
        continue OUTER;
      }
    }
    // should have `continue`d `OUTER` loop
    throw Exception('failed to find digit to borrow from');
  }
  if (rem.isNotEmpty) {
    // ret.slice(0, -1)
    return Div(
      res: ret.sublist(0, ret.length - 1),
      rem: ret[ret.length - 1],
      den: den,
    );
  }
  return Div(res: ret, rem: 0, den: den);
}

///
/// @param {number[]} a array of digits
/// @param {number[]} b array of digits
/// @param {number} base
/// @param {number} rem remainder
/// @param {number} den denominator under remainder
Div longAddSameLen(List<int> a, List<int> b, int base, int rem, int den) {
  if (a.length != b.length) {
    throw Exception('same length arrays needed');
  }
  var carry = rem >= den, res = [...b];
  if (carry) {
    rem -= den;
  }
  JSShim.reduceRight(a, (_, ai, index, list) {
    final result = ai + b[index] + (carry ? 1 : 0);
    carry = result >= base;
    res[index] = carry ? result - base : result;
    return null;
  }, null);
  return Div(res: res, rem: rem, den: den, carry: carry);
}

/// Returns `(a + (b-a)/M*n)` for n=[1, 2, ..., N], where `N<M`.
/// @param {number[]} a left array of digits
/// @param {number[]} b right array of digits
/// @param {number} base
/// @param {number} N number of linearly-spaced numbers to return
/// @param {number} M number of subdivisions to make, `M>N`
/// @returns {{res: number[]; rem: number; den: number;}[]} `N` numbers
List<Div> longLinspace(List<int> prev, List<int> next, int base, int N, int M) {
  if (prev.length < next.length) {
    prev = rightPad(prev, next.length);
  } else if (next.length < prev.length) {
    next = rightPad(next, prev.length);
  }
  if (prev.length == next.length &&
      JSShim.every(prev, (prevElem, index) => prevElem == next[index])) {
    throw Exception('Start and end strings lexicographically inseparable');
  }
  final prevDiv = longDiv(prev, M, base);
  final nextDiv = longDiv(next, M, base);
  var prevPrev = longSubSameLen(prev, prevDiv.res, base, [0, prevDiv.rem], M);
  var nextPrev = nextDiv;
  final ret = <Div>[];
  for (var n = 1; n <= N; ++n) {
    final x = longAddSameLen(
        prevPrev.res, nextPrev.res, base, prevPrev.rem + nextPrev.rem, M);
    ret.add(x);
    prevPrev = longSubSameLen(
        prevPrev.res, prevDiv.res, base, [prevPrev.rem, prevDiv.rem], M);
    nextPrev = longAddSameLen(
        nextPrev.res, nextDiv.res, base, nextPrev.rem + nextDiv.rem, M);
  }
  return ret;
}

List<int> chopDigits(List<int> rock, List<int> water) {
  for (var idx = 0; idx < water.length; idx++) {
    final waterValue = idx < water.length ? water[idx] : null;
    final rockValue = idx < rock.length ? rock[idx] : null;
    if (waterValue != null && waterValue != 0 && rockValue != waterValue) {
      return water.sublist(0, idx + 1);
    }
  }
  return water;
}

bool lexicographicLessThanArray(List<int> a, List<int> b) {
  final n = min(a.length, b.length);
  for (var i = 0; i < n; i++) {
    if (a[i] == b[i]) {
      continue;
    }
    return a[i] < b[i];
  }
  return a.length < b.length;
}

List<List<int>> chopSuccessiveDigits(List<List<int>> digits) {
  final reversed = !lexicographicLessThanArray(digits[0], digits[1]);
  if (reversed) {
    digits = digits.reversed.toList();
  }
  final sliced = digits.sublist(1);
  var result = sliced.fold([digits[0]], (accum, curr) {
    final arrayToConcat = [chopDigits(accum[accum.length - 1], curr)];
    return accum..addAll(arrayToConcat);
  });
  if (reversed) {
    result = result.reversed.toList();
  }
  return result;
}

List<dynamic> truncateLexHigher(dynamic lo, dynamic hi) {
  String loStr = lo is List<String> ? lo.join("") : lo;
  String hiStr = hi is List<String> ? hi.join("") : hi;

  final swapped = loStr.compareTo(hiStr) > 0;
  if (swapped) {
    final temp = lo;
    lo = hi;
    hi = temp;
  }
  if (swapped) {
    return [hi, lo];
  }
  return [lo, hi];
}
