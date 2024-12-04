import 'package:pbi_time/screens/Dashboard/dashboard.dart';
import 'package:pbi_time/screens/Register_User_Face_Finger/finger_Registration_screen.dart';
import 'package:pbi_time/screens/Register_User_Face_Finger/register_user.dart';
import 'package:pbi_time/screens/face_attendance/face_authentication_screen.dart';
import 'package:pbi_time/screens/finger_authentication/finger_auth_screen.dart';
import 'package:pbi_time/screens/home_screen.dart';

import '../screens/Mannual Registration/mannual_registration.dart';
import '../screens/Register_User_Face_Finger/face_Registration_screen.dart';

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
