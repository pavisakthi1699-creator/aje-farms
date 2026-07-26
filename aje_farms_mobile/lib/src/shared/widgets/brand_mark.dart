import 'package:flutter/material.dart';

/// The official AJE Farms mark used in every in-app brand placement.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 48,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Nembo ya AJE Farms',
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: Image.asset(
            'assets/branding/aje-farms-logo.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
