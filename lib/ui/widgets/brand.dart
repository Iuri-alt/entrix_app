import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Nome "Entrix" com o x na cor da marca.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Entri'),
          TextSpan(text: 'x', style: TextStyle(color: AppColors.brand, fontSize: size * 1.05)),
        ],
      ),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Emblema do Entrix (lib/assets/logo_mark.png) com cantos arredondados.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'lib/assets/logo_mark.png',
        width: size,
        height: size,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        semanticLabel: 'Entrix',
      ),
    );
  }
}

/// Emblema + nome, usado no splash, no login e no menu lateral.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.markSize = 72, this.textSize = 36, this.vertical = true});

  final double markSize;
  final double textSize;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final children = [
      BrandMark(size: markSize),
      SizedBox(width: vertical ? 0 : 10, height: vertical ? 14 : 0),
      BrandWordmark(size: textSize),
    ];
    return vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
