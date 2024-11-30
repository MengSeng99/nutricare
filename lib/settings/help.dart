import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Import for clipboard functionality
import 'package:url_launcher/url_launcher.dart';
import 'client_info.dart';
import 'payment_methods.dart';
import 'feedback.dart'; // Import the FeedbackScreen

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Help and FAQs',
          style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 247, 247, 254),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243)),
              ),
              const SizedBox(height: 15),
              _buildFaqItem(
                'How can I update my personal details?',
                'Navigate to Personal Details in the Settings menu.',
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ClientInfoScreen(),
                    ),
                  );
                },
                // Make it blue and underlined
                TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 90, 113, 243),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 10),
              _buildFaqItem(
                'How do I add a new payment method?',
                'Go to Payment Methods in the Settings menu.',
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsScreen(),
                    ),
                  );
                },
                // Make it blue and underlined
                TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 90, 113, 243),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Contact Us',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243)),
              ),
              const SizedBox(height: 10),
              const Text(
                'For further assistance, please reach out to our support team:',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              _buildContactInfo(
                'Email',
                'support@nutricareapp.com',
                () => _copyToClipboard(context, 'support@nutricareapp.com'),
              ),
              const SizedBox(height: 5),
              _buildContactInfo(
                'Phone',
                '+60 7236 4463',
                () => _launchURL('tel:+6072364463'),
              ),
              const SizedBox(height: 30),
              const Text(
                'Feedback',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243)),
              ),
              const SizedBox(height: 5),
              _buildContactInfo(
                'Feedback',
                'Click here to provide feedback!',
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                },
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 90, 113, 243), // Hyperlink color
                  decoration: TextDecoration.underline, // Underline to indicate hyperlink
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build each FAQ item with a modern card layout
  Widget _buildFaqItem(String question, String answer, VoidCallback onTap, TextStyle textStyle) {
    return GestureDetector(
      onTap: onTap, // Navigate when tapped
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: textStyle,
              ),
              const SizedBox(height: 5),
              Text(
                answer,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build contact info with an icon
  Widget _buildContactInfo(String title, String info, VoidCallback onTap, {TextStyle? textStyle}) {
    return GestureDetector(
      onTap: onTap, // Launch URL or call when tapped
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                title == 'Email' ? Icons.email : title == 'Phone' ? Icons.phone : Icons.feedback,
                color: const Color.fromARGB(255, 90, 113, 243),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  info,
                  style: textStyle ?? const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to copy email to clipboard and show dialog
  void _copyToClipboard(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    _showCopiedDialog(context);
  }

  // Show a dialog indicating that the email is copied
  void _showCopiedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: const Text(
                      "Email Copied",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 90, 113, 243)),
                    ),
          content: const Text('The email address has been copied to clipboard.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Launch URL function for phone calls
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}