import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

//   Mehtod to get the FCM device token

  Future<String?> getDeviceToken() async {
    try {
      String? token = await _messaging.getToken();
      if (kDebugMode) {
        print("FCM Device Token: $token");
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print("Error retrieving FCM token: $e");
      }
      return null;
    }
  }

//Listen for token refresh
  void listenForTokenRefresh(Function(String) onTokenRefresh) {
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print("FCM Token Refreshed: $newToken");
      }
      onTokenRefresh(newToken);
    });
  }
}
