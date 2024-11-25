import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:pbi_time/screens/face_recognition/face_authentication_screen.dart';
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
  String? _selectedLocation;
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
            _locations.isNotEmpty ? _locations.keys.first : null;
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
      // await _initializeLocation();

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('PBI Attendance',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF17a2b8),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _locations.isEmpty
                            ? Container(
                                width: MediaQuery.of(context).size.width,
                                child: Center(
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
                                ),
                              )
                            : DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select Location',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                hint: Text(
                                    'Select a Location'), // Default placeholder
                                value: _selectedLocation,
                                items: [
                                  // Add a default "placeholder" item
                                  DropdownMenuItem(
                                    child: Text('Select Location',
                                        style: TextStyle(color: Colors.grey)),
                                    value: null,
                                  ),
                                  // Add actual location items
                                  ..._locations.keys
                                      .map((locationName) =>
                                          DropdownMenuItem<String>(
                                            value: locationName,
                                            child: Text(locationName),
                                          ))
                                      .toList(),
                                ],
                                onChanged: (value) async {
                                  setState(() {
                                    _selectedLocation = value;

                                    _selectedLocationCode = value != null
                                        ? _locations[value]
                                        : null;

                                    // Optional: Print or use the location code
                                    log('Selected Location Code: $_selectedLocationCode');
                                  });
                                  if (_selectedLocationCode == null) {
                                    await SharedPrefsHelper.removeKey(
                                        'locationData');
                                    return;
                                  }
                                  String jsonString = json.encode({
                                    _selectedLocation: _selectedLocationCode
                                  });
                                  await SharedPrefsHelper.setLocationData(
                                      jsonString);
                                  String? id =
                                      await SharedPrefsHelper.getLocationData();
                                  log(id.toString());
                                },
                              ),
                        SizedBox(height: 20),
                        _buildActionButton(
                          context,
                          text: 'Register',
                          onPressed: _registerOfficeDevice,
                          color: Color(0xFF17a2b8),
                        ),
                        SizedBox(height: 15),
                        _buildActionButton(
                          context,
                          text: 'Face Recognition',
                          onPressed: () {
                            // Navigate to Face Recognition
                            Navigator.pushNamed(
                                context, FaceRecognitionScreen.routeName);
                          },
                          color: Color(0xFF17a2b8),
                        ),
                        SizedBox(height: 15),
                        _buildActionButton(
                          context,
                          text: 'Finger Recognition',
                          onPressed: () {
                            Navigator.pushNamed(
                                context, FingerprintScannerScreen.routeName);
                          },
                          color: Color(0xFF17a2b8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 5,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
            fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
