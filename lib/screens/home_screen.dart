// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:pbi_time/authentication/local_authentication.dart';
//
// class HomeScreen extends StatefulWidget {
//   static String routeName = '/home';
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final biometricService = BiometricService();
//
//
// // Check if biometrics is available first
//   void checkAndAuthenticate() async {
//     if (await biometricService.isBiometricsSupported()) {
//       bool authenticated = await biometricService.authenticate(
//         reason: 'Please verify your identity to continue',
//       );
//
//       // Handle result
//       if (authenticated) {
//         // Process payment or protected action
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Success!, You're authenticated")));
//       }
//     } else {
//       // Show alternative authentication method
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: TextButton(
//           onPressed: checkAndAuthenticate,
//           child: Text("Click to authenticate"),
//         ),
//       ),
//     );
//   }
// }
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../firebase/fcm_service.dart';
import '../services/local_authentication.dart';
import '../services/location_service.dart';
import 'Dashboard/dashboard.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String token = "Your Device Token";
  final _fcmService = FCMService();
  final biometricService = BiometricService();
  String biometricMessage = "You're not Authenticated!";
  final _locationService = LocationService();
  Map<String, dynamic>? _locationData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getDeviceToken();
    _initializeLocation();
  }

  // get Device Unique token

  Future<void> _getDeviceToken() async {
    token = (await _fcmService.getDeviceToken())!;
  }

  // getting the location on the startup.
  Future<void> _initializeLocation() async {
    final location = await _locationService.getCurrentLocationAddress();
    setState(() {
      _locationData = location;
    });
  }

  // Check biometrics and authenticate
  Future<void> checkAndAuthenticate() async {
    bool isSupported = await biometricService.isBiometricsSupported();

    if (isSupported) {
      // Log available biometrics
      List<BiometricType> biometrics =
          await biometricService.getAvailableBiometrics();
      debugPrint('Available biometrics: $biometrics');

      // Prompt the user for authentication
      bool authenticated = await biometricService.authenticate(
        reason: 'Please verify your identity to continue',
      );

      if (authenticated) {
        // Authentication successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Success! You're authenticated.")),
        );
        setState(() {
          biometricMessage = "You're authenticated.";
        });
        // Perform your protected action here
      } else {
        // Authentication failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication failed. Please try again.")),
        );
        setState(() {
          biometricMessage = "Authentication failed. Please try again.";
        });
      }
    } else {
      // Biometrics not supported, fallback to alternative authentication
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Biometrics not supported on this device. Use alternative login.",
          ),
        ),
      );
      // Add logic for PIN/password authentication if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Biometric Authentication"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
                width: 300,
                child: Column(
                  children: [
                    const Text(
                      'Device Token: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(token),
                  ],
                )),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(biometricMessage),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            _locationData == null
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      const Text('Address: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_locationData!['address'] ?? 'No location'),
                    ],
                  ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: checkAndAuthenticate,
              child: const Text("Authenticate"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, Dashboard.routeName);
              },
              child: const Text("Go to Dashboard"),
            ),
          ],
        ),
      ),
    );
  }
}
