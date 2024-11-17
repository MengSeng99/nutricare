// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey =
      GlobalKey<FormState>(); // Create a GlobalKey for the Form widget
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Constraining the size of the Image widget
              SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.6, // Set width relative to screen size
                height: MediaQuery.of(context).size.height *
                    0.3, // Set height relative to screen size
                child: Image.asset(
                  'images/user_profile/forgot_password.png',
                  fit: BoxFit.contain, // Ensures the image scales correctly
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reset your password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey, // Attach the form key to the Form widget
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email.';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null; // No error
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await _auth.sendPasswordResetEmail(
                          email: _emailController.text.trim());
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text(
                              'Email Sent',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 90, 113, 243),
                              ),
                            ),
                            content: const Text(
                                'An email has been sent to your email address. Please check your mailbox to reset your password.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                ),
                child: const Text(
                  'Reset Password',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(
                  height:
                      20), // Add spacing to prevent overflow when keyboard is visible
            ],
          ),
        ),
      ),
    );
  }
}
