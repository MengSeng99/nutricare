import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'authentication.dart'; // Import the authentication service

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();
  final _formKey = GlobalKey<FormState>(); // Create a GlobalKey for the Form widget
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey, // Attach the form key to the Form widget
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'images/recovery.png',
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.width * 0.5,
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.all(2),
                    child: Column(
                      children: [
                        Text(
                          'Join NutriCare Today!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 90, 113, 243),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Name TextFormField
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    // Validator for name field
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name.';
                      }
                      return null; // No error
                    },
                  ),
                  const SizedBox(height: 20),
                  // Email TextFormField
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    // Validator for email field
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email.';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address.';
                      }
                      return null; // No error
                    },
                  ),
                  const SizedBox(height: 20),
                  // Password TextFormField
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    // Validator for password field
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password.';
                      } else if (value.length < 6) {
                        return 'Password must be at least 6 characters long.';
                      }
                      return null; // No error
                    },
                  ),
                  const SizedBox(height: 20),
                  // Confirm Password TextFormField
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_confirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    // Validator for confirm password field
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password.';
                      } else if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null; // No error
                    },
                  ),
                  const SizedBox(height: 20),
                  // Modern Signup Button
                  GestureDetector(
                    onTap: () async {
                      // Validate the form before attempting signup
                      if (_formKey.currentState!.validate()) {
                        try {
                          User? user = await _authService.createUserWithEmail(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                            _nameController.text.trim(),
                          );

                          if (user != null) {
                            // Save user details to Firestore
                            await _authService.saveUserDetails(
                              _nameController.text.trim(),
                              _emailController.text.trim(),
                            );

                            // If signup is successful, navigate to the Login page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Signup successful! Please log in.')),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          }
                        } catch (e) {
                          // Catching any exceptions from Firestore save operation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())), // Display the error
                          );
                        }
                      }
                    },
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHovered = true),
                      onExit: (_) => setState(() => _isHovered = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _isHovered ? Colors.blueAccent : const Color.fromARGB(255, 90, 113, 243),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text('Already have an account? Log In'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Image.asset(
              'images/Logo-rounded.png',
              width: MediaQuery.of(context).size.width * 0.2,
              height: MediaQuery.of(context).size.width * 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
