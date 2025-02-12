import 'dart:convert';
import 'dart:developer';

import '../constants.dart';
import 'package:http/http.dart' as http;

import '../utils/sharedPreferencesHelper.dart';
import 'device_registration_service.dart';
import 'location_service.dart';

class MarkAttendanceService {
  static const String baseUrl = baseURL;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    // Add any other required headers like authentication tokens
  };
  final _locationService = LocationService();
  Map<String, dynamic> _locationData = {};

  // getting the location on the startup.
  Future<void> _initializeLocation() async {
    final location = await _locationService.getCurrentLocationAddress();

    _locationData = location;
    log(_locationData['coordinates'].toString());

    await SharedPrefsHelper.removeKey('lat');
    await SharedPrefsHelper.removeKey('long');

    await SharedPrefsHelper.setLatitude(
        _locationData['coordinates']['latitude']);
    await SharedPrefsHelper.setLongitude(
        _locationData['coordinates']['longitude']);
  }

  final http.Client _client;

  MarkAttendanceService({http.Client? client})
      : _client = client ?? http.Client();

  Future markAttendance(
    String empId,
    String type, {
    String? image = '',
    String? attendanceType,
  }) async {
    await _initializeLocation();
    try {
      String? deviceToken = await SharedPrefsHelper.getDeviceToken();
      String? data = await SharedPrefsHelper.getLocationData();
      double? lat = await SharedPrefsHelper.getLatitude();
      double? long = await SharedPrefsHelper.getLongitude();

      var locationId;

      // Check if data is null or empty and extract locationId
      if (data != null) {
        Map<String, dynamic> result = json.decode(data);

        // Check if the map is empty
        if (result.isNotEmpty) {
          var firstEntry = result.entries.first;
          locationId = firstEntry.value;
          log('Location ID: $locationId'); // Log locationId for debugging
        } else {
          log('No location data available.');
          return 'Location data is missing.';
        }
      } else {
        log('No data found in SharedPreferences.');
        return 'Location data not found.';
      }

      // Validate locationId before proceeding
      if (locationId == null) {
        return 'Location ID is not available.';
      }

      // Prepare the body for the request
      var requestBody = {
        "type": type,
        "employeeId": int.parse(empId),
        "locationId": locationId,
        "lat": lat,
        "long": long,
        "deviceToken": deviceToken ?? '', // Ensure deviceToken is not null
        "image": image,
      };

      // Add attendanceType to the request body if it's provided
      if (attendanceType != null) {
        requestBody["action"] = attendanceType;
      }

      // Making the API request
      final response = await _client.post(
        Uri.parse('$baseUrl/api/MarkAttendence/MarkAttendence'),
        headers: headers,
        body: json.encode(requestBody),
      );

      // Check for response status code
      if (response.statusCode != 200) {
        return 'Failed to Mark Attendance. Status code: ${response.statusCode}';
      }

      // Parse JSON response
      final responseData = json.decode(response.body);

      // Check if response is successful
      if (responseData['isSuccess'] == true) {
        // return responseData['content']; // Return the content if successful

        return {
          'isSuccess': responseData['isSuccess'],
          'message': responseData['content']
        };
      }

      // Return error message if exists
      // return responseData['errorMessage'] ?? 'An unknown error occurred.';
      return {
        'isSuccess': responseData['isSuccess'],
        'message': responseData['errorMessage']
      };
    } catch (e) {
      // Catch any other exceptions
      log('Error Marking Attendance: $e');
      return 'Error Marking Attendance: $e';
    }
  }
}
