import 'package:aje_farms_mobile/src/models/home_topics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts the minimum and maximum supported topic counts', () {
    expect(parseHomeTopics(const ['Mada moja']), const ['Mada moja']);

    final maximum = List.generate(maxHomeTopics, (index) => 'Mada ${index + 1}');
    expect(parseHomeTopics(maximum), maximum);
  });

  test('rejects invalid topic payloads', () {
    final tooMany =
        List.generate(maxHomeTopics + 1, (index) => 'Mada ${index + 1}');

    for (final invalid in <Object?>[
      null,
      const <String>[],
      tooMany,
      const <Object>['Mada', 2],
      const ['Mada', ' '],
      [List.filled(maxHomeTopicLength + 1, 'M').join()],
      const ['Nafaka', ' nafaka '],
    ]) {
      expect(parseHomeTopics(invalid), isNull, reason: '$invalid');
    }
  });

  test('trims valid values and returns an immutable list', () {
    final parsed = parseHomeTopics(const ['  Mifugo  ']);

    expect(parsed, const ['Mifugo']);
    expect(() => parsed!.add('Nafaka'), throwsUnsupportedError);
  });
}
