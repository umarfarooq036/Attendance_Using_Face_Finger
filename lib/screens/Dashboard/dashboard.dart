// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
//
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:shimmer/shimmer.dart';
//
// import '../../firebase/fcm_service.dart';
// import '../../models/device.dart';
// import '../../services/device_registration_service.dart';
// import '../../services/location_service.dart';
// import '../../utils/sharedPreferencesHelper.dart';
// import '../../utils/snackBar.dart';
// import '../Mannual Registration/mannual_registration.dart';
// import '../Register_User_Face_Finger/register_user.dart';
// import '../face_attendance/face_authentication_screen.dart';
// import '../finger_authentication/finger_auth_screen.dart';
//
// class Dashboard extends StatefulWidget {
//   static String routeName = '/dashboard';
//   const Dashboard({super.key});
//   @override
//   _DashboardState createState() => _DashboardState();
// }
//
// class _DashboardState extends State<Dashboard> {
//   String token = "Your Device Token";
//   final _fcmService = FCMService();
//   final _locationService = LocationService();
//   final _registrationService = DeviceRegistrationService();
//   Map<String, dynamic>? _locationData;
//
//   Map<String, dynamic> _locations = {};
//   String _selectedLocation = '';
//
//   int? _selectedLocationCode;
//   String deviceName = 'UnKnown Device';
//   bool isRegistered = false;
//   bool _isRegisteringDevice = false;
//   final deviceService = DeviceRegistrationService();
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkIsRegistered(context);
//       _getSavedOfficeLocation();
//       _initializeData();
//     });
//   }
//
//   Future<void> _checkIsRegistered(BuildContext context) async {
//     // Show loading dialog
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Prevent dismissing by tapping outside
//       builder: (BuildContext context) {
//         return Dialog(
//           backgroundColor: Colors.transparent, // Makes background transparent
//           child: Center(
//             child: CircularProgressIndicator(
//               color: Colors.white,
//             ), // Displaying the loader
//           ),
//         );
//       },
//     );
//
//     await _fetchLocations();
//
//     await _getDeviceToken();
//
//     if (token != null) {
//       Device? response = await deviceService.checkIsRegisteredFromServer(token);
//
//       if (response != null) {
//         // final employeeIdFromServer = response.employeeId;
//         // if (employeeIdFromServer != null) {
//         _selectedLocationCode = response.locationId;
//         isRegistered = true;
//         // employeeId = employeeIdFromServer;
//         // await SharedPrefsHelper.setEmployeeId(employeeId!);
//         // await SharedPrefsHelper.setIsRegistered(isRegistered);
//         // }
//       }
//     }
//
//     // Uncomment and implement this if you need to check saved preferences
//     // final checkIsRegistered = await SharedPrefsHelper.getIsRegistered() ?? false;
//     // int? employeeIdFromPrefs = await SharedPrefsHelper.getEmployeeId();
//     // if (checkIsRegistered && employeeIdFromPrefs != null) {
//     //   isRegistered = true;
//     //   _employeeCodeController.text = employeeIdFromPrefs.toString();
//     // }
//
//     // Continue with the rest of the flow
//     _getSavedOfficeLocation();
//     _initializeData();
//
//     // Close the loading dialog
//     Navigator.of(context).pop();
//   }
//
//   Future<void> _getSavedOfficeLocation() async {
//     String? data = await SharedPrefsHelper.getLocationData();
//
// // Check if the data is not null before decoding
//     if (data != null) {
//       // Decode the JSON string into a Map<String, int>
//       Map<String, int> result = Map<String, int>.from(json.decode(data));
//
//       setState(() {
//         // Set the _locations Map
//         _locations = result;
//
//         if (_locations.isNotEmpty) {
//           // Iterate over the map and find the matching location
//           _locations.forEach((key, value) {
//             if (value != null && value['id'] == _selectedLocationCode) {
//               // Update the _selectedLocation and modify the id in the map
//               _selectedLocation = key;
//               _locations[key]['id'] = _selectedLocationCode;
//             }
//           });
//         } else {
//           _selectedLocation = '';
//         }
//
// // Update _selectedLocationCode from the modified map
//         _selectedLocationCode = _selectedLocation != null
//             ? _locations[_selectedLocation]?['id']
//             : '';
//
//       });
//
//       // Log the locations data
//       log(_locations.toString());
//     } else {
//       // Handle the case where the data is null
//       log('No location data found in SharedPreferences.');
//     }
//   }
//
//   Future<void> _initializeData() async {
//     try {
//       // Fetch the device token
//       await _getDeviceToken();
//
//       // Fetch the current location
//       await _initializeLocation();
//
//       // Fetch locations from the API
//       // await _fetchLocations();
//
//       // Save data to preferences after fetching all required information
//       await _saveDataToPreferences();
//     } catch (e) {
//       log('Error initializing data: $e');
//       // Handle errors gracefully (e.g., show an error message)
//     } finally {
//       // Navigator.of(context).pop();
//     }
//   }
//
//   Future<void> _getDeviceToken() async {
//     token = (await _fcmService.getDeviceToken())!;
//   }
//
//   // getting the location on the startup.
//   Future<void> _initializeLocation() async {
//     final location = await _locationService.getCurrentLocationAddress();
//     setState(() {
//       _locationData = location;
//       log(_locationData!['coordinates'].toString());
//     });
//   }
//
//   Future<void> _fetchLocations() async {
//     try {
//       final locations = await _registrationService.getLocations();
//       deviceName = await getDeviceName();
//       setState(() {
//         _locations = locations;
//       });
//     } catch (e) {
//       // Handle errors
//       print('Error loading locations: $e');
//     }
//   }
//
//   Future<String> getDeviceName() async {
//     final deviceInfo = DeviceInfoPlugin();
//
//     if (Platform.isAndroid) {
//       AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//       return '${androidInfo.manufacturer} ${androidInfo.model}'; // e.g., Samsung Galaxy S21
//     } else if (Platform.isIOS) {
//       IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//       return iosInfo.name ?? 'Unknown iOS Device'; // e.g., iPhone 13 Pro
//     } else {
//       return 'Unknown Device';
//     }
//   }
//
//   Future<void> _saveDataToPreferences() async {
//     try {
//       await SharedPrefsHelper.setDeviceToken(token);
//       // await SharedPrefsHelper.setLatitude(
//       //     _locationData?['coordinates']['latitude']);
//       // await SharedPrefsHelper.setLongitude(
//       //     _locationData?['coordinates']['longitude']);
//
//       // Retrieve and log the saved data
//       String? savedToken = await SharedPrefsHelper.getDeviceToken();
//       double? savedLatitude = await SharedPrefsHelper.getLatitude();
//       double? savedLongitude = await SharedPrefsHelper.getLongitude();
//
//       log('Saved Data:');
//       log('Device Token: $savedToken');
//       log('Latitude: $savedLatitude');
//       log('Longitude: $savedLongitude');
//     } catch (e) {
//       SnackbarHelper.showSnackBar(context, 'Error saving data: $e',
//           type: SnackBarType.error);
//     }
//   }
//
//   Future<void> _registerOfficeDevice() async {
//     setState(() {
//       _isRegisteringDevice = true;
//     });
//     try {
//       // Ensure that _selectedLocationCode is not null before proceeding
//       if (_selectedLocationCode == null) {
//         SnackbarHelper.showSnackBar(context, 'Please select a location',
//             type: SnackBarType.error);
//         return; // Stop execution if location is not selected
//       }
//
//       // Call the registration service
//       String? message = await _registrationService.registerOfficeDevice(
//           token, _selectedLocationCode!, deviceName);
//
//       // Check if the message is null or valid
//       if (message != null && message.isNotEmpty) {
//         SnackbarHelper.showSnackBar(context, message,
//             type: SnackBarType.success);
//       } else {
//         SnackbarHelper.showSnackBar(
//             context, 'Registration successful, but no message returned',
//             type: SnackBarType.success);
//       }
//     } catch (e, stackTrace) {
//       // Log the error for debugging purposes
//       log('Error during device registration: $e',
//           error: e, stackTrace: stackTrace);
//
//       // Show error snack bar
//       SnackbarHelper.showSnackBar(context, 'Registration Failed: $e',
//           type: SnackBarType.error);
//     } finally {
//       setState(() {
//         _isRegisteringDevice = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Get screen dimensions
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: const Text(
//           'PBI Attendance',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFF17a2b8),
//         elevation: 0,
//       ),
//       body: Container(
//         height: screenHeight,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(
//             horizontal: screenWidth * 0.02,
//             vertical: screenHeight * 0.02,
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Card(
//                 elevation: 10,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.all(screenWidth * 0.05),
//                   child: Column(
//                     children: [
//                       // Location Dropdown with Registration Icons
//                       Row(
//                         children: [
//                           Expanded(
//                             flex: 4,
//                             child: _locations.isEmpty
//                                 ? Center(
//                                     child: Shimmer.fromColors(
//                                       baseColor: Colors.grey[300]!,
//                                       highlightColor: Colors.grey[100]!,
//                                       child: const Text(
//                                         'Loading...',
//                                         style: TextStyle(
//                                           fontSize: 28.0,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   )
//                                 : SizedBox(
//                                     height: 45,
//                                     child: DropdownButtonFormField<String>(
//                                       decoration: InputDecoration(
//                                         labelText: 'Select Location',
//                                         border: OutlineInputBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(15),
//                                         ),
//                                         constraints: BoxConstraints(
//                                           maxWidth: screenWidth * 0.9,
//                                         ),
//                                       ),
//                                       isExpanded: true,
//                                       hint: Text(
//                                         'Select Location',
//                                         overflow: TextOverflow.ellipsis,
//                                         maxLines: 1,
//                                         style: TextStyle(
//                                           color: Colors.grey,
//                                           fontSize: screenWidth * 0.035,
//                                         ),
//                                       ),
//                                       value: _locations.keys.firstWhere(
//                                         (location) =>
//                                             _locations[location] ==
//                                             _selectedLocationCode,
//                                         orElse: () => '',
//                                       ),
//                                       style: TextStyle(
//                                         color: Colors.black,
//                                         fontSize: screenWidth * 0.035,
//                                       ),
//                                       items:
//                                           _locations.keys.map((locationName) {
//                                         return DropdownMenuItem<String>(
//                                           value: locationName,
//                                           child: Text(
//                                             locationName,
//                                             maxLines: 2,
//                                             overflow: TextOverflow.ellipsis,
//                                             softWrap: true,
//                                             style: TextStyle(
//                                               fontSize: screenWidth * 0.035,
//                                             ),
//                                           ),
//                                         );
//                                       }).toList(),
//                                       onChanged: (value) async {
//                                         if (value != null) {
//                                           setState(() {
//                                             _selectedLocation = value;
//                                             _selectedLocationCode =
//                                                 _locations[value];
//
//                                             log('Selected Location Code: $_selectedLocationCode');
//                                           });
//
//                                           String jsonString = json.encode({
//                                             _selectedLocation:
//                                                 _selectedLocationCode
//                                           });
//                                           await SharedPrefsHelper
//                                               .setLocationData(jsonString);
//                                           String? id = await SharedPrefsHelper
//                                               .getLocationData();
//                                           log(id.toString());
//                                         } else {
//                                           setState(() {
//                                             _selectedLocation = '';
//                                             _selectedLocationCode = null;
//                                           });
//                                           await SharedPrefsHelper.removeKey(
//                                               'locationData');
//                                         }
//                                       },
//                                     ),
//                                   ),
//                           ),
//                           SizedBox(width: screenWidth * 0.02),
//                           // Device Registration Icons
//                           Expanded(
//                             flex: 1,
//                             child: InkWell(
//                               onTap: _registerOfficeDevice,
//                               child: Container(
//                                 padding: EdgeInsets.all(screenWidth * 0.02),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFF17a2b8),
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: Icon(
//                                   Icons.app_registration,
//                                   color: Colors.white,
//                                   size: screenWidth * 0.06,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       SizedBox(height: screenHeight * 0.02),
//
//                       // Attendance Options
//                       Wrap(
//                         spacing: screenWidth * 0.03,
//                         runSpacing: screenHeight * 0.02,
//                         alignment: WrapAlignment.center,
//                         children: [
//                           // _buildResponsiveButton(
//                           //   context,
//                           //   text: "Register Device",
//                           //   onPressed: () {
//                           //     _registerOfficeDevice();
//                           //   },
//                           //   color: const Color(0xFF17a2b8),
//                           //   icon: const Icon(Icons.app_registration),
//                           //   loader: _isRegisteringDevice,
//                           // ),
//                           _buildResponsiveButton(context, text: 'Register User',
//                               onPressed: () {
//                             Navigator.pushNamed(
//                                 context, RegistrationScreen.routeName);
//                           },
//                               color: const Color(0xFF17a2b8),
//                               icon: const Icon(Icons.person_add_alt),
//                               width: screenWidth * 0.4,
//                               loader: false,
//                               isDisabled: !isRegistered),
//                           _buildResponsiveButton(context,
//                               text: 'Manual Attendance', onPressed: () {
//                             Navigator.pushNamed(
//                                 context, ManualAttendanceScreen.routeName);
//                           },
//                               color: const Color(0xFF17a2b8),
//                               icon: const Icon(Icons.assignment_ind),
//                               width: screenWidth * 0.4,
//                               loader: false,
//                               isDisabled: !isRegistered),
//                           _buildResponsiveButton(context,
//                               text: 'Face Attendance', onPressed: () {
//                             Navigator.pushNamed(
//                                 context, FaceRecognitionScreen.routeName);
//                           },
//                               color: const Color(0xFF17a2b8),
//                               icon: const Icon(Icons.face),
//                               width: screenWidth * 0.4,
//                               isDisabled: !isRegistered,
//                               loader: false),
//                           _buildResponsiveButton(
//                             context,
//                             text: 'Finger Attendance',
//                             onPressed: () {
//                               Navigator.pushNamed(
//                                   context, FingerprintScannerScreen.routeName);
//                             },
//                             color: const Color(0xFF17a2b8),
//                             icon: const Icon(Icons.fingerprint),
//                             width: screenWidth * 0.4,
//                             isDisabled: !isRegistered,
//                             loader: false,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildResponsiveButton(
//     BuildContext context, {
//     required String text,
//     required VoidCallback onPressed,
//     required Color color,
//     required Icon icon,
//     double? width,
//     required bool loader,
//     required bool isDisabled, // New parameter to disable the button
//   }) {
//     return SizedBox(
//       width: width ?? MediaQuery.of(context).size.width * 0.4,
//       child: ElevatedButton.icon(
//         onPressed: isDisabled
//             ? null
//             : onPressed, // Disable button if isDisabled is true
//         icon: loader ? SizedBox.shrink() : icon,
//         label: FittedBox(
//           child: loader
//               ? CircularProgressIndicator(
//                   color: Color(0xFF17a2b8),
//                 )
//               : Text(
//                   text,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//         ),
//         style: ElevatedButton.styleFrom(
//           foregroundColor: Colors.white,
//           backgroundColor: loader
//               ? Colors.grey
//               : isDisabled
//                   ? Colors.grey
//                       .withOpacity(0.6) // Change button color if disabled
//                   : color,
//           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       ),
//     );
//   }
// }

//

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../firebase/fcm_service.dart';
import '../../models/device.dart';
import '../../services/device_registration_service.dart';
import '../../services/location_service.dart';
import '../../utils/sharedPreferencesHelper.dart';
import '../../utils/snackBar.dart';
import '../Mannual Registration/mannual_registration.dart';
import '../Register_User_Face_Finger/register_user.dart';
import '../face_attendance/face_authentication_screen.dart';
import '../finger_authentication/finger_auth_screen.dart';

class Dashboard extends StatefulWidget {
  static String routeName = '/dashboard';
  const Dashboard({super.key});
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? token;
  final _fcmService = FCMService();
  final _locationService = LocationService();
  final _registrationService = DeviceRegistrationService();
  Map<String, dynamic>? _locationData;
  Map<String, dynamic> _locations = {};
  String _selectedLocation = '';
  int? _selectedLocationCode;
  String deviceName = 'Unknown Device';
  bool isRegistered = false;
  bool _isRegisteringDevice = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Show loading dialog
      setState(() => _isLoading = true);

      // Step 1: Get device name
      deviceName = await _getDeviceName();

      // Step 2: Get device token
      token = await _fcmService.getDeviceToken();
      if (token == null) throw Exception('Failed to get device token');

      // Step 3: Fetch locations
      await _fetchLocations();

      // Step 4: Check device registration status
      await _checkDeviceRegistration();

      // Step 5: Get current location
      await _getCurrentLocation();

      // Step 6: Load saved office location
      await _loadSavedOfficeLocation();

      // Step 7: Save necessary data to preferences
      await _saveDataToPreferences();
    } catch (e) {
      log('Error initializing data: $e');
      SnackbarHelper.showSnackBar(context, 'Error initializing app: $e',
          type: SnackBarType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name ?? 'Unknown iOS Device';
      }
    } catch (e) {
      log('Error getting device name: $e');
    }
    return 'Unknown Device';
  }

  Future<void> _fetchLocations() async {
    try {
      final locations = await _registrationService.getLocations();
      setState(() => _locations = locations);
    } catch (e) {
      log('Error fetching locations: $e');
      throw Exception('Failed to fetch locations: $e');
    }
  }

  Future<void> _checkDeviceRegistration() async {
    try {
      if (token != null) {
        final Device? response =
            await _registrationService.checkIsRegisteredFromServer(token!);
        if (response != null) {
          setState(() {
            _selectedLocationCode = response.locationId;
            isRegistered = true;
          });
        }
      }
    } catch (e) {
      log('Error checking device registration: $e');
      throw Exception('Failed to check device registration: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocationAddress();
      setState(() => _locationData = location);
    } catch (e) {
      log('Error getting current location: $e');
      throw Exception('Failed to get current location: $e');
    }
  }

  Future<void> _loadSavedOfficeLocation() async {
    try {
      final String? data = await SharedPrefsHelper.getLocationData();
      if (data != null) {
        final Map<String, dynamic> savedLocations = json.decode(data);
        setState(() {
          if (savedLocations.isNotEmpty) {
            final entry = savedLocations.entries.first;
            _selectedLocation = entry.key;
            _selectedLocationCode = entry.value;
          }
        });
      }
    } catch (e) {
      log('Error loading saved location: $e');
    }
  }

  Future<void> _saveDataToPreferences() async {
    try {
      if (token != null) {
        await SharedPrefsHelper.setDeviceToken(token!);
        if (_locationData != null) {
          final coordinates = _locationData!['coordinates'];
          await SharedPrefsHelper.setLatitude(coordinates['latitude']);
          await SharedPrefsHelper.setLongitude(coordinates['longitude']);
        }
      }
    } catch (e) {
      log('Error saving preferences: $e');
      throw Exception('Failed to save preferences: $e');
    }
  }

  Future<void> _registerOfficeDevice() async {
    if (_selectedLocationCode == null) {
      SnackbarHelper.showSnackBar(context, 'Please select a location',
          type: SnackBarType.error);
      return;
    }

    setState(() => _isRegisteringDevice = true);
    try {
      final message = await _registrationService.registerOfficeDevice(
          token!, _selectedLocationCode!, deviceName);

      SnackbarHelper.showSnackBar(
          context, message ?? 'Device registered successfully',
          type: SnackBarType.success);

      // Refresh registration status
      await _checkDeviceRegistration();
    } catch (e) {
      log('Error registering device: $e');
      SnackbarHelper.showSnackBar(context, 'Registration failed: $e',
          type: SnackBarType.error);
    } finally {
      setState(() => _isRegisteringDevice = false);
    }
  }

  Future<void> _handleLocationChange(String? value) async {
    if (value == null || isRegistered) return;

    setState(() {
      _selectedLocation = value;
      _selectedLocationCode = _locations[value];
    });

    try {
      final jsonString =
          json.encode({_selectedLocation: _selectedLocationCode});
      await SharedPrefsHelper.setLocationData(jsonString);
    } catch (e) {
      log('Error saving location change: $e');
      SnackbarHelper.showSnackBar(context, 'Error saving location: $e',
          type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF17a2b8),
          ),
        ),
      );
    }

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
            horizontal: screenWidth * 0.02,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMainCard(screenWidth, screenHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(double screenWidth, double screenHeight) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          children: [
            _buildLocationRow(screenWidth),
            SizedBox(height: screenHeight * 0.02),
            _buildAttendanceOptions(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(double screenWidth) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildLocationDropdown(screenWidth),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          flex: 1,
          child: _buildRegistrationButton(screenWidth),
        ),
      ],
    );
  }

  Widget _buildLocationDropdown(double screenWidth) {
    if (_locations.isEmpty) {
      return Center(
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
      );
    }

    return SizedBox(
      height: 45,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Select Location',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        value: _selectedLocation.isEmpty ? null : _selectedLocation,
        items: _locations.keys.map((locationName) {
          return DropdownMenuItem<String>(
            value: locationName,
            child: Container(
              width: screenWidth * 0.7, // Adjust this value as needed
              child: Text(
                locationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: isRegistered
            ? null
            : _handleLocationChange, // Disable onChanged if registered
        isExpanded: true,
        menuMaxHeight: 300, // Set maximum height for dropdown menu
        alignment: AlignmentDirectional.centerStart,
      ),
    );
  }

  Widget _buildRegistrationButton(double screenWidth) {
    return InkWell(
      onTap: _registerOfficeDevice,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          color: const Color(0xFF17a2b8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _isRegisteringDevice
            ? SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                Icons.app_registration,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
      ),
    );
  }

  Widget _buildAttendanceOptions(double screenWidth, double screenHeight) {
    final attendanceOptions = [
      {
        'text': 'Register User',
        'route': RegistrationScreen.routeName,
        'icon': Icons.person_add_alt,
      },
      {
        'text': 'Manual Attendance',
        'route': ManualAttendanceScreen.routeName,
        'icon': Icons.assignment_ind,
      },
      {
        'text': 'Face Attendance',
        'route': FaceRecognitionScreen.routeName,
        'icon': Icons.face,
      },
      {
        'text': 'Finger Attendance',
        'route': FingerprintScannerScreen.routeName,
        'icon': Icons.fingerprint,
      },
    ];

    return Wrap(
      spacing: screenWidth * 0.03,
      runSpacing: screenHeight * 0.02,
      alignment: WrapAlignment.center,
      children: attendanceOptions.map((option) {
        return _buildResponsiveButton(
          context,
          text: option['text'] as String,
          onPressed: () {
            Navigator.pushNamed(context, option['route'] as String);
          },
          color: const Color(0xFF17a2b8),
          icon: Icon(option['icon'] as IconData),
          width: screenWidth * 0.4,
          loader: false,
          isDisabled: !isRegistered,
        );
      }).toList(),
    );
  }

  Widget _buildResponsiveButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required Color color,
    required Icon icon,
    double? width,
    required bool loader,
    required bool isDisabled,
  }) {
    return SizedBox(
      width: width ?? MediaQuery.of(context).size.width * 0.4,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        icon: loader ? SizedBox.shrink() : icon,
        label: FittedBox(
          child: loader
              ? CircularProgressIndicator(color: Color(0xFF17a2b8))
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: loader
              ? Colors.grey
              : isDisabled
                  ? Colors.grey.withOpacity(0.6)
                  : color,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
