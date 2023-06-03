import '../locale/localization_unit.dart';

LocalizationUnit localizeValue(String key, Object value, [List<String>? parents]) {
  final LocalizationUnit localizationUnit = switch (value) {
    String() => StringUnit(key: key, value: value),
    {'value': final String $value, 'desc': final String $desc} => StringWithDescriptionUnit(key: key, value: (value: $value, description: $desc)),
    {'value': final String $value} => StringUnit(key: key, value: $value),
    {
      'other': final String $other,
    } =>
      PluralizedUnit(
        key: key,
        value: (
          zero: value.get('zero'),
          one: value.get('one'),
          two: value.get('two'),
          few: value.get('few'),
          many: value.get('many'),
          other: $other,
          description: value.get('desc')
        ),
      ),
    Map() => NamespacedUnit(key: key, value: _localizeMap(key, value, parents ?? []), parents: parents ?? []),
    _ => throw UnsupportedError('Value "$value" is not supported'),
  };

  return localizationUnit;
}

Map<String, LocalizationUnit> _localizeMap(String parent, Map<dynamic, dynamic> map, List<String> parents) {
  final Map<String, LocalizationUnit> namespacedValue = {};
  for (final MapEntry(:key, :value) in map.entries) {
    final LocalizationUnit tempUnit = localizeValue(key, value);
    if (tempUnit is NamespacedUnit) {
      namespacedValue[key] = localizeValue(key, value, [...parents, parent]);
    } else {
      namespacedValue[key] = tempUnit;
    }
  }
  return namespacedValue;
}

extension on Object {
  T? get<T>(String key) {
    if (this is Map) {
      final Object? value = (this as Map)[key];
      if (value is T) {
        return value;
      }
      return null;
    }
    return null;
  }
}
