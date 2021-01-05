import 'package:mudder_dart/mudder_dart.dart';

void main() {
  final hex = SymbolTable(symbolsString: '0123456789abcdef');
  final hexStrings = hex.mudder(start: 'ffff', end: 'fe0f', numStrings: 3);
  print(hexStrings); // [ 'ff8', 'ff', 'fe8' ]

  final base62Strings =
      base62.mudder(start: 'ffff', end: 'fe0f', numStrings: 3);
  print(base62Strings); // [ 'ff', 'feq', 'feQ' ]
}
