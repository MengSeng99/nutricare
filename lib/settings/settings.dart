import 'package:flutter/material.dart';
import 'client_info.dart'; // Import the ClientInfoScreen
import 'help.dart';
import 'language.dart';
import 'payment_methods.dart'; // Import the HelpScreen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingOption(context, Icons.person, 'Personal Details', () {
              // Navigate to ClientInfoScreen
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientInfoScreen()));
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.payment, 'Payment Methods', () {
              // Navigate to PaymentMethodsScreen
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()));
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.language, 'Language', () {
              // Navigate to LanguageScreen
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageScreen()));
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.help, 'Help and FAQs', () {
              // Navigate to HelpScreen
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
            }),
          ],
        ),
      ),
    );
  }

  // Widget to build each setting option
  Widget _buildSettingOption(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[400]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color.fromARGB(255, 90, 113, 243), size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
