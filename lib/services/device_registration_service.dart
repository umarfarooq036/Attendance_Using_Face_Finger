import 'dart:convert';
import '../constants.dart';
import 'package:http/http.dart' as http;

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
        Uri.parse('$baseUrl/Locations/GetLocations'),
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
}
