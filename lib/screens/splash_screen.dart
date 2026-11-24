import 'dart:async';

import 'package:flutter/material.dart';

import 'home_screen.dart';
import '../services/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Same mark as the launcher icon: mint rounded tile with the
            // Material `eco` glyph, on the dark-green plate.
            Container(
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF005032),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF93D5AA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.eco,
                  size: 48,
                  color: Color(0xFF005032),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.text('app_title'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(strings.text('app_subtitle')),
          ],
        ),
      ),
    );
  }
}
