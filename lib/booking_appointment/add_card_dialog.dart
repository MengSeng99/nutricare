// add_card_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AddCardDialog {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String formatCardNumber(String input) {
    input = input.replaceAll(RegExp(r'\s+'), ''); // Remove any existing spaces
    if (input.length > 16) input = input.substring(0, 16); // Limit to 16 digits
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      if (i % 4 == 0 && i != 0) {
        buffer.write(' '); // Add space after every 4 digits
      }
      buffer.write(input[i]);
    }
    return buffer.toString();
  }

  String formatExpiryDate(String input) {
    input = input.replaceAll(RegExp(r'/'), ''); // Remove existing slash
    if (input.length > 4) input = input.substring(0, 4); // Limit to 4 digits
    if (input.length >= 2) {
      return '${input.substring(0, 2)}/${input.substring(2)}';
    }
    return input;
  }

  bool _isValidCardNumber(String cardNumber) {
    // Remove spaces and check length
    String unformattedNumber = cardNumber.replaceAll(' ', '');
    return unformattedNumber.length == 16;
  }

  Future<bool> _addCard(BuildContext context) async {
    final user = _auth.currentUser;

    if (user != null) {
      String userId = user.uid;

      // Validate card number before adding
      if (!_isValidCardNumber(cardNumberController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Card number must be 16 digits long (with spaces as required).'),
                                backgroundColor: Colors.red),
        );
        return false; // Exit early if the card number is invalid.
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .add({
        'cardNumber': cardNumberController.text,
        'cardHolder': cardHolderController.text,
        'expiryDate': expiryDateController.text,
        'cvv': cvvController.text,
      });

      // If we reach here, it means card number was valid, and card has been added.
      return true; // Indicate that the card was added successfully.
    }
    return false; // Indicate failure due to user not being logged in
  }

  void _clearTextFields() {
    cardNumberController.clear();
    cardHolderController.clear();
    expiryDateController.clear();
    cvvController.clear();
  }

  Future<void> showAddCardDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          child: Container(
            width: MediaQuery.of(context).size.width *
                0.85, // Width takes 85% of the screen
            padding: const EdgeInsets.all(16.0), // Add some padding
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Allow dialog to size itself to fit content
              children: [
                const Text(
                  "Add Payment Method",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243),
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),

                // Card Number Field
                TextFormField(
                  controller: cardNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, // Only allow numbers
                    LengthLimitingTextInputFormatter(
                        19), // 16 digits + 3 spaces
                  ],
                  onChanged: (value) {
                    cardNumberController.value = TextEditingValue(
                      text: formatCardNumber(value),
                      selection: TextSelection.collapsed(
                        offset: formatCardNumber(value).length,
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: "Card Number",
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 90, 113, 243)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Card Holder Name Field
                TextFormField(
                  controller: cardHolderController,
                  decoration: InputDecoration(
                    hintText: "Card Holder Name",
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 90, 113, 243)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Expiry Date Field
                TextFormField(
                  controller: expiryDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5), // 4 digits + 1 slash
                  ],
                  onChanged: (value) {
                    expiryDateController.value = TextEditingValue(
                      text: formatExpiryDate(value),
                      selection: TextSelection.collapsed(
                        offset: formatExpiryDate(value).length,
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: "Expiry Date (MM/YY)",
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 90, 113, 243)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // CVV Field
                TextFormField(
                  controller: cvvController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                        3), // Limit CVV to 3 digits
                  ],
                  decoration: InputDecoration(
                    hintText: "CVV",
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 90, 113, 243)),
                    ),
                  ),
                  obscureText: true, // Hide CVV for security
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearTextFields(); // Clear text fields on cancel
                      },
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (cardNumberController.text.isEmpty ||
                            cardHolderController.text.isEmpty ||
                            expiryDateController.text.isEmpty ||
                            cvvController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please fill in all fields')),
                          );
                        } else {
                          bool cardAdded = await _addCard(context);
                          if (cardAdded) {
                            // Show a snackbar only if the card was added successfully
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Payment method added successfully.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 90, 113, 243),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        "Add",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
