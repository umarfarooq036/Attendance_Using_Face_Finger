// lib/services/fingerprint_api_service.dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pbi_time/constants.dart';

class ApiResponse<T> {
  final T? data;

  ApiResponse({this.data});

  /// Converts the object to a map
  Map<String, dynamic> toMap() {
    return {
      'data': data,
    };
  }

  /// Creates an instance from a JSON map
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      data: json['data'] as T?,
    );
  }
}

class FingerprintApiService {
  static const String baseUrl = baseURL;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    // Add any other required headers like authentication tokens
  };

  final http.Client _client;

  FingerprintApiService({http.Client? client})
      : _client = client ?? http.Client();

  // Future<ApiResponse<Map<String, dynamic>>> _handleResponse(
  //     http.Response response) async {
  //   try {
  //     final responseData = json.decode(response.body);
  //
  //     if (response.statusCode >= 200 && response.statusCode < 300) {
  //       return ApiResponse(
  //         isSuccess: responseData['content'],
  //         data: responseData,
  //         content: responseData['content']
  //       );
  //     } else {
  //       return ApiResponse(
  //         success: false,
  //         error: responseData['message'] ?? 'Unknown error occurred',
  //       );
  //     }
  //   } catch (e) {
  //     return ApiResponse(
  //       success: false,
  //       error: 'Failed to process response: ${e.toString()}',
  //     );
  //   }
  // }

  Future<ApiResponse<dynamic>> canAddFingerprint(String id) async {
    // dynamic apiResponse;
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/EmployeeManagement/CanAddFinger?EmployeeId=$id'),
        headers: headers,
      );

      // final apiResponse = await _handleResponse(response);
      // final apiResponse = await json.decode(response.body);
      return ApiResponse(
          // isSuccess: apiResponse['isSuccess'],
          data: await json.decode(response.body));
      // errorMessage: apiResponse['errorMessage'],
      // content: apiResponse['content'],
      // successMessage: apiResponse['successMessage']);
    } catch (e) {
      return ApiResponse(
          // isSuccess: apiResponse['isSuccess'],
          data: {
            "isSuccess": false,
          });
      // errorMessage: apiResponse['errorMessage'],
      // content: apiResponse['content'],
      // successMessage: apiResponse['successMessage']);
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String employeeId,
    required String fingerprintData, required List<String> images,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/EmployeeManagement/AddFingers'),
        headers: headers,
        body: json.encode({
          'employeeId': employeeId,
          'fingers': fingerprintData,
          'images':images
        }),
      );

      // return await _handleResponse(response);
      return await json.decode(response.body);
    } catch (e) {
      return {
        "isSuccess": false,
      };
    }
  }

  //
  Future<ApiResponse<dynamic>> getUserList() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/EmployeeManagement/GetFingers'),
        headers: headers,
      );

      // final apiResponse = await _handleResponse(response);
      // final apiResponse = await json.decode(response.body);
      return ApiResponse(
        // success: apiResponse.success,
        data: await json.decode(response.body),
        // error: apiResponse.error,
      );
    } catch (e) {
      return ApiResponse(data: {
        'isSuccess': false,
      });
    }
  }
  //
  // Future<ApiResponse<bool>> deleteUser(String userId) async {
  //   try {
  //     final response = await _client.delete(
  //       Uri.parse('$baseUrl/api/users/$userId'),
  //       headers: headers,
  //     );
  //
  //     final apiResponse = await _handleResponse(response);
  //     return ApiResponse(
  //       success: apiResponse.success,
  //       data: apiResponse.success,
  //       error: apiResponse.error,
  //     );
  //   } catch (e) {
  //     return ApiResponse(
  //       success: false,
  //       error: 'Failed to delete user: ${e.toString()}',
  //     );
  //   }
  // }
  //
  // Future<ApiResponse<bool>> clearAllUsers() async {
  //   try {
  //     final response = await _client.delete(
  //       Uri.parse('$baseUrl/api/users'),
  //       headers: headers,
  //     );
  //
  //     final apiResponse = await _handleResponse(response);
  //     return ApiResponse(
  //       success: apiResponse.success,
  //       data: apiResponse.success,
  //       error: apiResponse.error,
  //     );
  //   } catch (e) {
  //     return ApiResponse(
  //       success: false,
  //       error: 'Failed to clear users: ${e.toString()}',
  //     );
  //   }
  // }

  Future<int?> getEmployeeId(String employeeCode) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/EmployeeManagement/GetEmployeeId?EmployeeCode=$employeeCode'),
        headers: headers,
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        // Decode the response body
        final data = json.decode(response.body);

        // Check if 'isSuccess' is true in the response
        if (data != null && data['isSuccess'] == true) {
          // Extract employeeId from the content
          final employeeId = data['content'];
          if (employeeId is int) {
            return employeeId; // Return the employeeId
          } else {
            throw Exception("Invalid employeeId format in the response");
          }
        } else {
          throw Exception(
              data?['errorMessage'] ?? "Failed to fetch employee ID");
        }
      } else {
        throw Exception("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      // Log the error and rethrow or return null
      if (kDebugMode) {
        print("Error in getEmployeeId: $e");
      }
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
