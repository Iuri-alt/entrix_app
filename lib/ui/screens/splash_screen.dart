import 'package:flutter/material.dart';

import '../widgets/brand.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLockup(markSize: 96, textSize: 40),
            SizedBox(height: 24),
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}
