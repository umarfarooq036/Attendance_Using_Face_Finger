import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:office_attendance/routes/app_routes.dart';
import 'package:office_attendance/screens/Dashboard/dashboard.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // initialize firebase services
  // _initializeApp();
  runApp(const MyApp());
}

// Future<void> _initializeApp() async {
//   await Firebase.initializeApp();
//   //
//   // final _fcmService = FCMService();
//   // String? token = await _fcmService.getDeviceToken();
//   // log(token.toString());
// }

@pragma('vm:entry-point')
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PBI Time Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: Dashboard.routeName,
      routes: AppRoutes.getRoutes(),
    );
  }
}
