import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../widgets/tactical_button.dart';
import 'dashboard_screen.dart';

class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _authStatus = 'Not authenticated';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _authStatus = 'Authenticating...';
    });

    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Ralph demands authentication. No excuses.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authStatus = 'Error: $e';
        _isAuthenticating = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      _authStatus = authenticated ? 'Authenticated' : 'Failed';
    });

    if (authenticated && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: 100,
                color: Colors.deepOrange.shade700,
              ),
              const SizedBox(height: 32),
              Text(
                'BIOMETRIC LOGIN',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Required. No exceptions.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isAuthenticating)
                const CircularProgressIndicator(
                  color: Colors.deepOrange,
                )
              else
                TacticalButton(
                  onPressed: _authenticate,
                  icon: Icons.lock_open,
                  label: 'AUTHENTICATE',
                ),
              const SizedBox(height: 16),
              Text(
                _authStatus,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _authStatus == 'Authenticated'
                          ? Colors.green
                          : Colors.red,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
