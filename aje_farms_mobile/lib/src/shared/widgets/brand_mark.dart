import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

/// The official Chuo Kikuu Cha Mtaani mark used in every brand placement.
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
      label: tr('Nembo ya Chuo Kikuu Cha Mtaani'),
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: Image.asset(
            'assets/branding/chuo-kikuu-cha-mtaani-logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
