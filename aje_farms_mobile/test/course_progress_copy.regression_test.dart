import 'package:aje_farms_mobile/src/features/courses/course_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('course progress copy matches incomplete and completed states', () {
    expect(
      courseProgressMessage(completed: 0, total: 3),
      'Anza na somo la kwanza kisha fuata mpangilio wa masomo.',
    );
    expect(
      courseProgressMessage(completed: 1, total: 3),
      'Umekamilisha somo 1 kati ya 3. Endelea na somo linalofuata.',
    );
    expect(
      courseProgressMessage(completed: 3, total: 3),
      'Umemaliza masomo yote. Unaweza kurudia masomo au kumuuliza Mwalimu AI swali la kozi.',
    );
  });
}
