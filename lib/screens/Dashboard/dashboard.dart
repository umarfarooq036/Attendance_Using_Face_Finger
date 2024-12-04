import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pbi_time/screens/Mannual%20Registration/mannual_registration.dart';
import 'package:pbi_time/screens/Register_User_Face_Finger/register_user.dart';
import 'package:pbi_time/screens/face_attendance/face_authentication_screen.dart';

import 'package:pbi_time/services/device_registration_service.dart';
import 'package:pbi_time/utils/sharedPreferencesHelper.dart';
import 'package:pbi_time/utils/snackBar.dart';
import 'package:shimmer/shimmer.dart';

import '../../firebase/fcm_service.dart';
import '../../services/location_service.dart';
import '../finger_authentication/finger_auth_screen.dart';

class Dashboard extends StatefulWidget {
  static String routeName = '/dashboard';
  const Dashboard({super.key});
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String token = "Your Device Token";
  final _fcmService = FCMService();
  final _locationService = LocationService();
  final _registrationService = DeviceRegistrationService();
  Map<String, dynamic>? _locationData;

  Map<String, dynamic> _locations = {};
  String _selectedLocation = '';
  int? _selectedLocationCode;
  String deviceName = 'UnKnown Device';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getSavedOfficeLocation();
    _initializeData();
  }

  Future<void> _getSavedOfficeLocation() async {
    String? data = await SharedPrefsHelper.getLocationData();

// Check if the data is not null before decoding
    if (data != null) {
      // Decode the JSON string into a Map<String, int>
      Map<String, int> result = Map<String, int>.from(json.decode(data));

      setState(() {
        // Set the _locations Map
        _locations = result;

        // Set the _selectedLocation to the first key of the Map (if it exists)
        _selectedLocation =
            (_locations.isNotEmpty ? _locations.keys.first : null)!;
        _selectedLocationCode = _locations[_selectedLocation];
      });

      // Log the locations data
      log(_locations.toString());
    } else {
      // Handle the case where the data is null
      log('No location data found in SharedPreferences.');
    }
  }

  Future<void> _initializeData() async {
    try {
      // Fetch the device token
      await _getDeviceToken();

      // Fetch the current location
      await _initializeLocation();

      // Fetch locations from the API
      await _fetchLocations();

      // Save data to preferences after fetching all required information
      await _saveDataToPreferences();
    } catch (e) {
      log('Error initializing data: $e');
      // Handle errors gracefully (e.g., show an error message)
    }
  }

  Future<void> _getDeviceToken() async {
    token = (await _fcmService.getDeviceToken())!;
  }

  // getting the location on the startup.
  Future<void> _initializeLocation() async {
    final location = await _locationService.getCurrentLocationAddress();
    setState(() {
      _locationData = location;
      log(_locationData!['coordinates'].toString());
    });
  }

  Future<void> _fetchLocations() async {
    try {
      final locations = await _registrationService.getLocations();
      deviceName = await getDeviceName();
      setState(() {
        _locations = locations;
      });
    } catch (e) {
      // Handle errors
      print('Error loading locations: $e');
    }
  }

  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.manufacturer} ${androidInfo.model}'; // e.g., Samsung Galaxy S21
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name ?? 'Unknown iOS Device'; // e.g., iPhone 13 Pro
    } else {
      return 'Unknown Device';
    }
  }

  Future<void> _saveDataToPreferences() async {
    try {
      await SharedPrefsHelper.setDeviceToken(token);
      // await SharedPrefsHelper.setLatitude(
      //     _locationData?['coordinates']['latitude']);
      // await SharedPrefsHelper.setLongitude(
      //     _locationData?['coordinates']['longitude']);

      // Retrieve and log the saved data
      String? savedToken = await SharedPrefsHelper.getDeviceToken();
      double? savedLatitude = await SharedPrefsHelper.getLatitude();
      double? savedLongitude = await SharedPrefsHelper.getLongitude();

      log('Saved Data:');
      log('Device Token: $savedToken');
      log('Latitude: $savedLatitude');
      log('Longitude: $savedLongitude');
    } catch (e) {
      SnackbarHelper.showSnackBar(context, 'Error saving data: $e',
          type: SnackBarType.error);
    }
  }

  Future<void> _registerOfficeDevice() async {
    try {
      // Ensure that _selectedLocationCode is not null before proceeding
      if (_selectedLocationCode == null) {
        SnackbarHelper.showSnackBar(context, 'Please select a location',
            type: SnackBarType.error);
        return; // Stop execution if location is not selected
      }

      // Call the registration service
      String? message = await _registrationService.registerOfficeDevice(
          token, _selectedLocationCode!, deviceName);

      // Check if the message is null or valid
      if (message != null && message.isNotEmpty) {
        SnackbarHelper.showSnackBar(context, message,
            type: SnackBarType.success);
      } else {
        SnackbarHelper.showSnackBar(
            context, 'Registration successful, but no message returned',
            type: SnackBarType.success);
      }
    } catch (e, stackTrace) {
      // Log the error for debugging purposes
      log('Error during device registration: $e',
          error: e, stackTrace: stackTrace);

      // Show error snack bar
      SnackbarHelper.showSnackBar(context, 'Registration Failed: $e',
          type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'PBI Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF17a2b8),
        elevation: 0,
      ),
      body: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    children: [
                      // Location Dropdown with Registration Icons
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: _locations.isEmpty
                                ? Center(
                                    child: Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: const Text(
                                        'Loading...',
                                        style: TextStyle(
                                          fontSize: 28.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    height: 45,
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Select Location',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        constraints: BoxConstraints(
                                          maxWidth: screenWidth * 0.9,
                                        ),
                                      ),
                                      isExpanded: true,
                                      hint: Text(
                                        'Select Location',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: screenWidth * 0.035,
                                        ),
                                      ),
                                      value: _selectedLocation.isEmpty
                                          ? null
                                          : _selectedLocation,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.035,
                                      ),
                                      items:
                                          _locations.keys.map((locationName) {
                                        return DropdownMenuItem<String>(
                                          value: locationName,
                                          child: Text(
                                            locationName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) async {
                                        if (value != null) {
                                          setState(() {
                                            _selectedLocation = value;
                                            _selectedLocationCode =
                                                _locations[value];

                                            log('Selected Location Code: $_selectedLocationCode');
                                          });

                                          String jsonString = json.encode({
                                            _selectedLocation:
                                                _selectedLocationCode
                                          });
                                          await SharedPrefsHelper
                                              .setLocationData(jsonString);
                                          String? id = await SharedPrefsHelper
                                              .getLocationData();
                                          log(id.toString());
                                        } else {
                                          setState(() {
                                            _selectedLocation = '';
                                            _selectedLocationCode = null;
                                          });
                                          await SharedPrefsHelper.removeKey(
                                              'locationData');
                                        }
                                      },
                                    ),
                                  ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          // Device Registration Icons
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: _registerOfficeDevice,
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF17a2b8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.app_registration,
                                  color: Colors.white,
                                  size: screenWidth * 0.06,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Attendance Options
                      Wrap(
                        spacing: screenWidth * 0.03,
                        runSpacing: screenHeight * 0.02,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildResponsiveButton(
                            context,
                            text: 'Register User',
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, RegistrationScreen.routeName);
                            },
                            color: const Color(0xFF17a2b8),
                            icon: const Icon(Icons.person_add_alt),
                            width: screenWidth * 0.4,
                          ),
                          _buildResponsiveButton(
                            context,
                            text: 'Manual Attendance',
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, ManualAttendanceScreen.routeName);
                            },
                            color: const Color(0xFF17a2b8),
                            icon: const Icon(Icons.assignment_ind),
                            width: screenWidth * 0.4,
                          ),
                          _buildResponsiveButton(
                            context,
                            text: 'Face Attendance',
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, FaceRecognitionScreen.routeName);
                            },
                            color: const Color(0xFF17a2b8),
                            icon: const Icon(Icons.face),
                            width: screenWidth * 0.4,
                          ),
                          _buildResponsiveButton(
                            context,
                            text: 'Finger Attendance',
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, FingerprintScannerScreen.routeName);
                            },
                            color: const Color(0xFF17a2b8),
                            icon: const Icon(Icons.fingerprint),
                            width: screenWidth * 0.4,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// New responsive button method
  Widget _buildResponsiveButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required Color color,
    required Icon icon,
    double? width,
  }) {
    return SizedBox(
      width: width ?? MediaQuery.of(context).size.width * 0.4,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: FittedBox(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // Widget _buildActionButton(
  //   BuildContext context, {
  //   required String text,
  //   required VoidCallback onPressed,
  //   required Color color,
  //   required Icon icon,
  // }) {
  //   double screenWidth = MediaQuery.of(context).size.width;
  //
  //   return ElevatedButton(
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: color,
  //       padding: EdgeInsets.symmetric(
  //         vertical: 15,
  //         horizontal: screenWidth * 0.001, // Responsive padding
  //       ),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(25),
  //       ),
  //       elevation: 5,
  //     ),
  //     onPressed: onPressed,
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         icon,
  //         SizedBox(width: screenWidth * 0.02), // Responsive spacing
  //         Text(
  //           text,
  //           style: TextStyle(
  //             fontSize: screenWidth * 0.023, // Responsive font size
  //             color: Colors.white,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
