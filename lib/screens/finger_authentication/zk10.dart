import 'package:flutter/services.dart';

@pragma('vm:entry-point')
class ZKFingerprint {
  static const MethodChannel _channel = MethodChannel('zkfingerprint_channel');

  static Future<void> setupErrorHandling() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'deviceOpenError') {
        print('Device Open Error: ${call.arguments}');
        // Handle or log the error
      }
    });
  }


  Future<String> startCapture() async {
    return await _channel.invokeMethod('startCapture');
  }

  Future<String> stopCapture() async {
    return await _channel.invokeMethod('stopCapture');
  }

  Future<String> registerUser(String userId) async {
    return await _channel.invokeMethod('registerUser', {'userId': userId});
  }

  Future<String> identifyUser() async {
    return await _channel.invokeMethod('identifyUser');
  }

  Future<String> deleteUser(String userId) async {
    return await _channel.invokeMethod('deleteUser', {'userId': userId});
  }

  Future<String> clearAllUsers() async {
    return await _channel.invokeMethod('clearAllUsers');
  }
}
