import 'package:college_circle/data/parsers/catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CatalogParser воспринимает техники из строки JSON', () {
    const raw = '{"schemaVersion":1,"items":['
        '{"id":"a","title":"T","subtitle":"S","durationHint":"1 м","steps":["Шаг один"]}]}';
    final list = CatalogParser.parseTechniques(raw);
    expect(list, hasLength(1));
    expect(list.first.steps, equals(['Шаг один']));
  });

  test('CatalogParser воспринимает достижения', () {
    const raw = '{"schemaVersion":1,"items":['
        '{"id":"1","title":"x","description":"d","icon":"air","rule":"r"}]}';
    final list = CatalogParser.parseAchievements(raw);
    expect(list.first.rule, 'r');
  });
}
