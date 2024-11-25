import 'package:pbi_time/screens/Dashboard/dashboard.dart';
import 'package:pbi_time/screens/face_recognition/face_authentication_screen.dart';
import 'package:pbi_time/screens/finger_authentication/finger_auth_screen.dart';
import 'package:pbi_time/screens/home_screen.dart';

class AppRoutes {
  static getRoutes() {
    return {
      HomeScreen.routeName: (context) => const HomeScreen(),
      Dashboard.routeName: (context) => const Dashboard(),
      FingerprintScannerScreen.routeName: (context) => const FingerprintScannerScreen(),
      FaceRecognitionScreen.routeName : (context) => const FaceRecognitionScreen(),
    };
  }
}
