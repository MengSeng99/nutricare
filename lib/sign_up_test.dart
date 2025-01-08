import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Signup Page Tests', () {
    test('Validate name field with empty input', () {
      final nameController = TextEditingController();
      nameController.text = '';
      expect(nameController.text.isEmpty, true, reason: 'Name field should not be empty.');
    });

    test('Validate email field with invalid input', () {
      final emailController = TextEditingController();
      emailController.text = 'invalidemail.com';
      final isValidEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text);
      expect(isValidEmail, false, reason: 'Email should be in a valid format.');
    });

    test('Validate password field with less than 6 characters', () {
      final passwordController = TextEditingController();
      passwordController.text = '123';
      expect(passwordController.text.length >= 6, false, reason: 'Password must be at least 6 characters long.');
    });

    test('Passwords match validation', () {
      final passwordController = TextEditingController();
      final confirmPasswordController = TextEditingController();
      passwordController.text = 'password123';
      confirmPasswordController.text = 'password123';
      expect(passwordController.text == confirmPasswordController.text, true, reason: 'Passwords must match.');
    });
  });
}
