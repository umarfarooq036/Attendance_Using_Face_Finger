

import 'package:office_attendance/screens/finger_authentication/finger_auth_screen.dart';

import '../screens/Dashboard/dashboard.dart';
import '../screens/Mannual Registration/mannual_registration.dart';
import '../screens/Register_User_Face_Finger/face_Registration_screen.dart';
import '../screens/Register_User_Face_Finger/finger_Registration_screen.dart';
import '../screens/Register_User_Face_Finger/register_user.dart';
import '../screens/face_attendance/face_authentication_screen.dart';
import '../screens/home_screen.dart';

class AppRoutes {
  static getRoutes() {
    return {
      HomeScreen.routeName: (context) => const HomeScreen(),
      Dashboard.routeName: (context) => const Dashboard(),
      FingerprintScannerScreen.routeName: (context) =>
          const FingerprintScannerScreen(),
      FaceRecognitionScreen.routeName: (context) =>
          const FaceRecognitionScreen(),
      ManualAttendanceScreen.routeName: (context) =>
          const ManualAttendanceScreen(),
      RegistrationScreen.routeName: (context) => const RegistrationScreen(),
      FaceRegistrationScreen.routeName: (context) =>
          const FaceRegistrationScreen(),
      FingerprintRegistrationScreen.routeName: (context) =>
          const FingerprintRegistrationScreen(),
    };
  }
}
