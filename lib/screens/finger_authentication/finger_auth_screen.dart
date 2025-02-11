// // import 'package:flutter/cupertino.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// //
// // class FingerprintScannerScreen extends StatefulWidget {
// //   static String routeName = '/fingerAuthScreen';
// //   @override
// //   const FingerprintScannerScreen({super.key});
// //   _FingerprintScannerScreenState createState() =>
// //       _FingerprintScannerScreenState();
// // }
// //
// // class _FingerprintScannerScreenState extends State<FingerprintScannerScreen> {
// //   static const platform = MethodChannel('zkfingerprint_channel');
// //   String _statusMessage = "Status: Waiting for action";
// //   Uint8List? _fingerprintImage;
// //
// //   final TextEditingController _userIdController = TextEditingController();
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Listen for method calls from native code
// //     platform.setMethodCallHandler((call) async {
// //       if (call.method == 'updateImage') {
// //         setState(() {
// //           _fingerprintImage = call.arguments;
// //           print("Image Array: $_fingerprintImage");
// //           _statusMessage = "Fingerprint captured successfully!";
// //         });
// //
// // // Start a 3-second delay to clear the image and message
// //         Future.delayed(Duration(seconds: 3), () {
// //           setState(() {
// //             _fingerprintImage = null;
// //             _statusMessage = "Status: Waiting for action";
// //             _userIdController.text = '';
// //           });
// //         });
// //       }
// //       else if(call.method == 'updateTemplate')
// //         {
// //           print('Template Type: ${call.arguments['type']}');
// //           print('Template Base64: ${call.arguments['base64']}');
// //           print('Template Length: ${call.arguments['length']}');
// //         }
// //     });
// //   }
// //
// //   Future<void> _startCapture() async {
// //     try {
// //       final String result = await platform.invokeMethod('startCapture');
// //       setState(() {
// //         _statusMessage = result;
// //       });
// //     } catch (e) {
// //       _showError(e);
// //     }
// //   }
// //
// //   Future<void> _stopCapture() async {
// //     try {
// //       final String result = await platform.invokeMethod('stopCapture');
// //       setState(() {
// //         _statusMessage = result;
// //       });
// //     } catch (e) {
// //       _showError(e);
// //     }
// //   }
// //
// //   Future<void> _registerUser(String userId) async {
// //     try {
// //       final String result = await platform.invokeMethod('registerUser', {
// //         'userId': userId,
// //       });
// //       setState(() {
// //         _statusMessage = result;
// //       });
// //     } catch (e) {
// //       _showError(e);
// //     }
// //   }
// //
// //   Future<void> _identifyUser() async {
// //     try {
// //       final String result = await platform.invokeMethod('identifyUser');
// //       setState(() {
// //         _statusMessage = result;
// //       });
// //     } catch (e) {
// //       _showError(e);
// //     }
// //   }
// //
// //   Future<void> _deleteUser(String userId) async {
// //     try {
// //       final String result = await platform.invokeMethod('deleteUser', {
// //         'userId': userId,
// //       });
// //       setState(() {
// //         _statusMessage = result;
// //       });
// //     } catch (e) {
// //       _showError(e);
// //     }
// //   }
// //
// //   Future<void> _clearAllUsers() async {
// //     try {
// //       final String result = await platform.invokeMethod('clearAllUsers');
// //       setState(() {
// //         _statusMessage = result;
// //       });
// //     } catch (e) {
// //       _showError(e);
// //     }
// //   }
// //
// //   void _showError(Object e) {
// //     setState(() {
// //       _statusMessage = "Error: ${e.toString()}";
// //     });
// //   }
// //
// //   @override
// //   void dispose() {
// //     _userIdController.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Fingerprint Scanner'),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             // Display fingerprint image if available
// //             _fingerprintImage != null
// //                 ? Container(
// //                     height: 200,
// //                     child: Image.memory(_fingerprintImage!),
// //                     decoration: BoxDecoration(
// //                       borderRadius: BorderRadius.circular(12),
// //                       border: Border.all(color: Colors.grey.shade300),
// //                     ),
// //                   )
// //                 : Container(
// //                     height: 200,
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey[200],
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                     child: Center(
// //                       child: Text(
// //                         'Fingerprint Image',
// //                         style: TextStyle(color: Colors.grey.shade600),
// //                       ),
// //                     ),
// //                   ),
// //             SizedBox(height: 20),
// //
// //             // Status message display
// //             Text(
// //               _statusMessage,
// //               textAlign: TextAlign.center,
// //               style: TextStyle(
// //                 fontSize: 16,
// //                 color: Colors.blueGrey,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //             SizedBox(height: 20),
// //
// //             // User ID Input
// //             TextField(
// //               controller: _userIdController,
// //               decoration: InputDecoration(
// //                 labelText: 'User ID',
// //                 border: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(8.0),
// //                 ),
// //                 suffixIcon: Icon(Icons.person),
// //               ),
// //             ),
// //             SizedBox(height: 20),
// //
// //             // Buttons with updated styling
// //             Wrap(
// //               spacing: 10,
// //               runSpacing: 10,
// //               children: [
// //                 ElevatedButton(
// //                   onPressed: _startCapture,
// //                   child: Text('Start Capture'),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.green,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //                   ),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: _stopCapture,
// //                   child: Text('Stop Capture'),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.redAccent,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //                   ),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: () => _registerUser(_userIdController.text),
// //                   child: Text('Register User'),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.blue,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //                   ),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: _identifyUser,
// //                   child: Text('Identify User'),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.orange,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //                   ),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: () => _deleteUser(_userIdController.text),
// //                   child: Text('Delete User'),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.purple,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //                   ),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: _clearAllUsers,
// //                   child: Text('Clear All Users'),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.grey,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                     ),
// //                     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// import 'dart:convert';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shimmer/shimmer.dart';
//
// import '../../constants.dart';
// import '../../services/fingerPrint_apiService.dart';
//
// class FingerprintScannerScreen extends StatefulWidget {
//   static String routeName = '/fingerAuthScreen';
//   @override
//   const FingerprintScannerScreen({super.key});
//   _FingerprintScannerScreenState createState() =>
//       _FingerprintScannerScreenState();
// }
//
// class _FingerprintScannerScreenState extends State<FingerprintScannerScreen> {
//   final _formKey = GlobalKey<FormState>();
//   static const platform = MethodChannel('zkfingerprint_channel');
//   String _statusMessage = "Status: Waiting for action";
//   final FingerprintApiService _apiService = FingerprintApiService();
//   Uint8List? _fingerprintImage;
//   List<String>? image;
//   final TextEditingController _empIdController = TextEditingController();
//   bool _isLoading = false;
//   String? template;
//   int? employeeId;
//   int Imageindex= 0;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _checkDeviceStatus();
//
//     // Listen for method calls from native code
//     platform.setMethodCallHandler((call) async {
//       try {
//         switch (call.method) {
//           case 'updateImage':
//             setState(() {
//
//               _fingerprintImage = call.arguments;
//               image?[Imageindex] = base64Encode(_fingerprintImage!);
//               Clipboard.setData(ClipboardData(text: image![Imageindex]));
//               print("Image Array: $_fingerprintImage");
//               _statusMessage = "Fingerprint captured successfully!";
//             });
//
//             // Start a 3-second delay to clear the image and message
//             Future.delayed(Duration(seconds: 3), () {
//               setState(() {
//                 _fingerprintImage = null;
//                 _statusMessage = "Status: Waiting for action";
//                 _empIdController.text = '';
//                 Imageindex = 0;
//               });
//             });
//             // if (kDebugMode) {
//             //   print(image);
//             // }
//             // break;
//
//           case 'updateTemplate':
//             template = call.arguments['base64'];
//             Clipboard.setData(ClipboardData(text: template!));
//             print('Template Type: ${call.arguments['type']}');
//             print('Template Base64: ${call.arguments['base64']}');
//             print('Template Length: ${call.arguments['length']}');
//             break;
//
//           // New method channel handlers
//           case 'db_canAddFinger':
//             setState(() => _isLoading = true);
//             try {
//               final response =
//                   await _apiService.canAddFingerprint(call.arguments['empId']);
//               return response.toMap();
//             } finally {
//               setState(() => _isLoading = false);
//             }
//
//           case 'db_insertUser':
//             setState(() => _isLoading = true);
//             try {
//               final Map<dynamic, dynamic> args = call.arguments;
//               final responseBody = await _apiService.registerUser(
//                 email: args['empId'],
//                 fingerprintData: args['template'],
//               );
//
//               if (responseBody['isSuccess']) {
//                 _showSnackBar('User registered successfully', isError: false);
//               } else {
//                 _showSnackBar(responseBody['errorMessage'], isError: true);
//               }
//               return responseBody;
//             } finally {
//               setState(() => _isLoading = false);
//             }
//
//           case 'db_getUserList':
//             setState(() => _isLoading = true);
//             try {
//               final response = await _apiService.getUserList();
//               if (response.data["isSuccess"]) {
//                 _showSnackBar('User list retrieved successfully',
//                     isError: false);
//               }
//               return response.toMap();
//             } finally {
//               setState(() => _isLoading = false);
//             }
//             setState(() => _isLoading = false);
//         }
//       } catch (e) {
//         _showSnackBar('Error: ${e.toString()}', isError: true);
//         return {'success': false, 'error': e.toString()};
//       }
//     });
//   }
//
//   void _showSnackBar(String message, {bool isError = false}) {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         duration: Duration(seconds: 3),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         action: SnackBarAction(
//           label: 'Dismiss',
//           textColor: Colors.white,
//           onPressed: () {
//             ScaffoldMessenger.of(context).hideCurrentSnackBar();
//           },
//         ),
//       ),
//     );
//   }
//
//   Future<void> _checkDeviceStatus() async {
//     try {
//       final bool result =
//           await platform.invokeMethod<bool>('checkDeviceStatus') ?? false;
//       setState(() {
//         if (!result) {
//           _statusMessage = 'Please Start Capture First';
//           return;
//         }
//         _statusMessage = "Capture Started";
//       });
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
//   // Existing methods remain unchanged
//   Future<void> _startCapture() async {
//     _checkDeviceStatus();
//     try {
//       final String result = await platform.invokeMethod('startCapture');
//       setState(() {
//         _statusMessage = result;
//       });
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
//   Future<void> _stopCapture() async {
//     _checkDeviceStatus();
//     try {
//       final String result = await platform.invokeMethod('stopCapture');
//       setState(() {
//         _statusMessage = result;
//       });
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
//   Future<void> _registerUser(String email) async {
//     _checkDeviceStatus();
//     if (_formKey.currentState!.validate()) {
//       if (isValidEmail(email)) {
//         print("Valid email!");
//         setState(() {
//           _statusMessage = "Valid Email";
//         });
//       } else {
//         print("Invalid email.");
//         setState(() {
//           _statusMessage = "Invalid Email";
//         });
//         return;
//       }
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   const SnackBar(content: Text('Processing Data')),
//       // );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please Enter Your Email')),
//       );
//       return;
//     }
//     try {
//       employeeId = await _apiService.getEmployeeId(email);
//       final String result = await platform.invokeMethod('registerUser', {
//         'userId': employeeId.toString(),
//       });
//       setState(() {
//         _statusMessage = result;
//       });
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
//   Future<void> _identifyUser() async {
//     _checkDeviceStatus();
//     try {
//       final String result = await platform.invokeMethod('identifyUser');
//       setState(() {
//         _statusMessage = result;
//       });
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
//   // Future<void> _deleteUser(String userId) async {
//   //   try {
//   //     final String result = await platform.invokeMethod('deleteUser', {
//   //       'userId': userId,
//   //     });
//   //     setState(() {
//   //       _statusMessage = result;
//   //     });
//   //   } catch (e) {
//   //     _showError(e);
//   //   }
//   // }
//   //
//   // Future<void> _clearAllUsers() async {
//   //   try {
//   //     final String result = await platform.invokeMethod('clearAllUsers');
//   //     setState(() {
//   //       _statusMessage = result;
//   //     });
//   //   } catch (e) {
//   //     _showError(e);
//   //   }
//   // }
//
//   void _showError(Object e) {
//     setState(() {
//       _statusMessage = "Error: ${e.toString()}";
//     });
//   }
//
//   bool isValidEmail(String email) {
//     // Define the regex for a valid email
//     // String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
//
//     // Match the email against the regex
//     return RegExp(emailRegex).hasMatch(email);
//   }
//
//   @override
//   void dispose() {
//     _empIdController.dispose();
//     _apiService.dispose();
//     super.dispose();
//   }
//
//   // Build method remains unchanged
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Fingerprint Scanner'),
//       ),
//       body: Form(
//         key: _formKey,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Display fingerprint image if available
//               _fingerprintImage != null
//                   ? Container(
//                       height: 200,
//                       child: Image.memory(_fingerprintImage!),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                     )
//                   : Container(
//                       height: 200,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Center(
//                         child: Text(
//                           'Fingerprint Image',
//                           style: TextStyle(color: Colors.grey.shade600),
//                         ),
//                       ),
//                     ),
//               SizedBox(height: 20),
//
//               // Status message display
//               _isLoading
//                   ? Center(
//                       child: Shimmer.fromColors(
//                           baseColor: Colors.grey[300]!,
//                           highlightColor: Colors.grey[100]!,
//                           child: const Text(
//                             'Loading...',
//                             style: TextStyle(
//                               fontSize: 28.0,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           )),
//                     )
//                   : Text(
//                       _statusMessage,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.blueGrey,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//               SizedBox(height: 20),
//
//               // User ID Input
//               TextFormField(
//                 controller: _empIdController,
//                 decoration: InputDecoration(
//                   labelText: 'Employee ID',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   suffixIcon: Icon(Icons.person),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please Enter You Email';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//
//               // Buttons with updated styling
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children: [
//                   ElevatedButton(
//                     onPressed: _startCapture,
//                     child: Text('Start Capture'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: _stopCapture,
//                     child: Text('Stop Capture'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.redAccent,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () => _registerUser(_empIdController.text),
//                     child: Text('Register User'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: _identifyUser,
//                     child: Text('Identify User'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     ),
//                   ),
//                   // ElevatedButton(
//                   //   onPressed: () => _deleteUser(_empIdController.text),
//                   //   child: Text('Delete User'),
//                   //   style: ElevatedButton.styleFrom(
//                   //     backgroundColor: Colors.purple,
//                   //     shape: RoundedRectangleBorder(
//                   //       borderRadius: BorderRadius.circular(8),
//                   //     ),
//                   //     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   //   ),
//                   // ),
//                   // ElevatedButton(
//                   //   onPressed: _clearAllUsers,
//                   //   child: Text('Clear All Users'),
//                   //   style: ElevatedButton.styleFrom(
//                   //     backgroundColor: Colors.grey,
//                   //     shape: RoundedRectangleBorder(
//                   //       borderRadius: BorderRadius.circular(8),
//                   //     ),
//                   //     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   //   ),
//                   // ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/fingerPrint_apiService.dart';
import '../../services/mark_attendance_service.dart';
import '../../utils/attendanceTypes.dart';

@pragma('vm:entry-point')
class FingerprintScannerScreen extends StatefulWidget {
  static String routeName = '/fingerAuthScreen';

  const FingerprintScannerScreen({super.key});

  @override
  _FingerprintScannerScreenState createState() =>
      _FingerprintScannerScreenState();
}

class _FingerprintScannerScreenState extends State<FingerprintScannerScreen> {
  // Form and UI Controllers
  final _formKey = GlobalKey<FormState>();
  static const platform = MethodChannel('zkfingerprint_channel');
  final FingerFaceApiService _apiService = FingerFaceApiService();
  final MarkAttendanceService _markAttendance = MarkAttendanceService();

  // State Variables
  String _statusMessage = "Status: Waiting for action";
  Uint8List? _fingerprintImage;
  bool _isLoading = false;

  // Fingerprint Data Storage
  List<String> images = ['', '', '']; // Three image slots
  String? template; // Single template
  int Imageindex = 0;
  int? employeeId;
  bool registerFlagForImageStatusMsg = false;
  // String? _selectedValue = attendanceTypes.first.keys.first;

  final TextEditingController _empIdController = TextEditingController();

  String? validationMessage;
  String? selectedOption;

  @override
  void initState() {
    super.initState();
    // _checkDeviceStatus();
    _initMethodChannelHandler();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readyDevice();
    });
  }

  void _readyDevice() async {
    await _startCapture();
    // await _identifyUser(empId);
  }

  void _initMethodChannelHandler() {
    platform.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'updateImage':
            _handleImageUpdate(call.arguments);
            break;
          case 'updateTemplate':
            _handleTemplateUpdate(call.arguments);
            break;

          // New method channel handlers
          case 'db_canAddFinger':
            setState(() => _isLoading = true);
            try {
              final response =
                  await _apiService.canAddFingerprint(call.arguments['empId']);
              return response.toMap();
            } finally {
              setState(() => _isLoading = false);
            }

          case 'db_insertUser':
            setState(() => _isLoading = true);
            try {
              final Map<dynamic, dynamic> args = call.arguments;
              final responseBody = await _apiService.registerUser(
                employeeId: args['empId'],
                fingerprintData: args['template'],
                images: images,
              );

              if (responseBody['isSuccess']) {
                _showSuccessSnackBar('User registered successfully');
              } else {
                _showErrorSnackBar(responseBody['errorMessage']);
              }
              return responseBody;
            } finally {
              setState(() => _isLoading = false);
            }

          case 'db_getUserList':
            setState(() => _isLoading = true);
            try {
              final response = await _apiService.getUserList();
              final isSuccess = response.data['isSuccess'];
              isSuccess
                  ? _showSuccessSnackBar(
                      'User list retrieved successfully',
                    )
                  : _showErrorSnackBar(response.data['errorMessage'] ??
                      'Unable to fetch users list!, Please start capture again.');
              // if (response.data["isSuccess"]) {
              //   _showSuccessSnackBar(
              //     'User list retrieved successfully',
              //   );
              // }
              // else{
              //   _showErrorSnackBar(response.data[''])
              // }
              return response.toMap();
            } finally {
              setState(() => _isLoading = false);
            }

          case 'mark_attendance':
            // log(call.arguments);
            // employeeId = call.arguments;
            if (_validateInput()) _identifyUser(call.arguments);
            break;
        }
      } catch (e) {
        _showErrorSnackBar('Error processing method call: $e');
      }
    });
  }

  void _handleImageUpdate(dynamic imageData) {
    if (imageData != null) {
      setState(() {
        _fingerprintImage = imageData;

        // Store base64 encoded image in the images array
        images[Imageindex] = base64Encode(_fingerprintImage!);

        _statusMessage = registerFlagForImageStatusMsg
            ? "Fingerprint image ${Imageindex + 1} captured successfully"
            : "Fingerprint image captured!";

        // Increment image index, wrap around to 0 if exceeds 2
        Imageindex = (Imageindex + 1) % 3;
      });

      // Auto-clear image after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _fingerprintImage = null;
            _statusMessage = "Status: Waiting for action";
          });
        }
      });
    }
  }

  void _handleTemplateUpdate(dynamic templateData) {
    if (templateData != null && templateData['base64'] != null) {
      setState(() {
        template = templateData['base64'];
        _statusMessage = templateData['result'];
      });
    }
  }

  Future<void> _checkDeviceStatus() async {
    try {
      final result = await platform.invokeMethod('checkDeviceStatus');
      final bool isReady = result == true; // Safely check if the result is true

      setState(() {
        _statusMessage =
            isReady ? "Device Ready" : "Please Connect Fingerprint Device";
      });
    } catch (e) {
      _showErrorSnackBar('Device status check failed: $e');
    }
  }

  Future<void> _startCapture() async {
    try {
      final result = await platform.invokeMethod('startCapture');
      if (result) {
        setState(() {
          _statusMessage = 'Capture Started!';
        });
      } else {
        setState(() {
          _statusMessage = 'Please Start Capture Again!';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Start capture failed: $e');
    }
  }

  Future<void> _stopCapture() async {
    try {
      final String result = await platform.invokeMethod('stopCapture');
      setState(() {
        _statusMessage = result;
      });
    } catch (e) {
      _showErrorSnackBar('Stop capture failed: $e');
    }
  }

  Future<void> _registerUser() async {
    if (!_validateInput()) return;

    // Optional: Device status check if needed
    _checkDeviceStatus();

    // Set loading or processing state
    setState(() {
      _statusMessage = "Valid Email";
      _isLoading = true; // Assuming you want to show a loading indicator
    });

    try {
      registerFlagForImageStatusMsg = true;
      // Retrieve employee ID
      final employeeCode = _empIdController.text.trim();
      employeeId = await _apiService.getEmployeeId(context, employeeCode);

      if (employeeId == null) {
        _showErrorSnackBar('Could not retrieve employee ID');
        return;
      }

      // Platform-specific user registration method
      final String result = await platform.invokeMethod('registerUser', {
        'userId': employeeId.toString(),
      });

      // Update state with registration result
      setState(() {
        _statusMessage = result;
      });

      // Optional: Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success!: $result')),
      );
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      // Ensure loading state is reset
      setState(() {
        _isLoading = false;
        registerFlagForImageStatusMsg = false;
        // _resetForm();
      });
    }
  }

  Future<void> _identifyUser(String empId) async {
    log("identifying user log");
    _checkDeviceStatus();
    try {
      // final String result = await platform.invokeMethod('identifyUser');
      if (empId == null) {
        return _showErrorSnackBar('Employee ID not found!');
      }
      final response = await _markAttendance.markAttendance(
        empId,
        'Finger',
        attendanceType: selectedOption,
      );

      if (response != null) {
        _showSuccessSnackBar(response);
      }
      // else _showErrorSnackBar(response);

      // setState(() {
      //   _statusMessage = result;
      // });fstar
    } catch (e) {
      _showErrorSnackBar('Identification failed: $e');
    }
  }

  bool _validateSelection() {
    // setState(() {
    if (selectedOption == null || selectedOption!.isEmpty) {
      setState(() {
        validationMessage = "Please select at least one option.";
      });
      return false;
    } else {
      setState(() {
        validationMessage = null;
      });
      return true;
    }

    validationMessage =
        selectedOption == null ? "Please select at least one option." : null;
    // });
  }

  bool _validateInput() {
    final isSelected = _validateSelection();
    if (!isSelected) {
      return false;
    }
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // final email = _empIdController.text.trim();
    //   if (!_isValidEmail(email)) {
    //     _showErrorSnackBar('Invalid email format');
    //     return false;
    //   }
    //
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,

      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    // Dispose the TextEditingController
    _empIdController.dispose();

    // Safely stop capture if it's running
    _stopCaptureSafely();

    // Clean up other resources if necessary
    super.dispose();
  }

  Future<void> _stopCaptureSafely() async {
    try {
      // Safely stop the capture using the platform channel
      await platform.invokeMethod('stopCapture');
    } catch (e) {
      // Log or handle the error; don't let it crash the app
      debugPrint('Error stopping capture: $e');
    }
  }

  Future<void> _refresh() async {
    _readyDevice();
  }

  Widget _buildActionTypes() {
    List<String> keys = attendanceOptions.keys.toList();

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.teal[700]!, width: 1.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Select Attendance Type',
                style: TextStyle(
                  color: Colors.teal[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.0),
          Column(
            children: [
              for (int i = 0; i < keys.length; i += 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: RadioListTile<String>(
                        visualDensity: const VisualDensity(horizontal: -4.0),
                        toggleable: true,
                        enableFeedback: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          keys[i],
                          style: TextStyle(
                            color: Colors.teal[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: attendanceOptions[keys[i]] ?? '',
                        groupValue: selectedOption,
                        onChanged: (String? value) {
                          setState(() {
                            selectedOption = value;
                            validationMessage = null;
                          });
                        },
                        activeColor: Colors.teal[700],
                      ),
                    ),
                    if (i + 1 < keys.length)
                      Flexible(
                        child: RadioListTile<String>(
                          visualDensity: const VisualDensity(horizontal: -4.0),
                          toggleable: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            keys[i + 1],
                            style: TextStyle(
                              color: Colors.teal[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: attendanceOptions[keys[i + 1]] ?? '',
                          groupValue: selectedOption,
                          onChanged: (String? value) {
                            setState(() {
                              selectedOption = value;
                              validationMessage = null;
                              log(value.toString());
                            });
                          },
                          activeColor: Colors.teal[700],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (validationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                validationMessage!,
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ),
          // SizedBox(height: 8.0),
          // ElevatedButton(
          //   onPressed: _validateSelection,
          //   child: Text("Submit"),
          // ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fingerprint Scanner'),
          backgroundColor: const Color(0xFF17a2b8),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Fingerprint Image Display
                        _fingerprintImage != null
                            ? Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Image.memory(_fingerprintImage!),
                              )
                            : Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                    child: Image.asset(
                                  'assets/images/fingerprint-scan.png', // Add your placeholder image in the assets folder
                                  fit: BoxFit.cover,
                                )),
                              ),
                        const SizedBox(height: 20),

                        // Status Message
                        _isLoading
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
                            : Text(
                                _statusMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                        const SizedBox(height: 20),

                        _buildActionTypes(),

                        // Employee ID Input (Commented out for now)
                        // TextFormField(
                        //   controller: _empIdController,
                        //   decoration: InputDecoration(
                        //     labelText: 'Employee ID',
                        //     border: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(8.0),
                        //     ),
                        //     suffixIcon: const Icon(Icons.person),
                        //   ),
                        //   validator: (value) {
                        //     if (value == null || value.isEmpty) {
                        //       return 'Please Enter Your Employee ID';
                        //     }
                        //     return null;
                        //   },
                        // ),
                        const SizedBox(height: 20),

                        // Action Buttons (Uncomment and customize if needed)
                        // Wrap(
                        //   spacing: 10,
                        //   runSpacing: 10,
                        //   children: [
                        //     ElevatedButton(
                        //       onPressed: _startCapture,
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.green,
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         padding: const EdgeInsets.symmetric(
                        //             horizontal: 24, vertical: 12),
                        //       ),
                        //       child: const Text('Start Capture'),
                        //     ),
                        //     ElevatedButton(
                        //       onPressed: _stopCapture,
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.redAccent,
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         padding: const EdgeInsets.symmetric(
                        //             horizontal: 24, vertical: 12),
                        //       ),
                        //       child: const Text('Stop Capture'),
                        //     ),
                        //     ElevatedButton(
                        //       onPressed: () => _registerUser(),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.blue,
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         padding: const EdgeInsets.symmetric(
                        //             horizontal: 24, vertical: 12),
                        //       ),
                        //       child: const Text('Register User'),
                        //     ),
                        //   ],
                        // ),
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Fingerprint Scanner'),
  //       backgroundColor: const Color(0xFF17a2b8),
  //     ),
  //     body: SingleChildScrollView(
  //       child: Form(
  //         key: _formKey,
  //         child: Padding(
  //           padding: const EdgeInsets.all(16.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: [
  //               // Fingerprint Image Display
  //               _fingerprintImage != null
  //                   ? Container(
  //                       height: 200,
  //                       decoration: BoxDecoration(
  //                         borderRadius: BorderRadius.circular(12),
  //                         border: Border.all(color: Colors.grey.shade300),
  //                       ),
  //                       child: Image.memory(_fingerprintImage!),
  //                     )
  //                   : Container(
  //                       height: 200,
  //                       decoration: BoxDecoration(
  //                         color: Colors.grey[200],
  //                         borderRadius: BorderRadius.circular(12),
  //                       ),
  //                       child: Center(
  //                         child: Text(
  //                           'Fingerprint Image',
  //                           style: TextStyle(color: Colors.grey.shade600),
  //                         ),
  //                       ),
  //                     ),
  //               const SizedBox(height: 20),
  //
  //               // Status Message
  //               _isLoading
  //                   ? Center(
  //                       child: Shimmer.fromColors(
  //                         baseColor: Colors.grey[300]!,
  //                         highlightColor: Colors.grey[100]!,
  //                         child: const Text(
  //                           'Loading...',
  //                           style: TextStyle(
  //                             fontSize: 28.0,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ),
  //                     )
  //                   : Text(
  //                       _statusMessage,
  //                       textAlign: TextAlign.center,
  //                       style: const TextStyle(
  //                         fontSize: 16,
  //                         color: Colors.blueGrey,
  //                         fontWeight: FontWeight.w500,
  //                       ),
  //                     ),
  //               const SizedBox(height: 20),
  //
  //               // Employee ID Input
  //               TextFormField(
  //                 controller: _empIdController,
  //                 decoration: InputDecoration(
  //                   labelText: 'Employee ID',
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8.0),
  //                   ),
  //                   suffixIcon: const Icon(Icons.person),
  //                 ),
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return 'Please Enter Your Employee ID';
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               const SizedBox(height: 20),
  //
  //               // Action Buttons
  //               Wrap(
  //                 spacing: 10,
  //                 runSpacing: 10,
  //                 children: [
  //                   ElevatedButton(
  //                     onPressed: _startCapture,
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.green,
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       padding: const EdgeInsets.symmetric(
  //                           horizontal: 24, vertical: 12),
  //                     ),
  //                     child: const Text('Start Capture'),
  //                   ),
  //                   ElevatedButton(
  //                     onPressed: _stopCapture,
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.redAccent,
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       padding: const EdgeInsets.symmetric(
  //                           horizontal: 24, vertical: 12),
  //                     ),
  //                     child: const Text('Stop Capture'),
  //                   ),
  //                   ElevatedButton(
  //                     onPressed: () => _registerUser(),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.blue,
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       padding: const EdgeInsets.symmetric(
  //                           horizontal: 24, vertical: 12),
  //                     ),
  //                     child: const Text('Register User'),
  //                   ),
  //                   // ElevatedButton(
  //                   //   onPressed: _identifyUser,
  //                   //   style: ElevatedButton.styleFrom(
  //                   //     backgroundColor: Colors.orange,
  //                   //     shape: RoundedRectangleBorder(
  //                   //       borderRadius: BorderRadius.circular(8),
  //                   //     ),
  //                   //     padding: const EdgeInsets.symmetric(
  //                   //         horizontal: 24, vertical: 12),
  //                   //   ),
  //                   //   child: const Text('Identify User'),
  //                   // ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
