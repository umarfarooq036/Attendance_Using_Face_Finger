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
import '../../utils/attendanceTypes.dart';
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

  final _formKey = GlobalKey<FormState>();

  final configs = FaceAuthConfigs();
  List<String> base64Images = []; // Array to store Base64 strings
  String? faceId;
  String? imageId;

  // String? _selectedValue = attendanceTypes.first.keys.first;

  final MarkAttendanceService _markAttendance = MarkAttendanceService();

  // ================ AWS Clients ================
  late rekognition.Rekognition rekognitionClient;
  late DynamoDB dynamoDb;

  // ================ Local Variables ================
  final FingerFaceApiService _apiService = FingerFaceApiService();
  static int? employeeId;
  String? validationMessage;
  String? selectedOption;

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

  Future<rekognition.IndexFacesResponse?> _indexFaces(String imagePath, String userName) async { String sanitizedName = userName.trim().replaceAll(' ', '_');
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
              employeeId.toString(), 'Face',
              attendanceType: selectedOption);

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

  // Widget _buildActionTypes() {
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Container(
  //       padding: EdgeInsets.symmetric(horizontal: 16.0),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         border: Border.all(color: Colors.teal[700]!, width: 1.5),
  //         borderRadius: BorderRadius.circular(8.0),
  //       ),
  //       child: DropdownButtonFormField<String>(
  //         isExpanded: true,
  //         value: _selectedValue,
  //         decoration: InputDecoration(
  //           labelText: 'Attendance Type',
  //           hintText: 'Select Attendance Type',
  //           labelStyle: TextStyle(
  //             color: Colors.teal[700],
  //             fontWeight: FontWeight.w600,
  //           ),
  //           hintStyle: TextStyle(
  //             color: Colors.teal[400],
  //           ),
  //           border: InputBorder.none,
  //         ),
  //         icon: Icon(Icons.arrow_drop_down, color: Colors.teal[700]),
  //         dropdownColor: Colors.white,
  //         items: attendanceTypes.map((type) {
  //           String key = type.keys.first;
  //           return DropdownMenuItem<String>(
  //             value: key,
  //             child: Text(
  //               key,
  //               style: TextStyle(
  //                 color: Colors.teal[900],
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           );
  //         }).toList(),
  //         onChanged: (newValue) {
  //           setState(() {
  //             _selectedValue = newValue;
  //             log(newValue!);
  //           });
  //         },
  //         validator: (value) {
  //           // Ensure the user doesn't select the default placeholder
  //           if (value == null || value == 'Please Select') {
  //             return 'Please select a valid attendance type';
  //           }
  //           return null;
  //         },
  //       ),
  //     ),
  //   );
  // }

// Modern Action Buttons with Elevated Design

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

  Widget _buildActionButtons() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: isActionInProgress
                  ? null // Disable button when action is in progress
                  : () {
                final isSelected = _validateSelection();
                if (!isSelected) {
                  return;
                }
                if (_formKey.currentState!.validate()) {
                  pickImage('search');
                }
                else{
                  log('not validated');
                }
              },
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
      body: Form(
        key: _formKey,
        child: Container(
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
                      _buildActionTypes(),
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
      ),
    );
  }
}
