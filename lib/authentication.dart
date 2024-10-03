import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<User?> createUserWithEmail(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        await saveUserDetails(name, email); // Save user details to Firestore
      }
      return user;
    } catch (e) {
      rethrow; // Rethrow the exception for handling in UI
    }
  }

  // Save user details to Firestore
  Future<void> saveUserDetails(String name, String email) async {
    User? user = _auth.currentUser; // Get the current user
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
        });
      } catch (e) {
        rethrow; // Rethrow the exception for handling in UI
      }
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    // Validate email format
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      throw FirebaseAuthException(code: 'invalid-email', message: 'Invalid email format');
    }
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      rethrow; // Pass the error up to the caller
    }
  }
}
