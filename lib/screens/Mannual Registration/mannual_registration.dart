// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// class ManualAttendanceScreen extends StatefulWidget {
//   static String routeName = '/mannualAttendance';
//
//   const ManualAttendanceScreen({super.key});
//
//   @override
//   State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
// }
//
// class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
//   final TextEditingController _nameController = TextEditingController();
//
//   final TextEditingController _employeeCodeController = TextEditingController();
//   String? _imagePath;
//   String? base64Image;
//   final _key = GlobalKey<FormState>();
//   bool isLoading = false;
//
//   Future<void> _markAttendance() async {
//     setState(() {
//       _nameController.text = '';
//       _employeeCodeController.text = '';
//       _imagePath = null;
//       isLoading = false;
//     });
//   }
//
//   Future<void> pickImage() async {
//     final picker = ImagePicker();
//     final image =
//         await picker.pickImage(source: ImageSource.camera, imageQuality: 100);
//
//     if (image == null) return;
//
//     final bytes = await File(image.path).readAsBytes();
//     base64Image = base64Encode(bytes);
//
//     // Maintain array of up to three Base64 images
//     // if (base64Images.length == 3) {
//     //   base64Images.removeAt(0); // Remove the oldest image
//     // }
//     // base64Images.add(base64Image);
//
//     setState(() {
//       _imagePath = image.path;
//     });
//   }
//
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _employeeCodeController.dispose();
//     super.dispose();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manual Attendance'),
//         centerTitle: true,
//         backgroundColor: Colors.teal,
//       ),
//       body: SingleChildScrollView(
//         child: Form(
//           key: _key,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const Text(
//                   'Enter Your Details',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.teal,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 // SizedBox(height: 20),
//                 Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: _imagePath == null
//                         ? Container(
//                             height: 200,
//                             decoration: BoxDecoration(
//                               color: Colors.grey[200],
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 'Please Capture Your Image',
//                                 style: TextStyle(color: Colors.grey.shade600),
//                               ),
//                             ),
//                           )
//                         : Container(
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(12),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.grey.withOpacity(0.5),
//                                   blurRadius: 8,
//                                   offset: Offset(0, 4),
//                                 ),
//                               ],
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: Image.file(
//                                 File(_imagePath!),
//                                 // width: 180,
//                                 height: 300,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           )),
//                 const SizedBox(
//                   height: 20,
//                 ),
//                 TextFormField(
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Full Name is required';
//                     }
//                   },
//                   controller: _nameController,
//                   decoration: InputDecoration(
//                     labelText: 'Full Name',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     prefixIcon: Icon(Icons.person, color: Colors.teal),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 TextFormField(
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Employee Code is required';
//                     }
//                     return null;
//                   },
//                   controller: _employeeCodeController,
//                   decoration: InputDecoration(
//                     labelText: 'Employee Code',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     prefixIcon: Icon(Icons.badge, color: Colors.teal),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () async {
//                     // Handle attendance submission
//
//                     if (_key.currentState!.validate()) {
//                       setState(() {
//                         isLoading = true;
//                       });
//                       // Process data
//                       await pickImage();
//                       await _markAttendance();
//                       return;
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator.adaptive(
//                           backgroundColor: Colors.white,
//                         )
//                       : const Text(
//                           'Submit Attendance',
//                           style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white),
//                         ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/fingerPrint_apiService.dart';
import '../../services/mark_attendance_service.dart';
import '../../utils/attendanceTypes.dart';
import '../../utils/sharedPreferencesHelper.dart';
import '../../utils/snackBar.dart';

class ManualAttendanceScreen extends StatefulWidget {
  static String routeName = '/manualAttendance';

  const ManualAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _employeeCodeController = TextEditingController();
  final _key = GlobalKey<FormState>();
  String? _imagePath;
  String? base64Image;
  bool isLoading = false;
  DateTime timeStamp = DateTime.now();
  final MarkAttendanceService _markAttendanceService = MarkAttendanceService();
  final FingerFaceApiService _apiService = FingerFaceApiService();

  String? validationMessage;
  String? selectedOption;

  // String? _selectedValue = attendanceTypes.first.keys.first;

  @override
  void dispose() {
    _nameController.dispose();
    _employeeCodeController.dispose();
    super.dispose();
  }

  Future<int?> _validateEmployee(String empCode) async {
    try {
      final response = await _apiService.getEmployeeId(context, empCode);
      if (response != null) {
        await SharedPrefsHelper.setEmployeeId(response);
        return response;
      }
      _showSnackBar('Could not Validate Employee ID', type: SnackBarType.error);
      return null;
    } catch (e) {
      _showSnackBar('Error: $e', type: SnackBarType.error);
      return null;
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image capture canceled')),
        );
        return;
      }

      final bytes = await File(image.path).readAsBytes();
      base64Image = base64Encode(bytes);

      setState(() {
        _imagePath = image.path;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  Future<void> _markAttendance() async {
    final isSelected = _validateSelection();
    if (!isSelected) {
      return;
    }
    if (_key.currentState!.validate()) {
      if (_imagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture an image!')),
        );
        return;
      }
      setState(() => isLoading = true);

      final empId = await _validateEmployee(
          _employeeCodeController.text); //to get the employee ID.
      final response = await _markAttendanceService.markAttendance(
          empId.toString(), 'Manual',
          image: base64Image, attendanceType: selectedOption);
      if (response['isSuccess'] == true) {
        _showSnackBar(response['message'], type: SnackBarType.success);
      } else {
        _showSnackBar(response['message'], type: SnackBarType.error);
      }

      setState(() {
        isLoading = false;
        _nameController.clear();
        _employeeCodeController.clear();
        _imagePath = null;
      });
    }
  }

  void _showSnackBar(String message, {SnackBarType type = SnackBarType.info}) {
    SnackbarHelper.showSnackBar(context, message, type: type);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Attendance'),
        centerTitle: true,
        backgroundColor: const Color(0xFF17a2b8),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter Your Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17a2b8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _imagePath == null
                      ? Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Color(0xFF17a2b8), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              'Please Capture Your Image',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_imagePath!),
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                // TextFormField(
                //   controller: _nameController,
                //   decoration: InputDecoration(
                //     labelText: 'Full Name',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //     prefixIcon:
                //         const Icon(Icons.person, color: Color(0xFF17a2b8)),
                //   ),
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Full Name is required';
                //     }
                //     return null;
                //   },
                // ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _employeeCodeController,
                  decoration: InputDecoration(
                    labelText: 'Employee Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon:
                        const Icon(Icons.badge, color: Color(0xFF17a2b8)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Employee Code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildActionTypes(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Capture Image',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF17a2b8),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : _markAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF17a2b8),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          backgroundColor: Colors.white,
                        )
                      : const Text(
                          'Submit Attendance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
}
