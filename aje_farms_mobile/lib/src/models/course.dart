import 'package:flutter/material.dart';

enum LessonType {
  reading('Somo', Icons.article_outlined),
  video('Video', Icons.play_circle_outline);

  const LessonType(this.label, this.icon);

  final String label;
  final IconData icon;
}

class Lesson {
  const Lesson({
    required this.title,
    required this.type,
    required this.meta,
    required this.description,
    this.id,
    this.sourceTitle,
    this.resourceUrl,
    this.isPremium = false,
    this.isCompleted = false,
  });

  final String? id;
  final String title;
  final LessonType type;
  final String meta;
  final String description;
  final String? sourceTitle;
  final String? resourceUrl;
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
  final List<String> outcomes;
  final List<Lesson> lessons;
}
