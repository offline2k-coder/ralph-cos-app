import 'dart:async';
import 'package:flutter/material.dart';
import 'biometric_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BiometricLoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.military_tech,
              size: 120,
              color: Colors.deepOrange.shade700,
            ),
            const SizedBox(height: 24),
            Text(
              'RALPH',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chief of Staff',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.deepOrange.shade300,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.deepOrange,
            ),
          ],
        ),
      ),
    );
  }
}
