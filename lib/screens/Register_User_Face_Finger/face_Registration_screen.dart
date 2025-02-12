import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aws_rekognition_api/rekognition-2016-06-27.dart' as rekognition;
import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/fingerPrint_apiService.dart';
import '../../services/mark_attendance_service.dart';
import '../../utils/sharedPreferencesHelper.dart';
import '../../utils/snackBar.dart';
import '../face_attendance/configs.dart';

class FaceRegistrationScreen extends StatefulWidget {
  static const String routeName = '/registerUserFace';

  const FaceRegistrationScreen({super.key});
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRegistrationScreen> {
  // ================ State Variables ================
  String? _imagePath;
  List<Map<String, String>> attendanceRecords = [];
  String? displayMessage;
  bool isLoading = false;
  bool isActionInProgress = false;

  final configs = FaceAuthConfigs();
  List<String> base64Images = []; // Array to store Base64 strings
  String? faceId;
  String? imageId;

  final MarkAttendanceService _markAttendance = MarkAttendanceService();

  // ================ AWS Clients ================
  late rekognition.Rekognition rekognitionClient;
  late DynamoDB dynamoDb;

  // ================ Local Variables ================
  final FingerFaceApiService _apiService = FingerFaceApiService();
  static int? employeeId;
  String? employeeCode;

  // ================ Lifecycle Methods ================
  @override
  void initState() {
    super.initState();
    _configureAWS();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)!.settings.arguments as String;
      if (arguments != null) {
        employeeCode = arguments;
      }
    });
  }

  // @override
  // void dispose() async {
  //   // TODO: implement dispose
  //   await SharedPrefsHelper.clearValue('employeeId');
  //   log("Value clreareed");
  //   super.dispose();
  // }

  // ================ AWS Configuration ================
  void _configureAWS() {
    final credentials = rekognition.AwsClientCredentials(
      accessKey: configs.accessKeyId,
      secretKey: configs.secretAccessKey,
    );

    rekognitionClient = rekognition.Rekognition(
      region: configs.region,
      credentials: credentials,
    );

    dynamoDb = DynamoDB(
      region: configs.region,
      credentials: credentials,
    );
  }

  // ================ Loading & Messages ================
  void _setLoading(bool value) {
    if (mounted) {
      setState(() {
        isLoading = value;
        isActionInProgress = value;
      });
    }
  }

  void _showSnackBar(String message, {SnackBarType type = SnackBarType.info}) {
    SnackbarHelper.showSnackBar(context, message, type: type);
  }

  // ================ Image Handling ================
  Future<void> pickImage(String action) async {
    // base64Images = [];
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    // Maintain array of up to three Base64 images
    if (base64Images.length == 3) {
      base64Images.removeAt(0); // Remove the oldest image
    }
    base64Images.add(base64Image);

    setState(() {
      _imagePath = image.path;
    });

    // await _showUsernameDialog();
    try {
      _setLoading(true);
      await _processFaceRegistration(employeeCode!);
    } catch (e) {
      _showSnackBar('Error during face registration', type: SnackBarType.error);
    } finally {
      _setLoading(false);
    }
  }

  // // ================ Dialog Handling ================
  // Future<void> _showUsernameDialog() async {
  //   final employeeCode = await _promptForEmployeeCode();
  //   if (employeeCode?.isNotEmpty != true) return;
  //
  //   try {
  //     _setLoading(true);
  //     await _processFaceRegistration(employeeCode!);
  //   } catch (e) {
  //     _showSnackBar('Error during face registration', type: SnackBarType.error);
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<String?> _promptForEmployeeCode() async {
  //   String? employeeCode;
  //
  //   await showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Enter Your Employee Code'),
  //       content: TextField(
  //         onChanged: (value) => employeeCode = value.trim(),
  //         decoration: const InputDecoration(hintText: "Employee Code"),
  //       ),
  //       actions: [
  //         TextButton(
  //           child: const Text('Cancel'),
  //           onPressed: () => Navigator.of(context).pop(),
  //         ),
  //         TextButton(
  //           child: const Text('OK'),
  //           onPressed: () {
  //             if (employeeCode?.isNotEmpty ?? false) {
  //               Navigator.of(context).pop();
  //             }
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   return employeeCode;
  // }

  // ================ Registration and Search ================
  Future<void> _processFaceRegistration(String employeeCode) async {
    // This validation means to get the employee ID using employee Code.
    if (!await _validateEmployee(employeeCode)) {
      _showSnackBar('Invalid employee code', type: SnackBarType.error);
      Navigator.pop(context);
      return;
    }

    // Checking if the user can add face or not
    if (!await _canAddFace()) {
      _showSnackBar('Cannot add face', type: SnackBarType.error);
      // Navigator.pop(context);
      return;
    }

    // Indexing the face data through amazon rekognition
    final response = await _indexFaces(_imagePath!, employeeCode);
    if (response?.faceRecords?.isEmpty ?? true) {
      _showSnackBar('Failed to index face', type: SnackBarType.error);
      return;
    }

    // At the end register the user.
    final result = await _registerFace();
    if (result?['isSuccess'] == true) {
      _showSnackBar(result!['content'], type: SnackBarType.success);
      Navigator.pop(context);
    } else {
      await _deleteFace(faceId!);
    }
  }

  Future<bool> _validateEmployee(String empCode) async {
    try {
      final response = await _apiService.getEmployeeId(context, empCode);
      if (response != null) {
        await SharedPrefsHelper.setEmployeeId(response);
        setState(() => employeeId = response);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _canAddFace() async {
    try {
      final response = await _apiService.canAddFingerprint(
        employeeId.toString(),
        type: 'face',
      );

      final canAdd = response.data['isSuccess'] == true;
      if (canAdd) {
        SnackbarHelper.showSnackBar(context, "Face registration allowed",
            type: SnackBarType.success);
      }
      return canAdd;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _registerFace() async {
    if (base64Images.isEmpty || faceId == null) {
      SnackbarHelper.showSnackBar(
        context,
        'No face data available for registration.',
        type: SnackBarType.error,
      );
      return null;
    }

    _setLoading(true);

    try {
      final response = await _apiService.registerUserFace(
        employeeId: employeeId.toString(),
        faceId: faceId!,
        images: base64Images,
      );
      log(faceId!);
      log(base64Images.toString());

      if (response['isSuccess'] == true) {
        SnackbarHelper.showSnackBar(
          context,
          'Face registration successful: ${response['content']}',
          type: SnackBarType.success,
        );
        return response;
      } else {
        SnackbarHelper.showSnackBar(
          context,
          'Failed to register face: ${response['content'] ?? response['errorMessage']}',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      SnackbarHelper.showSnackBar(
        context,
        'Error registering face: $e',
        type: SnackBarType.error,
      );
    } finally {
      Future.delayed(Duration(seconds: 3));
      _setLoading(false);
      _imagePath = null;
      attendanceRecords = [];
    }

    return null;
  }

  Future<rekognition.IndexFacesResponse?> _indexFaces(
      String imagePath, String userName) async {
    String sanitizedName = userName.trim().replaceAll(' ', '_');
    _setLoading(true);

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final response = await rekognitionClient.indexFaces(
        collectionId: configs.collectionId,
        image: rekognition.Image(bytes: Uint8List.fromList(imageBytes)),
        externalImageId: sanitizedName,
        maxFaces: 1,
        qualityFilter: rekognition.QualityFilter.auto,
      );

      if (response.faceRecords != null && response.faceRecords!.isNotEmpty) {
        final face = response.faceRecords!.first.face!;
        faceId = face.faceId;
        imageId = face.imageId;

        _showSnackBar(
          'Face indexed successfully as "${face.externalImageId}" in AWS collection.',
        );
        return response;
      } else {
        _showSnackBar('No face detected in the image.');
      }
    } catch (e) {
      _showSnackBar('Error indexing face: $e');
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<bool> _deleteFace(String faceId) async {
    _setLoading(true);

    try {
      final response = await rekognitionClient.deleteFaces(
        collectionId: configs.collectionId,
        faceIds: [faceId], // Specify the faceId to delete
      );

      if (response.deletedFaces != null && response.deletedFaces!.isNotEmpty) {
        _showSnackBar(
            'Face with ID "$faceId" deleted successfully from AWS collection.');
        return true;
      } else {
        _showSnackBar('No face found with the specified ID.');
      }
    } catch (e) {
      _showSnackBar('Error deleting face: $e');
    } finally {
      _setLoading(false);
    }

    return false;
  }

// ================ UI Widgets ================

// Image Preview with Rounded Corners
  Widget _buildImagePreview() => _imagePath == null || _imagePath!.isEmpty
      ? Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/person_placeholder.png', // Placeholder image
              width: 180,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        )
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_imagePath!),
              width: 180,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        );

// Modern Action Buttons with Elevated Design
  Widget _buildActionButtons() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TextButton(
            //   child: Text('Delete'),
            //
            //   onPressed: () {
            //     _deleteFace(faceId!);
            //   },
            // ),
            ElevatedButton.icon(
              onPressed:
                  isActionInProgress ? null : () => pickImage('register'),
              icon: const Icon(
                Icons.person_add,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'Register Face',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF17a2b8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
        centerTitle: true,
        backgroundColor: Color(0xFF17a2b8),
      ),
      body: Container(
        width: double.infinity, // Ensures it covers the full width
        height: MediaQuery.of(context)
            .size
            .height, // Ensures it covers the full height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[400]!,
                        highlightColor: Colors.grey[100]!,
                        child: const Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  _buildImagePreview(),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Main UI with Modern Layout
//   @override
//   Widget build(BuildContext context) => Scaffold(
//         appBar: AppBar(
//           title: const Text('Face Recognition'),
//           centerTitle: true,
//           backgroundColor: Color(0xFF17a2b8),
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               if (isLoading)
//                 Padding(
//                   padding: EdgeInsets.symmetric(vertical: 20),
//                   child: Shimmer.fromColors(
//                     baseColor: Colors.grey[400]!,
//                     highlightColor: Colors.grey[100]!,
//                     child: const Text(
//                       'Loading...',
//                       style: TextStyle(
//                         fontSize: 28.0,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               _buildImagePreview(),
//               _buildActionButtons(),
//             ],
//           ),
//         ),
//       );
}
