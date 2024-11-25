import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aws_rekognition_api/rekognition-2016-06-27.dart' as rekognition;
import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';

import 'configs.dart';


class FaceRecognitionScreen extends StatefulWidget {
  static String routeName = '/faceAuthScreen';

  const FaceRecognitionScreen({super.key});
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  String? _imagePath;
  List<Map<String, String>> attendanceRecords = [];
  String? displayMessage;
  bool isLoading = false; // Indicates loading state
  final configs = FaceAuthConfigs();


  // // AWS Configuration


  late rekognition.Rekognition rekognitionClient;
  late DynamoDB dynamoDb;

  @override
  void initState() {
    super.initState();
    configureAWS();
  }

  // AWS Configuration for Rekognition and DynamoDB
  void configureAWS() {
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

  // Show a loading indicator while registering or searching
  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  // Image Picker Function
  Future<void> pickImage(String action) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 75);

    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });

      if (action == 'search') {
        await searchFaces(_imagePath!);
      } else {
        _showUsernameDialog(); // Show dialog to enter username for registration
      }
    }
  }

  // Show dialog for entering username
  Future<void> _showUsernameDialog() async {
    String? userName;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Username'),
          content: TextField(
            onChanged: (value) {
              userName = value;
            },
            decoration: InputDecoration(hintText: "Username"),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (userName != null && userName!.isNotEmpty) {
      await indexFaces(_imagePath!,
          userName!); // Register the face with the entered username
    }
  }

  // Register User's Face
  Future<void> indexFaces(String imagePath, String userName) async {
    String usersanitizedName = userName.trim().replaceAll(' ', '_');

    setLoading(true);
    try {
      final imageBytes = await File(imagePath).readAsBytes();

      final response = await rekognitionClient.indexFaces(
        collectionId: configs.collectionId,
        image: rekognition.Image(bytes: Uint8List.fromList(imageBytes)),
        externalImageId:
            usersanitizedName, // Store user's name as ExternalImageId
        maxFaces: 1,
        qualityFilter: rekognition.QualityFilter.auto,
      );

      if (response.faceRecords != null && response.faceRecords!.isNotEmpty) {
        showTemporaryMessage('User registered successfully as $userName!');
      }
    } catch (e) {
      print('Error in indexFaces: $e');
      showTemporaryMessage('Failed to register user.');
    } finally {
      setLoading(false);
    }
  }

  // Show a temporary message for 2 seconds
  void showTemporaryMessage(String message) {
    setState(() {
      displayMessage = message;
    });
    Timer(Duration(seconds: 8), () {
      setState(() {
        displayMessage = null;
        _imagePath = null;
        attendanceRecords = [];
      });
    });
  }

  // Search for User's Face and Log Attendance
  Future<void> searchFaces(String imagePath) async {
    setLoading(true);
    try {
      final imageBytes = await File(imagePath).readAsBytes();

      final response = await rekognitionClient.searchFacesByImage(
        collectionId: configs.collectionId,
        image: rekognition.Image(bytes: Uint8List.fromList(imageBytes)),
        faceMatchThreshold: 90,
        maxFaces: 1,
      );

      if (response.faceMatches != null && response.faceMatches!.isNotEmpty) {
        final recognizedFace = response.faceMatches!.first.face;
        final rekognitionId = recognizedFace?.faceId;
        final userName = recognizedFace?.externalImageId;
        if (rekognitionId != null && userName != null) {
          // Log attendance only if both rekognitionId and externalImageId are available
          await logAttendance(rekognitionId, userName);
          showTemporaryMessage('User found: $userName, attendance marked.');
          await getAttendanceRecords(rekognitionId); // Fetch attendance history
        }
      } else {
        showTemporaryMessage('No matching faces found.');
      }
    } catch (e) {
      print('Error in searchFaces: $e');
      showTemporaryMessage('Error during search.');
    } finally {
      setLoading(false);
    }
  }

  // Log Attendance to DynamoDB
  Future<void> logAttendance(
      String rekognitionId, String externalImageId) async {
    final now = DateTime.now();
    final timestamp =
        now.toIso8601String(); // Unique timestamp for each log entry

    final attendanceRecord = {
      'RekognitionId': AttributeValue(s: rekognitionId), // Partition key
      'Timestamp':
          AttributeValue(s: timestamp), // Unique timestamp for each log
      'UserName': AttributeValue(s: externalImageId), // Name or unique ID
      'Status': AttributeValue(s: 'Present'), // Status attribute, if needed
    };

    try {
      await dynamoDb.putItem(
        tableName: configs.tableName,
        item: attendanceRecord,
      );
      print('Attendance logged for user $rekognitionId at $timestamp');
    } catch (e) {
      print('Failed to log attendance: $e');
    }
  }

  // Fetch Attendance Records from DynamoDB
  Future<void> getAttendanceRecords(String rekognitionId) async {
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
                'ExternalImageId': item['ExternalImageId']?.s ?? 'Unknown',
                'Status': item['Status']?.s ?? 'Unknown',
              };
            }).toList() ??
            [];
      });
      // Timer(Duration(seconds: 8), () {
      //   setState(() {
      //     attendanceRecords = [];
      //   });
      // });
    } catch (e) {
      print('Failed to fetch attendance records: $e');
    }
  }

  // UI for the Attendance App
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance App with AWS'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_imagePath != null) ...[
              SizedBox(
                width: 150, // Adjust width as desired
                height: 150, // Adjust height as desired
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit
                      .cover, // Optionally, use BoxFit to control how the image fits within the box
                ),
              ),
              SizedBox(height: 20),
            ],
            if (isLoading)
              CircularProgressIndicator()
            else if (displayMessage != null) ...[
              Text(
                displayMessage!,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: () => pickImage('register'),
              child: Text('Register User'),
            ),
            ElevatedButton(
              onPressed: () => pickImage('search'),
              child: Text('Search & Log Attendance'),
            ),
            SizedBox(height: 20),
            Text(
              'Attendance Records:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: attendanceRecords.isNotEmpty
                  ? ListView.builder(
                      itemCount: attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final record = attendanceRecords[index];
                        return Card(
                          margin:
                              EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          child: ListTile(
                            leading:
                                Icon(Icons.date_range, color: Colors.indigo),
                            title: Text('Date: ${record['Timestamp']}'),
                            subtitle: Text('Status: ${record['Status']}'),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No attendance records found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
