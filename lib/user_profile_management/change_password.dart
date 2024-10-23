import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../authentication_process/login.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user's email
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'guest@example.com';

    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
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
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Add an image at the top of the screen
            Image.asset(
              'images/user_profile/forgot_password.png',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),

            // Display some instructional text
            const Text(
              "Reset Your Password",
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "A password reset link will be sent to your email address. Click the link in the email to reset your password.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),

            // Display current email
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.7),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, color: Color.fromARGB(255, 90, 113, 243)),
                  const SizedBox(width: 10),
                  Text(
                    userEmail,
                    style: const TextStyle(fontSize: 18.0, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Reset Password Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 113, 243), // Blue background
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Reset Password",
                style: TextStyle(color: Colors.white, fontSize: 16.0), // White text
              ),
              onPressed: () {
                // Show a modernized confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: const Text(
                      "Confirm Password Reset",
                      style: TextStyle(fontWeight: FontWeight.bold,color: Color.fromARGB(255, 90, 113, 243)),
                    ),
                    content: const Text(
                      "Are you sure you want to reset your password? You will receive a password reset link at your registered email address.",
                      style: TextStyle(fontSize: 14.0),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Dismiss the dialog
                        },
                        child: const Text("No"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 90, 113, 243), // Blue background
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            // Send password reset email
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Check your email to reset your password."),
                              ),
                            );

                            // Log out the user and navigate to login screen
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                              (Route<dynamic> route) => false,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: ${e.toString()}"),
                              ),
                            );
                          }
                        },
                        child: const Text("Reset", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
