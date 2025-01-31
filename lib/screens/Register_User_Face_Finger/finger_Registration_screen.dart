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
    if (usersListRetrieved) {
      await _registerUser();
    } else {
      initState();
      // _readyDevice();
    }
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

  // Future<void> _registerUser() async {
  //   // Validate input
  //   if (!_validateInput()) return;
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     // // Validate inputs and template
  //     // if (template == null) {
  //     //   _showErrorSnackBar('Please capture fingerprint template first');
  //     //   return;
  //     // }
  //
  //     final email = _empIdController.text.trim();
  //     employeeId = await _apiService.getEmployeeId(email);
  //
  //     if (employeeId == null) {
  //       _showErrorSnackBar('Could not retrieve employee ID');
  //       return;
  //     }
  //
  //     // Register user with template
  //     final response = await _apiService.registerUser(
  //       email: email,
  //       fingerprintData: template!,
  //     );
  //
  //     if (response['isSuccess']) {
  //       _showSuccessSnackBar('User registered successfully');
  //       _resetForm();
  //     } else {
  //       _showErrorSnackBar(response['errorMessage'] ?? 'Registration failed');
  //     }
  //   } catch (e) {
  //     _showErrorSnackBar('Registration error: $e');
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _registerUser() async {
    if (!usersListRetrieved) {
      await _startCapture();
    }
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

  Future<void> _identifyUser(String empId) async {
    log("identifying user log");
    _checkDeviceStatus();
    try {
      // final String result = await platform.invokeMethod('identifyUser');
      if (empId == null) {
        return _showErrorSnackBar('Employee ID not found!');
      }
      final response = await _markAttendance.markAttendance(empId, 'Finger',
          attendanceType: '');

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

  bool _validateInput() {
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

  // for now the email validation is removed

  // bool _isValidEmail(String email) {
  //   final email_Regex = RegExp(emailRegex);
  //   return email_Regex.hasMatch(email);
  // }

  // void _resetForm() {
  //   setState(() {
  //     _empIdController.clear();
  //     images = ['', '', ''];
  //     template = null;
  //     Imageindex = 0;
  //     _statusMessage = "Status: Waiting for action";
  //     _fingerprintImage = null;
  //   });
  // }

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
    );
  }

// @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Fingerprint Scanner'),
  //       backgroundColor: const Color(0xFF17a2b8),
  //     ),
  //     body: RefreshIndicator(
  //       onRefresh: _refresh,
  //       child: SingleChildScrollView(
  //         child: Form(
  //           key: _formKey,
  //           child: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.stretch,
  //               children: [
  //                 // Fingerprint Image Display
  //                 _fingerprintImage != null
  //                     ? Container(
  //                         height: 200,
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(12),
  //                           border: Border.all(color: Colors.grey.shade300),
  //                         ),
  //                         child: Image.memory(_fingerprintImage!),
  //                       )
  //                     : Container(
  //                         height: 200,
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[200],
  //                           borderRadius: BorderRadius.circular(12),
  //                         ),
  //                         child: Center(
  //                           child: Text(
  //                             'Fingerprint Image',
  //                             style: TextStyle(color: Colors.grey.shade600),
  //                           ),
  //                         ),
  //                       ),
  //                 const SizedBox(height: 20),
  //
  //                 // Status Message
  //                 _isLoading
  //                     ? Center(
  //                         child: Shimmer.fromColors(
  //                           baseColor: Colors.grey[300]!,
  //                           highlightColor: Colors.grey[100]!,
  //                           child: const Text(
  //                             'Loading...',
  //                             style: TextStyle(
  //                               fontSize: 28.0,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ),
  //                       )
  //                     : Text(
  //                         _statusMessage,
  //                         textAlign: TextAlign.center,
  //                         style: const TextStyle(
  //                           fontSize: 16,
  //                           color: Colors.blueGrey,
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                 const SizedBox(height: 20),
  //
  //                 // Employee ID Input
  //                 TextFormField(
  //                   controller: _empIdController,
  //                   decoration: InputDecoration(
  //                     labelText: 'Employee ID',
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(8.0),
  //                     ),
  //                     suffixIcon: const Icon(Icons.person),
  //                   ),
  //                   validator: (value) {
  //                     if (value == null || value.isEmpty) {
  //                       return 'Please Enter Your Employee ID';
  //                     }
  //                     return null;
  //                   },
  //                 ),
  //                 const SizedBox(height: 20),
  //
  //                 // Action Buttons
  //                 // Wrap(
  //                 //   spacing: 10,
  //                 //   runSpacing: 10,
  //                 //   children: [
  //                 //     ElevatedButton(
  //                 //       onPressed: _startCapture,
  //                 //       style: ElevatedButton.styleFrom(
  //                 //         backgroundColor: Colors.green,
  //                 //         shape: RoundedRectangleBorder(
  //                 //           borderRadius: BorderRadius.circular(8),
  //                 //         ),
  //                 //         padding: const EdgeInsets.symmetric(
  //                 //             horizontal: 24, vertical: 12),
  //                 //       ),
  //                 //       child: const Text('Start Capture'),
  //                 //     ),
  //                 //     ElevatedButton(
  //                 //       onPressed: _stopCapture,
  //                 //       style: ElevatedButton.styleFrom(
  //                 //         backgroundColor: Colors.redAccent,
  //                 //         shape: RoundedRectangleBorder(
  //                 //           borderRadius: BorderRadius.circular(8),
  //                 //         ),
  //                 //         padding: const EdgeInsets.symmetric(
  //                 //             horizontal: 24, vertical: 12),
  //                 //       ),
  //                 //       child: const Text('Stop Capture'),
  //                 //     ),
  //                 //     ElevatedButton(
  //                 //       onPressed: () => _registerUser(),
  //                 //       style: ElevatedButton.styleFrom(
  //                 //         backgroundColor: Colors.blue,
  //                 //         shape: RoundedRectangleBorder(
  //                 //           borderRadius: BorderRadius.circular(8),
  //                 //         ),
  //                 //         padding: const EdgeInsets.symmetric(
  //                 //             horizontal: 24, vertical: 12),
  //                 //       ),
  //                 //       child: const Text('Register User'),
  //                 //     ),
  //                 //     // ElevatedButton(
  //                 //     //   onPressed: _identifyUser,
  //                 //     //   style: ElevatedButton.styleFrom(
  //                 //     //     backgroundColor: Colors.orange,
  //                 //     //     shape: RoundedRectangleBorder(
  //                 //     //       borderRadius: BorderRadius.circular(8),
  //                 //     //     ),
  //                 //     //     padding: const EdgeInsets.symmetric(
  //                 //     //         horizontal: 24, vertical: 12),
  //                 //     //   ),
  //                 //     //   child: const Text('Identify User'),
  //                 //     // ),
  //                 //   ],
  //                 // ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
