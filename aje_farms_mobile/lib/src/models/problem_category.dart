import 'package:flutter/material.dart';

class ProblemCategory {
  const ProblemCategory({
    required this.title,
    required this.topic,
    required this.icon,
    required this.color,
    required this.summary,
    required this.examples,
  });

  final String title;
  final String topic;
  final IconData icon;
  final Color color;
  final String summary;
  final List<String> examples;
}
