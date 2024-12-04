import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pbi_time/screens/Register_User_Face_Finger/face_Registration_screen.dart';
import 'package:pbi_time/screens/Register_User_Face_Finger/finger_Registration_screen.dart';

class RegistrationScreen extends StatefulWidget {
  static String routeName = '/registerUser';

  const RegistrationScreen({super.key});
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _key = GlobalKey<FormState>();
  final _employeeCodeController = TextEditingController();

  @override
  void dispose() {
    _employeeCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFE0F7FA),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _key,
          child: Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'User Registration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter employee code';
                        }
                        return null;
                      },
                      controller: _employeeCodeController,
                      decoration: InputDecoration(
                        labelText: 'Employee Code',
                        hintText: 'Enter your Employee Code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.teal.shade50,
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_key.currentState!.validate()) {
                          Navigator.pushNamed(
                              context, FaceRegistrationScreen.routeName,
                              arguments: _employeeCodeController.text);
                          // Handle Register Face action
                          String employeeCode = _employeeCodeController.text;
                          if (kDebugMode) {
                            print("Registering face for: $employeeCode");
                          }
                        }
                      },
                      child: Text('Register Face'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.teal[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_key.currentState!.validate()) {
                          Navigator.pushNamed(
                              context, FingerprintRegistrationScreen.routeName , arguments: _employeeCodeController.text);
                          // Handle Register Finger action
                          String employeeCode = _employeeCodeController.text;
                          if (kDebugMode) {
                            print("Registering finger for: $employeeCode");
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.teal[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Register Finger'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
