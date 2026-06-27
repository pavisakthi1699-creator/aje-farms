import 'package:flutter/material.dart';

class PlanOption {
  const PlanOption({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    this.recommended = false,
  });

  final String title;
  final String subtitle;
  final String price;
  final IconData icon;
  final bool recommended;
}
