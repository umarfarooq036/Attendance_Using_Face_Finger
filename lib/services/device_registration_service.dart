import 'dart:convert';
import 'dart:developer';
import '../constants.dart';
import 'package:http/http.dart' as http;

import '../models/device.dart';

class DeviceRegistrationService {
  static const String baseUrl = baseURL;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    // Add any other required headers like authentication tokens
  };

  final http.Client _client;

  DeviceRegistrationService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, int>> getLocations() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/Locations/GetLocations/0'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Parse JSON response
        final data = json.decode(response.body);

        // Extract content and map locationName to id
        final locations = data['content']['\$values'] as List<dynamic>;

        final Map<String, int> locationMap = {
          for (var location in locations)
            location['locationName']: location['id'] as int,
        };

        return locationMap; // Return the map
      } else {
        throw Exception(
            'Failed to load locations. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      throw Exception('Error fetching locations: $e');
    }
  }

  Future<String?> registerOfficeDevice(
      String deviceToken, int locationId, String deviceName) async {
    try {
      final response = await _client.post(
          Uri.parse('$baseUrl/api/DeviceManagement/RegisterOfficeDevice'),
          headers: headers,
          body: json.encode({
            "deviceToken": deviceToken,
            "deviceName": deviceName,
            "location": locationId
          }));

      if (response.statusCode != 200) {
        return 'Failed to fetch data. Status code: ${response.statusCode}';
      }

// Parse JSON response
      final data = json.decode(response.body);

      if (data['isSuccess'] == true) {
        return data['content']; // Return content if successful
      }

      return data['errorMessage'] ?? 'An unknown error occurred';
    } catch (e) {
      // Handle errors
      throw Exception('Error Registering Device: $e');
    }
  }


  Future<Device?> checkIsRegisteredFromServer(String token) async {
    try {
      // Make the POST request
      final response = await _client.post(
        Uri.parse('$baseUrl/api/DeviceManagement/CheckDevice'),
        headers: headers,
        body: json.encode({'deviceToken': token}),
      );

      // Check if the response status code indicates success
      if (response.statusCode == 200) {
        // Parse the JSON response
        final responseData = json.decode(response.body);

        // Check if the response contains the required fields
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('isSuccess')) {
          bool isSuccess = responseData['isSuccess'] ?? false;
          String? errorMessage = responseData['errorMessage'];
          String? successMessage = responseData['successMessage'];
          dynamic content = responseData['content'];

          if (isSuccess) {
            // If the registration check is successful, parse the content into a Device object
            if (content != null && content is Map<String, dynamic>) {
              Device device = Device.fromJson(
                  content); // Create Device from response content
              log('Device registration check succeeded. Device: $device');
              return device; // Return the device object
            } else {
              log('Device registration check succeeded but content is not a valid device object.');
              return null;
            }
          } else {
            // Log the failure message and return null
            log('Device registration check failed. Error: $errorMessage');
            return null;
          }
        } else {
          log('Invalid response structure: $responseData');
          throw Exception('Invalid response from server.');
        }
      } else {
        // Handle non-200 status codes
        log('Failed to check registration. Status code: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors or exceptions during the process
      log('Error checking registration: $e');
      rethrow; // Optionally rethrow the exception if needed
    }
  }
}
