import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

enum LessonType {
  reading('Somo', Icons.article_outlined),
  video('Video', Icons.play_circle_outline);

  const LessonType(this.labelSw, this.icon);

  /// Kiswahili source label; [label] is the display text.
  final String labelSw;
  String get label => tr(labelSw);
  final IconData icon;
}

class Lesson {
  const Lesson({
    required this.title,
    required this.type,
    required this.meta,
    required this.description,
    this.id,
    this.moduleId,
    this.moduleKey,
    this.moduleTitle,
    this.durationMinutes,
    this.sourceTitle,
    this.resourceUrl,
    this.videoPath,
    this.isLearnerVisible = true,
    this.readinessReasons = const [],
    this.isPremium = false,
    this.isCompleted = false,
  });

  final String? id;
  final String? moduleId;
  final String? moduleKey;
  final String? moduleTitle;
  final String title;
  final LessonType type;
  final String meta;
  final String description;
  final int? durationMinutes;
  final String? sourceTitle;

  /// A pasted external video link.
  final String? resourceUrl;

  /// The storage key of a video uploaded through the admin dashboard. Playback
  /// resolves it through `/api/lessons/:id/video-url`, which signs it per
  /// request — the object itself is never public.
  final String? videoPath;
  final bool isLearnerVisible;
  final List<String> readinessReasons;
  final bool isPremium;
  final bool isCompleted;
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
    required this.progress,
    required this.imageUrl,
    this.introVideoUrl,
    required this.outcomes,
    required this.lessons,
  });

  final String id;
  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final double progress;
  final String imageUrl;

  /// A short, public orientation video shown on the course preview.
  final String? introVideoUrl;
  final List<String> outcomes;
  final List<Lesson> lessons;
}
