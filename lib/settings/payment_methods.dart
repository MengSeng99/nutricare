// PaymentMethodsScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../booking_appointment/add_card_dialog.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AddCardDialog _addCardDialog = AddCardDialog();

  String _getMaskedCardNumber(String cardNumber) {
    // Mask the first 12 digits and show only the last 4 digits
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
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
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add, color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: () => _addCardDialog.showAddCardDialog(context),
          ),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No payment methods added."));
                }

                var cards = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    var card = cards[index];
                    String maskedCardNumber =
                        _getMaskedCardNumber(card['cardNumber']);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(
                              color: Color.fromARGB(255, 90, 113, 243)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          title: Text(
                            maskedCardNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "Expiry: ${card['expiryDate']}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              bool? confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    title: const Text(
                                      'Confirm Delete',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Color.fromARGB(255, 90, 113, 243),
                                      ),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to delete this payment method?',
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 90, 113, 243),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(false); // User cancels
                                        },
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                        ),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(true); // User confirms
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmDelete == true) {
                                // If the user confirms, delete the payment method
                                await _firestore
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('payment_methods')
                                    .doc(card.id)
                                    .delete();

                                // Show a snackbar after deletion
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Payment method deleted successfully.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                          onTap: () {
                            // Show dialog with card details
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  title: const Text(
                                    "Card Details",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Color.fromARGB(255, 90, 113, 243)),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Card Number: $maskedCardNumber",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        "Expiry Date: ${card['expiryDate']}",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      // Text("CVV: ${card['cvv']}"),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255,
                                            90,
                                            113,
                                            243), // Blue background
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        "Close",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : const Center(
              child: Text("Please log in to view your payment methods.")),
    );
  }
}
