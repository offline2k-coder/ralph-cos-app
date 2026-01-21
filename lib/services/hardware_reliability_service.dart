import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class HardwareReliabilityService {
  static final HardwareReliabilityService _instance = HardwareReliabilityService._internal();
  factory HardwareReliabilityService() => _instance;
  HardwareReliabilityService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return true; // Fallback if no hardware

      return await _auth.authenticate(
        localizedReason: 'RALPH requires biometric verification for access.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric Error: $e');
      return false;
    }
  }

  // Note: True battery optimization disabling requires platform-specific code/intents
  // This helper provides the guidance/intent trigger logic for the UI
  Future<void> requestDisableBatteryOptimization() async {
    // In a real app, we would use a package like 'optimize_battery' or 
    // MethodChannel to open the specific settings page.
    // For now, we provide the technical requirement.
    print('RALPH: Requesting manual battery optimization exemption.');
  }
}
