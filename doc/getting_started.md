# mudder-dart

Dart version of [mudderjs](https://github.com/fasiha/mudderjs).

Generate lexicographically-spaced strings between two strings from pre-defined alphabets.


## Usage

- Create a new symbol table with the list of characters you want to use. In this example, we consider lowercase hexadecimal strings:

```dart
    final hex = SymbolTable(symbolsString: '0123456789abcdef');
    final hexStrings = hex.mudder(start: 'ffff', end: 'fe0f', numStrings: 3);
    print(hexStrings); // [ 'ff8', 'ff', 'fe8' ]
```

- As a convenience, the following pre-generated symbol table are provided:
    - `base10`: `0-9`,
    - `base62`: `0-9A-Za-z`,
    - `base36`: `0-9a-z` (lower- and upper-case accepted),
    - `alphabet`: `a-z` (lower- and upper-case accepted).


## API

### Constructor

`final m = SymbolTable(symbolsString: ...)` creates a new symbol table using the individual characters of `string`.

### Generate strings

**`m.mudder(start: '', end: '' [, numStrings[, base[, numDivisions]]])`** for strings, or array-of-strings, `start` and `end`, returns a `numStrings`-length (default one) array of strings.

`base` is an integer defaulting to the size of the symbol table `m`, but can be less than it if you, for some reason, wish to use only a subset of the symbol table.

`start` can be lexicographically less than or greater than `end`, but in either case, the returned array will be lexicographically sorted between them.

If `start` or `end` are non-truthy, the first is replaced by the first symbol, and the second is replaced by repeating the final symbol several times—e.g.,
for a numeric symbol table, `start` would default to `0` and `end` to `999999` or similar. This is done so that the strings returned cover 99.99...% of the available string space.

`numDivisions` defaults to `numStrings + 1` and must be greater than `numStrings`. It represents the number of pieces to subdivide the lexical space between `start` and `end`
into—then the returned array will contain the first `numStrings` steps along that grid from `start` to `end`. You can customize `numDivisions` to be (much) larger than `numStrings`
in cases where you know you are going to insert many strings between two endpoints, but only *one (or a few) at a time*.

> For example, if you call `startVal = m.mudder(start: startVal, end: endVal, numStrings: 1)[0]` over and over (overwriting `startVal` each iteration),
> you *halve* the space between the endpoints each call, eventually making the new string very long.
> If you *knew* you were going to do this, you can call `startVal = m.mudder(start: startVal, end: endVal, numStrings: 1, numDivisions: 100)[0]`, i.e., set `numDivisons: 100`,
> to subdivide the space between the endpoints a hundred times (instead of just two times), and return just the first 1/100th step from `start` to `end`.
> This makes your string length grow much more sedately, and you can always reverse `start` and `end` to get the same behavior going in the other direction.
> See [#7](https://github.com/fasiha/mudderjs/issues/7) for numerous examples, and a caveat if you’re using non-truthy `start`.

> If the symbol table was *not* prefix-free, the function will refuse to operate on *strings* `start`/`end` because, without the prefix-free criterion,
> a string can’t be parsed unambiguously: you have to split the string into an array of stringy symbols yourself. Invalid or unrecognized symbols are silently ignored.

**`m.mudder(numStrings: 1)`** is equivalent to `m.mudder(start: '', end: '', numStrings: 1)`. See above.

