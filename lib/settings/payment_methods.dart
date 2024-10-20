import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController cardNumberController;
  late TextEditingController cardHolderController;
  late TextEditingController expiryDateController;
  late TextEditingController cvvController;

  @override
  void initState() {
    super.initState();
    cardNumberController = TextEditingController();
    cardHolderController = TextEditingController();
    expiryDateController = TextEditingController();
    cvvController = TextEditingController();
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    cardHolderController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    super.dispose();
  }

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

  Future<void> _addCard() async {
    final user = _auth.currentUser;

    if (user != null) {
      String userId = user.uid;

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

      Navigator.of(context).pop(); // Close the dialog after saving
      _clearTextFields(); // Clear the text fields after adding
    }
  }

  void _clearTextFields() {
    cardNumberController.clear();
    cardHolderController.clear();
    expiryDateController.clear();
    cvvController.clear();
  }

  Future<void> _showAddCardDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text("Add Payment Method",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
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
                          offset: formatCardNumber(value).length),
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
                          offset: formatExpiryDate(value).length),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearTextFields(); // Clear text fields on cancel
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: _addCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 90, 113, 243),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                "Add",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Payment Methods",
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
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add, color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: _showAddCardDialog,
          )
        ],
      ),
      body: user != null
          ? StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('payment_methods')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cards = snapshot.data!.docs;

                if (cards.isEmpty) {
                  return const Center(child: Text("No payment methods added."));
                }

                return ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];

                      return Padding(
                        padding: const EdgeInsets.all(
                            16.0), // Add padding around the Card
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.credit_card,
                                color: Color.fromARGB(255, 90, 113, 243)),
                            title: Text(
                                "**** **** **** ${card['cardNumber'].substring(card['cardNumber'].length - 4)}"),
                            subtitle: Text("Expiry Date: ${card['expiryDate']}",
                                style: const TextStyle(color: Colors.grey)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _firestore
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('payment_methods')
                                        .doc(card.id)
                                        .delete();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
              },
            )
          : const Center(
              child: Text("Please log in to view your payment methods.")),
    );
  }
}
