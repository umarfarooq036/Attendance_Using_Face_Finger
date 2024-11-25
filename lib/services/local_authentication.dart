// import 'package:flutter/material.dart';
// import 'package:local_auth/local_auth.dart';
//
// class BiometricService {
//   static final BiometricService _instance = BiometricService._internal();
//   factory BiometricService() => _instance;
//   BiometricService._internal();
//
//   final LocalAuthentication _auth = LocalAuthentication();
//
//   // Check if device supports biometrics
//   Future<bool> isBiometricsSupported() async {
//     try {
//       return await _auth.canCheckBiometrics;
//     } catch (e) {
//       debugPrint('Error checking biometrics support: $e');
//       return false;
//     }
//   }
//
//   // Main authentication method
//   Future<bool> authenticate({
//     String reason = 'Please authenticate to access the app',
//     bool biometricOnly = false,
//   }) async {
//     try {
//       // First check if biometrics is supported
//       bool canCheckBiometrics = await isBiometricsSupported();
//       if (!canCheckBiometrics) {
//         debugPrint('Biometrics not supported on this device');
//         return false;
//       }
//       // Try to authenticate
//       final bool authenticated = await _auth.authenticate(
//         localizedReason: reason,
//         options: AuthenticationOptions(
//           stickyAuth: true,
//           biometricOnly: biometricOnly,
//           useErrorDialogs: true,
//         ),
//       );
//
//       return authenticated;
//     } catch (e) {
//       debugPrint('Authentication error: $e');
//       return false;
//     }
//   }
//
//   // Get available biometric types
//   Future<List<BiometricType>> getAvailableBiometrics() async {
//     try {
//       return await _auth.getAvailableBiometrics();
//     } catch (e) {
//       debugPrint('Error getting available biometrics: $e');
//       return [];
//     }
//   }
// }
//
// // Usage example in any screen:
// /*
// class _MyScreenState extends State<MyScreen> {
//   final _biometricService = BiometricService();
//
//   Future<void> _authenticateUser() async {
//     bool authenticated = await _biometricService.authenticate(
//       reason: 'Please authenticate to continue',
//     );
//
//     if (authenticated) {
//       // User authenticated successfully
//       // Navigate or perform actions
//     } else {
//       // Authentication failed
//       // Show error message or handle accordingly
//     }
//   }
// }
// */
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device supports biometrics and has enrolled credentials.
  Future<bool> isBiometricsSupported() async {
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometrics support: $e');
      return false;
    }
  }

  /// Main authentication method
  Future<bool> authenticate({
    String reason = 'Please authenticate to access the app',
    bool biometricOnly = false,
  }) async {
    try {
      // Check if biometrics are supported
      bool canUseBiometrics = await isBiometricsSupported();
      if (!canUseBiometrics) {
        debugPrint('Biometrics not supported or no credentials enrolled.');
        return false;
      }

      // Attempt biometric authentication
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  /// Get a list of available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Fallback to device credentials (PIN, pattern, or password) if biometrics fail
  Future<bool> authenticateWithFallback({
    String reason = 'Please authenticate using your device credentials',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow fallback to device credentials
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('Fallback authentication error: $e');
      return false;
    }
  }

  /// Helper method to log available biometric types
  Future<void> logAvailableBiometrics() async {
    List<BiometricType> biometrics = await getAvailableBiometrics();
    debugPrint('Available biometrics: $biometrics');
  }
}
