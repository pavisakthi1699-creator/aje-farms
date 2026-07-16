import 'package:aje_farms_mobile/src/features/courses/course_detail_screen.dart';
import 'package:aje_farms_mobile/src/models/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression: ISSUE-003 — text courses displayed a video play icon
// Found by /qa on 2026-07-16
// Report: .gstack/qa-reports/qa-report-ushuhuda-pilot-2026-07-16.md
void main() {
  test('reading lessons use a book icon in the course hero', () {
    const lesson = Lesson(
      title: 'Somo la maandishi',
      type: LessonType.reading,
      meta: 'Dakika 4',
      description: 'Maelezo',
    );

    expect(lessonHeroIcon(lesson), Icons.menu_book_rounded);
  });

  test('video lessons retain the play icon in the course hero', () {
    const lesson = Lesson(
      title: 'Somo la video',
      type: LessonType.video,
      meta: 'Dakika 4',
      description: 'Maelezo',
    );

    expect(lessonHeroIcon(lesson), Icons.play_arrow_rounded);
  });
}
