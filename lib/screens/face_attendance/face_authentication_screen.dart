// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:aws_rekognition_api/rekognition-2016-06-27.dart' as rekognition;
// import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';
//
// import 'configs.dart';
//
//
// class FaceRecognitionScreen extends StatefulWidget {
//   static String routeName = '/faceAuthScreen';
//
//   const FaceRecognitionScreen({super.key});
//   @override
//   _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
// }
//
// class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
//   String? _imagePath;
//   List<Map<String, String>> attendanceRecords = [];
//   String? displayMessage;
//   bool isLoading = false; // Indicates loading state
//   final configs = FaceAuthConfigs();
//
//
//   // // AWS Configuration
//   // For Remote Users
//   // final String collectionId = 'CollectionName';
//   // final String region = 'us-east-1';
//   // final String accessKeyId = 'AccessID';
//   // final String secretAccessKey = 'secretKey';
//   // final String tableName = 'TableName'; // DynamoDB table name
//
//
//   late rekognition.Rekognition rekognitionClient;
//   late DynamoDB dynamoDb;
//
//   @override
//   void initState() {
//     super.initState();
//     configureAWS();
//   }
//
//   // AWS Configuration for Rekognition and DynamoDB
//   void configureAWS() {
//     final credentials = rekognition.AwsClientCredentials(
//       accessKey: configs.accessKeyId,
//       secretKey: configs.secretAccessKey,
//     );
//
//     rekognitionClient = rekognition.Rekognition(
//       region: configs.region,
//       credentials: credentials,
//     );
//
//     dynamoDb = DynamoDB(
//       region: configs.region,
//       credentials: credentials,
//     );
//   }
//
//   // Show a loading indicator while registering or searching
//   void setLoading(bool value) {
//     setState(() {
//       isLoading = value;
//     });
//   }
//
//   // Image Picker Function
//   Future<void> pickImage(String action) async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image =
//         await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
//
//     if (image != null) {
//       setState(() {
//         _imagePath = image.path;
//       });
//
//       if (action == 'search') {
//         await searchFaces(_imagePath!);
//       } else {
//         _showUsernameDialog(); // Show dialog to enter username for registration
//       }
//     }
//   }
//
//   // Show dialog for entering username
//   Future<void> _showUsernameDialog() async {
//     String? userName;
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Enter Username'),
//           content: TextField(
//             onChanged: (value) {
//               userName = value;
//             },
//             decoration: InputDecoration(hintText: "Username"),
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//
//     if (userName != null && userName!.isNotEmpty) {
//       await indexFaces(_imagePath!,
//           userName!); // Register the face with the entered username
//     }
//   }
//
//   // Register User's Face
//   Future<void> indexFaces(String imagePath, String userName) async {
//     String usersanitizedName = userName.trim().replaceAll(' ', '_');
//
//     setLoading(true);
//     try {
//       final imageBytes = await File(imagePath).readAsBytes();
//
//       final response = await rekognitionClient.indexFaces(
//         collectionId: configs.collectionId,
//         image: rekognition.Image(bytes: Uint8List.fromList(imageBytes)),
//         externalImageId:
//             usersanitizedName, // Store user's name as ExternalImageId
//         maxFaces: 1,
//         qualityFilter: rekognition.QualityFilter.auto,
//       );
//
//       if (response.faceRecords != null && response.faceRecords!.isNotEmpty) {
//         showTemporaryMessage('User registered successfully as $userName!');
//       }
//     } catch (e) {
//       print('Error in indexFaces: $e');
//       showTemporaryMessage('Failed to register user.');
//     } finally {
//       setLoading(false);
//     }
//   }
//
//   // Show a temporary message for 2 seconds
//   void showTemporaryMessage(String message) {
//     setState(() {
//       displayMessage = message;
//     });
//     Timer(Duration(seconds: 8), () {
//       setState(() {
//         displayMessage = null;
//         _imagePath = null;
//         attendanceRecords = [];
//       });
//     });
//   }
//
//   // Search for User's Face and Log Attendance
//   Future<void> searchFaces(String imagePath) async {
//     setLoading(true);
//     try {
//       final imageBytes = await File(imagePath).readAsBytes();
//
//       final response = await rekognitionClient.searchFacesByImage(
//         collectionId: configs.collectionId,
//         image: rekognition.Image(bytes: Uint8List.fromList(imageBytes)),
//         faceMatchThreshold: 90,
//         maxFaces: 1,
//       );
//
//       if (response.faceMatches != null && response.faceMatches!.isNotEmpty) {
//         final recognizedFace = response.faceMatches!.first.face;
//         final rekognitionId = recognizedFace?.faceId;
//         final userName = recognizedFace?.externalImageId;
//         if (rekognitionId != null && userName != null) {
//           // Log attendance only if both rekognitionId and externalImageId are available
//           await logAttendance(rekognitionId, userName);
//           showTemporaryMessage('User found: $userName, attendance marked.');
//           await getAttendanceRecords(rekognitionId); // Fetch attendance history
//         }
//       } else {
//         showTemporaryMessage('No matching faces found.');
//       }
//     } catch (e) {
//       print('Error in searchFaces: $e');
//       showTemporaryMessage('Error during search.');
//     } finally {
//       setLoading(false);
//     }
//   }
//
//   // Log Attendance to DynamoDB
//   Future<void> logAttendance(
//       String rekognitionId, String externalImageId) async {
//     final now = DateTime.now();
//     final timestamp =
//         now.toIso8601String(); // Unique timestamp for each log entry
//
//     final attendanceRecord = {
//       'RekognitionId': AttributeValue(s: rekognitionId), // Partition key
//       'Timestamp':
//           AttributeValue(s: timestamp), // Unique timestamp for each log
//       'UserName': AttributeValue(s: externalImageId), // Name or unique ID
//       'Status': AttributeValue(s: 'Present'), // Status attribute, if needed
//     };
//
//     try {
//       await dynamoDb.putItem(
//         tableName: configs.tableName,
//         item: attendanceRecord,
//       );
//       print('Attendance logged for user $rekognitionId at $timestamp');
//     } catch (e) {
//       print('Failed to log attendance: $e');
//     }
//   }
//
//   // Fetch Attendance Records from DynamoDB
//   Future<void> getAttendanceRecords(String rekognitionId) async {
//     try {
//       final response = await dynamoDb.query(
//         tableName: configs.tableName,
//         keyConditionExpression: 'RekognitionId = :rekognitionId',
//         expressionAttributeValues: {
//           ':rekognitionId': AttributeValue(s: rekognitionId),
//         },
//       );
//
//       setState(() {
//         attendanceRecords = response.items?.map((item) {
//               return {
//                 'Timestamp': item['Timestamp']?.s ?? 'Unknown',
//                 'ExternalImageId': item['ExternalImageId']?.s ?? 'Unknown',
//                 'Status': item['Status']?.s ?? 'Unknown',
//               };
//             }).toList() ??
//             [];
//       });
//       // Timer(Duration(seconds: 8), () {
//       //   setState(() {
//       //     attendanceRecords = [];
//       //   });
//       // });
//     } catch (e) {
//       print('Failed to fetch attendance records: $e');
//     }
//   }
//
//   // UI for the Attendance App
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Attendance App with AWS'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             if (_imagePath != null) ...[
//               SizedBox(
//                 width: 150, // Adjust width as desired
//                 height: 150, // Adjust height as desired
//                 child: Image.file(
//                   File(_imagePath!),
//                   fit: BoxFit
//                       .cover, // Optionally, use BoxFit to control how the image fits within the box
//                 ),
//               ),
//               SizedBox(height: 20),
//             ],
//             if (isLoading)
//               CircularProgressIndicator()
//             else if (displayMessage != null) ...[
//               Text(
//                 displayMessage!,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 20),
//             ],
//             ElevatedButton(
//               onPressed: () => pickImage('register'),
//               child: Text('Register User'),
//             ),
//             ElevatedButton(
//               onPressed: () => pickImage('search'),
//               child: Text('Search & Log Attendance'),
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Attendance Records:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             Expanded(
//               child: attendanceRecords.isNotEmpty
//                   ? ListView.builder(
//                       itemCount: attendanceRecords.length,
//                       itemBuilder: (context, index) {
//                         final record = attendanceRecords[index];
//                         return Card(
//                           margin:
//                               EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                           child: ListTile(
//                             leading:
//                                 Icon(Icons.date_range, color: Colors.indigo),
//                             title: Text('Date: ${record['Timestamp']}'),
//                             subtitle: Text('Status: ${record['Status']}'),
//                           ),
//                         );
//                       },
//                     )
//                   : Center(
//                       child: Text(
//                         'No attendance records found.',
//                         style: TextStyle(fontSize: 16, color: Colors.grey),
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:aws_rekognition_api/rekognition-2016-06-27.dart' as rekognition;
// import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';
// import 'package:pbi_time/utils/sharedPreferencesHelper.dart';
// import '../../services/fingerPrint_apiService.dart';
// import '../../utils/snackBar.dart';
// import 'configs.dart';
//
// class FaceRecognitionScreen extends StatefulWidget {
//   static String routeName = '/faceAuthScreen';
//
//   const FaceRecognitionScreen({super.key});
//   @override
//   _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
// }
//
// class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
//   // ================ State Variables ================
//   String? _imagePath;
//   List<Map<String, String>> attendanceRecords = [];
//   String? displayMessage;
//   bool isLoading = false;
//   final configs = FaceAuthConfigs();
//   List<String> base64Images = []; // Array to store Base64 strings
//   String? faceId;
//   String? imageId;
//
//   // ================ AWS Clients ================
//   late rekognition.Rekognition rekognitionClient;
//   late DynamoDB dynamoDb;
//
//   // ================ Local DB auth variables ================
//   final FingerFaceApiService _apiService = FingerFaceApiService();
//   static int? employeeId;
//
//   // ================ Lifecycle Methods ================
//   @override
//   void initState() {
//     super.initState();
//     _configureAWS();
//   }
//
//   // ================ AWS Configuration ================
//   void _configureAWS() {
//     final credentials = rekognition.AwsClientCredentials(
//       accessKey: configs.accessKeyId,
//       secretKey: configs.secretAccessKey,
//     );
//
//     rekognitionClient = rekognition.Rekognition(
//       region: configs.region,
//       credentials: credentials,
//     );
//
//     dynamoDb = DynamoDB(
//       region: configs.region,
//       credentials: credentials,
//     );
//   }
//
//   // ================ UI State Methods ================
//   void _setLoading(bool value) {
//     setState(() {
//       isLoading = value;
//     });
//   }
//
//   void _showTemporaryMessage(String message) {
//     setState(() {
//       displayMessage = message;
//     });
//     Timer(Duration(seconds: 8), () {
//       if (mounted) {
//         setState(() {
//           displayMessage = null;
//           _imagePath = null;
//           attendanceRecords = [];
//         });
//       }
//     });
//   }
//
//   // ================ Image Handling ================
//   // Future<void> pickImage(String action) async {
//   //   final ImagePicker picker = ImagePicker();
//   //   final XFile? image =
//   //       await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
//   //
//   //   if (image != null) {
//   //     setState(() {
//   //       _imagePath = image.path;
//   //     });
//   //
//   //     if (action == 'search') {
//   //       await _searchFaces(_imagePath!);
//   //     } else {
//   //       await _showUsernameDialog();
//   //     }
//   //   }
//   // }
//
// // ================ Dialog Methods ================
//
//   Future<void> pickImage(String action) async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image =
//         await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
//
//     if (image != null) {
//       // Convert to Base64
//       final File imageFile = File(image.path);
//       final bytes = await imageFile.readAsBytes();
//       final base64Image = base64Encode(bytes);
//
//       log(base64Image);
//
//       // Maintain array of up to three Base64 images
//       if (base64Images.length == 3) {
//         base64Images.removeAt(0); // Remove the oldest image
//       }
//       base64Images.add(base64Image);
//
//       setState(() {
//         _imagePath = image.path;
//       });
//
//       // Perform action
//       if (action == 'search') {
//         await _searchFaces(_imagePath!);
//       } else {
//         await _showUsernameDialog();
//       }
//     }
//   }
//
//   Future<void> _showUsernameDialog() async {
//     final employeeCode = await _promptForEmployeeCode();
//     if (employeeCode == null || employeeCode.isEmpty) return;
//
//     try {
//       setState(() => isLoading = true);
//       await _processFaceRegistration(employeeCode);
//     } catch (e) {
//       SnackbarHelper.showSnackBar(
//           context,
//           'An error occurred during face registration',
//           type: SnackBarType.error
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   Future<String?> _promptForEmployeeCode() async {
//     String? employeeCode;
//
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Enter Your Employee Code'),
//         content: TextField(
//           onChanged: (value) => employeeCode = value.trim(),
//           decoration: const InputDecoration(hintText: "Employee Code"),
//         ),
//         actions: [
//           TextButton(
//             child: const Text('Cancel'),
//             onPressed: () {
//               employeeCode = null;
//               Navigator.of(context).pop();
//             },
//           ),
//           TextButton(
//             child: const Text('OK'),
//             onPressed: () {
//               if (employeeCode?.isNotEmpty ?? false) {
//                 Navigator.of(context).pop();
//               }
//             },
//           ),
//         ],
//       ),
//     );
//
//     return employeeCode;
//   }
//
//   Future<void> _processFaceRegistration(String employeeCode) async {
//     // Validate employee
//     if (!await _validateEmployee(employeeCode)) {
//       SnackbarHelper.showSnackBar(
//           context,
//           'Invalid employee code',
//           type: SnackBarType.error
//       );
//       return;
//     }
//
//     // Check if face can be added
//     if (!await _canAddFace()) {
//       SnackbarHelper.showSnackBar(
//           context,
//           'Cannot add face at this time',
//           type: SnackBarType.error
//       );
//       return;
//     }
//
//     // Process face indexing and registration
//     await _processFaceIndexingAndRegistration(employeeCode);
//   }
//
//   Future<bool> _validateEmployee(String empCode) async {
//     try {
//       final response = await _apiService.getEmployeeId(context, empCode);
//       if (response != null) {
//         await SharedPrefsHelper.setEmployeeId(response);
//         setState(() => employeeId = response);
//         return true;
//       }
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   Future<bool> _canAddFace() async {
//     try {
//       final response = await _apiService.canAddFingerprint(
//         employeeId.toString(),
//         type: 'face',
//       );
//
//       final canAdd = response.data['isSuccess'] == true;
//       if (canAdd) {
//         SnackbarHelper.showSnackBar(
//             context,
//             "Face registration allowed",
//             type: SnackBarType.success
//         );
//       }
//       return canAdd;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   Future<void> _processFaceIndexingAndRegistration(String employeeCode) async {
//     if (_imagePath == null) {
//       SnackbarHelper.showSnackBar(
//           context,
//           'No image selected',
//           type: SnackBarType.error
//       );
//       return;
//     }
//
//     final response = await _indexFaces(_imagePath!, employeeCode);
//     if (response?.faceRecords?.isEmpty ?? true) {
//       SnackbarHelper.showSnackBar(
//           context,
//           'Failed to index face',
//           type: SnackBarType.error
//       );
//       return;
//     }
//
//     final result = await _registerFace();
//     if (result?['isSuccess'] ?? false) {
//       SnackbarHelper.showSnackBar(
//           context,
//           result!['content'],
//           type: SnackBarType.success
//       );
//     }
//   }
//
//   // ================ AWS Face Recognition Methods ================  For Multiple Images of a Single User
//   // Future<void> _indexMultipleImages(List<String> imagePaths, String userName) async {
//   //   String sanitizedName = userName.trim().replaceAll(' ', '_'); // Unified external ID for all images
//   //   List<String> faceIds = []; // To store all detected Face IDs across images
//   //
//   //   _setLoading(true);
//   //
//   //   try {
//   //     for (String imagePath in imagePaths) {
//   //       final imageBytes = await File(imagePath).readAsBytes();
//   //       final response = await rekognitionClient.indexFaces(
//   //         collectionId: configs.collectionId,
//   //         image: rekognition.Image(bytes: Uint8List.fromList(imageBytes)),
//   //         externalImageId: sanitizedName,
//   //         maxFaces: 3, // Allow up to 3 faces per image
//   //         qualityFilter: rekognition.QualityFilter.auto,
//   //       );
//   //
//   //       if (response.faceRecords != null && response.faceRecords!.isNotEmpty) {
//   //         // Extract and add FaceIds for each image
//   //         final imageFaceIds = response.faceRecords!
//   //             .map((record) => record.face?.faceId)
//   //             .where((id) => id != null)
//   //             .toList();
//   //
//   //         faceIds.addAll(imageFaceIds);
//   //
//   //         // Log and display FaceIds for this image
//   //         for (var faceId in imageFaceIds) {
//   //           print('Detected FaceId: $faceId');
//   //           SnackbarHelper.showSnackBar(
//   //             context,
//   //             'Detected FaceId: $faceId',
//   //             type: SnackBarType.success,
//   //           );
//   //         }
//   //       } else {
//   //         _showTemporaryMessage('No faces detected in one of the images.');
//   //       }
//   //     }
//   //
//   //     // Final Success Message
//   //     if (faceIds.isNotEmpty) {
//   //       _showTemporaryMessage(
//   //           'User registered successfully as $userName with ${faceIds.length} face(s) across ${imagePaths.length} image(s)!');
//   //     } else {
//   //       _showTemporaryMessage('No faces detected in any of the images.');
//   //     }
//   //   } catch (e) {
//   //     print('Error in indexing faces: $e');
//   //     _showTemporaryMessage('Failed to register user.');
//   //   } finally {
//   //     _setLoading(false);
//   //   }
//   // }
//
//   Future<Map<String, dynamic>?> _registerFace() async {
//     // setState(() {
//     //   isLoading = true;
//     // });
//     try {
//       final response = await _apiService.registerUserFace(
//           employeeId: employeeId.toString(),
//           faceId: faceId!,
//           images: base64Images);
//       if (response['isSuccess'] == true) {
//         // SnackbarHelper.showSnackBar(context, response['content']);
//         return response;
//       }
//       return null;
//     } catch (e) {
//       throw Exception(e);
//       // return false;
//     }
//     finally{
//       isLoading = false;
//     }
//   }
//
//   Future<rekognition.IndexFacesResponse?> _indexFaces( String imagePath, String userName) async {
//     String sanitizedName = userName.trim().replaceAll(' ', '_');
//     _setLoading(true);
//
//     try {
//       final imageBytes = await File(imagePath).readAsBytes();
//       final response = await rekognitionClient.indexFaces(
//         collectionId: configs.collectionId,
//         image: rekognition.Image(bytes: Uint8List.fromList(imageBytes)),
//         externalImageId: sanitizedName,
//         maxFaces: 1,
//         qualityFilter: rekognition.QualityFilter.auto,
//       );
//
//       if (response.faceRecords != null && response.faceRecords!.isNotEmpty) {
//         _showTemporaryMessage(
//             'User Saved In AWS_Collection as ${response.faceRecords![0].face!.externalImageId}');
//         faceId = response.faceRecords![0].face!.faceId;
//         imageId = response.faceRecords![0].face!.imageId;
//
//         // SnackbarHelper.showSnackBar(context, response.faceRecords![0].face!.faceId!);
//
//         return response;
//       }
//       return null;
//     } catch (e) {
//       print('Error in indexFaces: $e');
//       _showTemporaryMessage('Failed to register user.');
//     } finally {
//       _setLoading(false);
//     }
//     return null;
//   }
//
//   Future<void> _searchFaces(String imagePath) async {
//     _setLoading(true);
//     try {
//       final imageBytes = await File(imagePath).readAsBytes();
//       final response = await rekognitionClient.searchFacesByImage(
//         collectionId: configs.collectionId,
//         image: rekognition.Image(bytes: Uint8List.fromList(imageBytes)),
//         faceMatchThreshold: 90,
//         maxFaces: 1,
//       );
//
//       if (response.faceMatches != null && response.faceMatches!.isNotEmpty) {
//         final recognizedFace = response.faceMatches!.first.face;
//         final rekognitionId = recognizedFace?.faceId;
//         final userName = recognizedFace?.externalImageId;
//
//         if (rekognitionId != null && userName != null) {
//           await _logAttendance(rekognitionId, userName);
//           _showTemporaryMessage('User found: $userName, attendance marked.');
//           await _getAttendanceRecords(rekognitionId);
//         }
//       } else {
//         _showTemporaryMessage('No matching faces found.');
//       }
//     } catch (e) {
//       print('Error in searchFaces: $e');
//       _showTemporaryMessage('Error during search.');
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // ================ AWS DynamoDB Methods ================
//   Future<void> _logAttendance(String rekognitionId, String userName) async {
//     try {
//       final now = DateTime.now();
//       final timestamp = now.toIso8601String();
//
//       final attendanceRecord = {
//         'RekognitionId': AttributeValue(s: rekognitionId),
//         'Timestamp': AttributeValue(s: timestamp),
//         'UserName': AttributeValue(s: userName),
//         'Status': AttributeValue(s: 'Present'),
//       };
//
//       await dynamoDb.putItem(
//         tableName: configs.tableName,
//         item: attendanceRecord,
//       );
//       print('Attendance logged for user $userName at $timestamp');
//     } catch (e) {
//       print('Failed to log attendance: $e');
//       throw e;
//     }
//   }
//
//   Future<void> _getAttendanceRecords(String rekognitionId) async {
//     try {
//       final response = await dynamoDb.query(
//         tableName: configs.tableName,
//         keyConditionExpression: 'RekognitionId = :rekognitionId',
//         expressionAttributeValues: {
//           ':rekognitionId': AttributeValue(s: rekognitionId),
//         },
//       );
//
//       if (mounted) {
//         setState(() {
//           attendanceRecords = response.items?.map((item) {
//                 return {
//                   'Timestamp': item['Timestamp']?.s ?? 'Unknown',
//                   'UserName': item['UserName']?.s ?? 'Unknown',
//                   'Status': item['Status']?.s ?? 'Unknown',
//                 };
//               }).toList() ??
//               [];
//         });
//       }
//     } catch (e) {
//       print('Failed to fetch attendance records: $e');
//     }
//   }
//
//   // ================ UI Widgets ================
//   Widget _buildImagePreview() {
//     if (_imagePath == null) return SizedBox.shrink();
//
//     return Column(
//       children: [
//         SizedBox(
//           width: 150,
//           height: 150,
//           child: Image.file(File(_imagePath!), fit: BoxFit.cover),
//         ),
//         SizedBox(height: 20),
//       ],
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Column(
//       children: [
//         ElevatedButton(
//           onPressed: () => pickImage('register'),
//           child: Text('Register User'),
//         ),
//         SizedBox(height: 10),
//         ElevatedButton(
//           onPressed: () => pickImage('search'),
//           child: Text('Search & Log Attendance'),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildAttendanceList() {
//     return Expanded(
//       child: Column(
//         children: [
//           Text(
//             'Attendance Records:',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 10),
//           Expanded(
//             child: attendanceRecords.isEmpty
//                 ? Center(
//                     child: Text(
//                       'No attendance records found.',
//                       style: TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                   )
//                 : ListView.builder(
//                     itemCount: attendanceRecords.length,
//                     itemBuilder: (context, index) {
//                       final record = attendanceRecords[index];
//                       return Card(
//                         margin: EdgeInsets.symmetric(
//                           vertical: 5,
//                           horizontal: 10,
//                         ),
//                         child: ListTile(
//                           leading: Icon(Icons.date_range, color: Colors.indigo),
//                           title: Text('Date: ${record['Timestamp']}'),
//                           subtitle: Text('Status: ${record['Status']}'),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================ Main Build Method ================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Attendance App with AWS'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _buildImagePreview(),
//             if (isLoading)
//               CircularProgressIndicator()
//             else if (displayMessage != null) ...[
//               Text(
//                 displayMessage!,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 20),
//             ],
//             _buildActionButtons(),
//             SizedBox(height: 20),
//             _buildAttendanceList(),
//           ],
//         ),
//       ),
//     );
//   }
// }

//

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aws_rekognition_api/rekognition-2016-06-27.dart' as rekognition;
import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/fingerPrint_apiService.dart';
import '../../services/mark_attendance_service.dart';
import '../../utils/sharedPreferencesHelper.dart';
import '../../utils/snackBar.dart';
import 'configs.dart';

class FaceRecognitionScreen extends StatefulWidget {
  static const String routeName = '/faceAuthScreen';

  const FaceRecognitionScreen({super.key});
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
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

  // ================ Lifecycle Methods ================
  @override
  void initState() {
    super.initState();
    _configureAWS();
  }

  @override
  void dispose() async {
    // TODO: implement dispose
    await SharedPrefsHelper.clearValue('employeeId');
    log("Value clreareed");
    super.dispose();
  }

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

    if (action == 'search') {
      await _searchFaces(_imagePath!);
    } else {
      await _showUsernameDialog();
    }
  }

  // ================ Dialog Handling ================
  Future<void> _showUsernameDialog() async {
    final employeeCode = await _promptForEmployeeCode();
    if (employeeCode?.isNotEmpty != true) return;

    try {
      _setLoading(true);
      await _processFaceRegistration(employeeCode!);
    } catch (e) {
      _showSnackBar('Error during face registration', type: SnackBarType.error);
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> _promptForEmployeeCode() async {
    String? employeeCode;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Your Employee Code'),
        content: TextField(
          onChanged: (value) => employeeCode = value.trim(),
          decoration: const InputDecoration(hintText: "Employee Code"),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              if (employeeCode?.isNotEmpty ?? false) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );

    return employeeCode;
  }

  // ================ Registration and Search ================
  Future<void> _processFaceRegistration(String employeeCode) async {
    // This validation means to get the employee ID using employee Code.
    if (!await _validateEmployee(employeeCode)) {
      _showSnackBar('Invalid employee code', type: SnackBarType.error);
      return;
    }

    // Checking if the user can add face or not
    if (!await _canAddFace()) {
      _showSnackBar('Cannot add face at this time', type: SnackBarType.error);
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

  Future<void> _searchFaces(String imagePath) async {
    _setLoading(true);
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final response = await rekognitionClient.searchFacesByImage(
        collectionId: configs.collectionId,
        image: rekognition.Image(bytes: Uint8List.fromList(imageBytes)),
        faceMatchThreshold: 90,
        maxFaces: 1,
      );

      if (response.faceMatches?.isNotEmpty ?? false) {
        final matchedFace = response.faceMatches!.first.face;
        if (matchedFace != null) {
          // logging means storing in db

          // await _logAttendance(
          //     matchedFace.faceId!, matchedFace.externalImageId!);
          // _showSnackBar(
          // 'User found: ${matchedFace.externalImageId}, attendance marked.');

          // get and show the logs in the screen

          // await _getAttendanceRecords(matchedFace.faceId!);
          await _validateEmployee(
              matchedFace.externalImageId!); //to get the employee ID.
          final response = await _markAttendance.markAttendance(
              employeeId.toString(), 'Face');

          if (response != null) {
            _showSnackBar(response, type: SnackBarType.success);
          }
        }
      } else {
        _showSnackBar('No matching faces found.');
      }
    } catch (e) {
      _showSnackBar('Error during search', type: SnackBarType.error);
    } finally {
      _setLoading(false);
      _imagePath = null;
      attendanceRecords = [];
    }
  }

  // ================ DynamoDB Attendance Logging ================
  Future<void> _logAttendance(String rekognitionId, String userName) async {
    try {
      final now = DateTime.now().toIso8601String();
      final attendanceRecord = {
        'RekognitionId': AttributeValue(s: rekognitionId),
        'Timestamp': AttributeValue(s: now),
        'UserName': AttributeValue(s: userName),
        'Status': AttributeValue(s: 'Present'),
      };

      await dynamoDb.putItem(
        tableName: configs.tableName,
        item: attendanceRecord,
      );
    } catch (e) {
      _showSnackBar('Failed to log attendance', type: SnackBarType.error);
    }
  }

  Future<void> _getAttendanceRecords(String rekognitionId) async {
    try {
      final response = await dynamoDb.query(
        tableName: configs.tableName,
        keyConditionExpression: 'RekognitionId = :rekognitionId',
        expressionAttributeValues: {
          ':rekognitionId': AttributeValue(s: rekognitionId),
        },
      );

      setState(() {
        attendanceRecords = response.items?.map((item) {
              return {
                'Timestamp': item['Timestamp']?.s ?? 'Unknown',
                'UserName': item['UserName']?.s ?? 'Unknown',
                'Status': item['Status']?.s ?? 'Unknown',
              };
            }).toList() ??
            [];
      });
    } catch (e) {
      _showSnackBar('Failed to fetch attendance records',
          type: SnackBarType.error);
    }
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
            ElevatedButton.icon(
              onPressed: isActionInProgress ? null : () => pickImage('search'),
              icon: const Icon(
                Icons.search,
                size: 20,
              ),
              label: const Text('Mark Attendance'),
              style: ElevatedButton.styleFrom(
                iconColor: Colors.white,
                foregroundColor: Colors.white,
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

// Modern Attendance List with Card Design
  Widget _buildAttendanceList() {
    if (attendanceRecords.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: const Text(
          'No attendance records found.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 5,
        ),
        itemCount: attendanceRecords.length,
        itemBuilder: (context, index) {
          final record = attendanceRecords[index];
          return Card(
            color: Colors.indigo.shade50,
            shadowColor: Colors.indigo,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.date_range, color: Colors.indigo),
              title: Text(
                record['UserName'] ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Time: ${record['Timestamp'] ?? 'N/A'}\nStatus: ${record['Status'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          );
        },
      ),
    );
  }

// Main UI with Modern Layout
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
                    // const Divider(height: 30, thickness: 1),
                    // const Text(
                    //   'Attendance Records',
                    //   style:
                    //       TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    // ),
                    // _buildAttendanceList(),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}
