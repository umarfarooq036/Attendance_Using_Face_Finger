import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/fingerPrint_apiService.dart';
import '../../services/mark_attendance_service.dart';

class FingerprintRegistrationScreen extends StatefulWidget {
  static String routeName = '/fingerRegisterScreen';

  const FingerprintRegistrationScreen({super.key});

  @override
  _FingerprintScannerScreenState createState() =>
      _FingerprintScannerScreenState();
}

class _FingerprintScannerScreenState
    extends State<FingerprintRegistrationScreen> {
  // Form and UI Controllers
  final _formKey = GlobalKey<FormState>();
  static const platform = MethodChannel('zkfingerprint_channel');
  final FingerFaceApiService _apiService = FingerFaceApiService();
  final MarkAttendanceService _markAttendance = MarkAttendanceService();

  // State Variables
  String _statusMessage = "Status: Waiting for action";
  Uint8List? _fingerprintImage;
  bool _isLoading = false;
  bool _isCapturing = false;

  // Fingerprint Data Storage
  List<String> images = ['', '', '']; // Three image slots
  String? template; // Single template
  int Imageindex = 0;
  int? employeeId;
  bool registerFlagForImageStatusMsg = false;
  // String? employeeCode;
  bool argumentsFetched = false;
  bool usersListRetrieved = false;

  final TextEditingController _empIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _checkDeviceStatus();
    _initMethodChannelHandler();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!argumentsFetched) {
        final arguments = ModalRoute.of(context)!.settings.arguments as String;
        if (arguments != null) {
          _empIdController.text = arguments;
          argumentsFetched = true;
          _readyDevice();
        }
      }
    });
  }

  void _readyDevice() async {
    await _startCapture();
    await _registerUser();
  }

  Future<void> _refresh() async {
    // if (usersListRetrieved) {
    //   await _registerUser();
    // } else {
      // initState();
      _readyDevice();
    // }
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
              Navigator.pop(context);
            }

          case 'db_getUserList':
            setState(() => _isLoading = true);
            try {
              final response = await _apiService.getUserList();
              final isSuccess = response.data['isSuccess'];
              if (isSuccess) {
                usersListRetrieved = true;
              }
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
            // _identifyUser(call.arguments);
            Navigator.pop(context);
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


  // The start capture method that uses the global variable _isCapturing
  // Future<void> _startCapture() async {
  //   // If capture is already in progress, don't start a new one.
  //   if (_isCapturing) {
  //     print('Capture already in progress.');
  //     return;
  //   }
  //
  //   while (!_isCapturing) {
  //     try {
  //       // Attempt to start capture via platform method.
  //       final result = await platform.invokeMethod('startCapture');
  //
  //       if (result) {
  //         // Capture started successfully. Update state and mark capture as started.
  //         setState(() {
  //           _statusMessage = 'Capture Started!';
  //         });
  //         _isCapturing = true;
  //       } else {
  //         // Device not connected; perform cleanup and update UI.
  //         // _stopCaptureSafely();
  //         setState(() {
  //           _statusMessage = 'Device not connected. Trying again...';
  //         });
  //         // Wait a bit before trying again.
  //         await Future.delayed(Duration(seconds: 2));
  //       }
  //     } catch (e) {
  //       // An error occurred. Safely stop capture and show an error message.
  //       _stopCaptureSafely();
  //       _showErrorSnackBar('Start capture failed: $e');
  //       // Optionally exit the loop on error:
  //       break;
  //     }
  //   }
  // }



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
    // if (!usersListRetrieved) {
    //   await _startCapture();
    // }
    // if (!_validateInput()) return;

    // Optional: Device status check if needed
    _checkDeviceStatus();

    // Set loading or processing state
    setState(() {
      // _statusMessage = "Valid Email";
      _isLoading = true; // Assuming you want to show a loading indicator
    });

    try {
      registerFlagForImageStatusMsg = true;
      // Retrieve employee ID
      final employeeCode = _empIdController.text.trim();
      employeeId = await _apiService.getEmployeeId(context, employeeCode);

      if (employeeId == null) {
        _showErrorSnackBar('Could not retrieve employee ID');
        setState(() {
          _statusMessage = 'Scroll down to refresh the screen';
        });
        // Navigator.pop(context);
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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
      _isCapturing = false;
      // Safely stop the capture using the platform channel
      await platform.invokeMethod('stopCapture');
    } catch (e) {
      // Log or handle the error; don't let it crash the app
      debugPrint('Error stopping capture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                border: Border.all(color: Colors.grey.shade300),
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

                      const SizedBox(height: 20),

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

}

// import 'dart:convert';
// import 'dart:developer';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shimmer/shimmer.dart';
//
// import '../../services/fingerPrint_apiService.dart';
// import '../../services/mark_attendance_service.dart';
//
// class FingerprintRegistrationScreen extends StatefulWidget {
//   static String routeName = '/fingerRegisterScreen';
//
//   const FingerprintRegistrationScreen({Key? key}) : super(key: key);
//
//   @override
//   _FingerprintRegistrationScreenState createState() =>
//       _FingerprintRegistrationScreenState();
// }
//
// class _FingerprintRegistrationScreenState
//     extends State<FingerprintRegistrationScreen> {
//   // Core Controllers and Services
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   static const platform = MethodChannel('zkfingerprint_channel');
//
//   final FingerFaceApiService _apiService = FingerFaceApiService();
//   final MarkAttendanceService _markAttendance = MarkAttendanceService();
//   final TextEditingController _empIdController = TextEditingController();
//
//   // State Management Variables
//   bool _isDeviceInitialized = false;
//   bool _isLoading = false;
//   String _statusMessage = "Status: Waiting for Initialization";
//
//   // Fingerprint Specific Variables
//   Uint8List? _fingerprintImage;
//   List<String> images = ['', '', ''];
//   String? template;
//   int imageIndex = 0;
//   int? employeeId;
//
//   @override
//   void initState() {
//     super.initState();
//     _initMethodChannelHandler();
//
//     // Post-frame callback for initialization
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeDeviceAndUser();
//     });
//   }
//
//   void _initMethodChannelHandler() {
//     platform.setMethodCallHandler((call) async {
//       try {
//         switch (call.method) {
//           case 'updateImage':
//             _handleImageUpdate(call.arguments);
//             break;
//           case 'updateTemplate':
//             _handleTemplateUpdate(call.arguments);
//             break;
//           case 'db_canAddFinger':
//             return await _handleCanAddFinger(call.arguments);
//           case 'db_insertUser':
//             return await _handleUserInsertion(call.arguments);
//           case 'db_getUserList':
//             return await _handleGetUserList();
//         }
//       } catch (e) {
//         _showErrorSnackBar('Method Handler Error: $e');
//       }
//     });
//   }
//
//   Future<Map<String, dynamic>> _handleCanAddFinger(dynamic arguments) async {
//     setState(() => _isLoading = true);
//     try {
//       final response = await _apiService.canAddFingerprint(arguments['empId']);
//       return response.toMap();
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<Map<String, dynamic>> _handleUserInsertion(dynamic arguments) async {
//     setState(() => _isLoading = true);
//     try {
//       final responseBody = await _apiService.registerUser(
//         employeeId: arguments['empId'],
//         fingerprintData: arguments['template'],
//         images: images,
//       );
//
//       if (responseBody['isSuccess']) {
//         _showSuccessSnackBar('User registered successfully');
//         Navigator.pop(context);
//       } else {
//         _showErrorSnackBar(responseBody['errorMessage']);
//       }
//       return responseBody;
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<Map<String, dynamic>> _handleGetUserList() async {
//     setState(() => _isLoading = true);
//     try {
//       final response = await _apiService.getUserList();
//       final isSuccess = response.data['isSuccess'];
//
//       isSuccess
//           ? _showSuccessSnackBar('User list retrieved successfully')
//           : _showErrorSnackBar(
//               response.data['errorMessage'] ?? 'Unable to fetch users list!');
//
//       return response.toMap();
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _initializeDeviceAndUser() async {
//     // Prevent multiple initialization
//     // if (_isDeviceInitialized) return;
//
//     setState(() {
//       _isLoading = true;
//       _statusMessage = "Initializing Device...";
//     });
//
//     try {
//       // 1. Check Device Status
//       final isDeviceReady = await _checkDeviceStatus();
//       // if (!isDeviceReady) {
//       //   throw Exception('Fingerprint device is not ready');
//       // }
//
//       // 2. Start Capture Process
//       final captureStarted = await _startCaptureProcess();
//       if (!captureStarted) {
//         throw Exception('Failed to start fingerprint capture');
//       }
//
//       // 3. Fetch and Set Employee ID
//       final arguments = ModalRoute.of(context)!.settings.arguments;
//       if (arguments != null && arguments is String) {
//         _empIdController.text = arguments;
//
//         // Verify Employee ID
//         final employeeId = await _apiService.getEmployeeId(context, arguments);
//         if (employeeId == null) {
//           throw Exception('Invalid Employee ID');
//         }
//
//         // Mark initialization complete
//         setState(() {
//           _isDeviceInitialized = true;
//           _statusMessage = 'Device Ready for Fingerprint Registration';
//         });
//       } else {
//         throw Exception('No Employee Information Provided');
//       }
//     } catch (e) {
//       _handleInitializationError(e);
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<bool> _checkDeviceStatus() async {
//     try {
//       final result = await platform.invokeMethod('checkDeviceStatus');
//       return result == true;
//     } catch (e) {
//       log('Device Status Check Failed: $e');
//       return false;
//     }
//   }
//
//   Future<bool> _startCaptureProcess() async {
//     try {
//       final result = await platform.invokeMethod('startCapture');
//       setState(() {
//         _statusMessage = result ? 'Capture Started!' : 'Capture Start Failed';
//       });
//       return result == true;
//     } catch (e) {
//       log('Capture Process Failed: $e');
//       return false;
//     }
//   }
//
//   void _handleImageUpdate(dynamic imageData) {
//     if (imageData != null) {
//       setState(() {
//         _fingerprintImage = imageData;
//         images[imageIndex] = base64Encode(_fingerprintImage!);
//         _statusMessage = "Fingerprint image ${imageIndex + 1} captured!";
//         imageIndex = (imageIndex + 1) % 3;
//       });
//
//       // Auto-clear image after 3 seconds
//       Future.delayed(Duration(seconds: 3), () {
//         if (mounted) {
//           setState(() {
//             _fingerprintImage = null;
//             _statusMessage = "Status: Waiting for action";
//           });
//         }
//       });
//     }
//   }
//
//   void _handleTemplateUpdate(dynamic templateData) {
//     if (templateData != null && templateData['base64'] != null) {
//       setState(() {
//         template = templateData['base64'];
//         _statusMessage = templateData['result'];
//       });
//     }
//   }
//
//   void _handleInitializationError(Object error) {
//     String errorMessage = 'Initialization Failed';
//
//     if (error is Exception) {
//       errorMessage = error.toString().replaceFirst('Exception: ', '');
//     }
//
//     _showErrorSnackBar(errorMessage);
//
//     log('Initialization Error: $error');
//
//     setState(() {
//       _isDeviceInitialized = false;
//       _statusMessage = 'Device Initialization Failed';
//     });
//   }
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _empIdController.dispose();
//     _stopCaptureSafely();
//     super.dispose();
//   }
//
//   Future<void> _stopCaptureSafely() async {
//     try {
//       await platform.invokeMethod('stopCapture');
//     } catch (e) {
//       debugPrint('Error stopping capture: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: _startCaptureProcess,
//       child: Scaffold(
//         key: _scaffoldKey,
//         appBar: AppBar(
//           title: const Text('Fingerprint Registration'),
//           backgroundColor: const Color(0xFF17a2b8),
//         ),
//         body: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: ListView(
//             padding: const EdgeInsets.all(16.0),
//             children: [
//               Card(
//                 elevation: 5,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       // Fingerprint Image Display
//                       _buildFingerprintImageDisplay(),
//
//                       const SizedBox(height: 20),
//
//                       // Status Message
//                       _buildStatusMessage(),
//
//                       const SizedBox(height: 20),
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
//   Widget _buildFingerprintImageDisplay() {
//     return _fingerprintImage != null
//         ? Container(
//             height: 200,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey.shade300),
//             ),
//             child: Image.memory(_fingerprintImage!),
//           )
//         : Container(
//             height: 200,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Center(
//                 child: Image.asset(
//               'assets/images/fingerprint-scan.png',
//               fit: BoxFit.cover,
//             )),
//           );
//   }
//
//   Widget _buildStatusMessage() {
//     return _isLoading
//         ? Center(
//             child: Shimmer.fromColors(
//               baseColor: Colors.grey[300]!,
//               highlightColor: Colors.grey[100]!,
//               child: const Text(
//                 'Loading...',
//                 style: TextStyle(
//                   fontSize: 28.0,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           )
//         : Text(
//             _statusMessage,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 16,
//               color: Colors.blueGrey,
//               fontWeight: FontWeight.w500,
//             ),
//           );
//   }
// }
