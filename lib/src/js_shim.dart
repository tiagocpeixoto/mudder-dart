class JSShim {
  static String repeat(String string, int count) {
    var result = '';
    for (var i = 0; i < count; i++) {
      result += string;
    }
    return result;
  }

  static bool every<E>(List<E> list, bool test(E element, int index)) {
    for (var index = 0; index < list.length; index++) {
      if (!test(list[index], index)) return false;
    }
    return true;
  }

  static dynamic reduceRight<T, E>(
      List<E> list, fn(T prev, E curr, int index, List<E> list),
      [T initialValue]) {
    var value = initialValue;
    for (var index = list.length - 1; index > -1; index--) {
      value = fn(value, list[index], index, list);
    }
    return value;
  }
}
