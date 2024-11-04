import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import the PaymentMethodsScreen for navigation
import 'payment_success.dart';


class PaymentScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final String specialistName;
  final String specialistId;
  final String appointmentMode; 

  const PaymentScreen({
    super.key,
    required this.selectedDate,
    this.selectedTimeSlot,
    required this.specialistName,
    required this.specialistId,
    required this.appointmentMode,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = "Credit/Debit Card";
  bool isPaymentProcessing = false;
  bool hasSavedPaymentMethods = false;
  List<String> userPaymentMethods = [];
  List<Map<String, dynamic>> availableServices = [];
  String? selectedService;
  double selectedServiceFee = 0.0;
  String promoCode = "";
  bool isPromoApplied = false;
  final TextEditingController promoCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserPaymentMethods();
    _fetchSpecialistServices();
  }

  Future<void> _fetchUserPaymentMethods() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userId = currentUser.uid;

      final paymentMethodsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payment_methods');

      final snapshot = await paymentMethodsCollection.get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          userPaymentMethods = snapshot.docs.map((doc) {
            final data = doc.data();
            return "**** **** **** ${data['cardNumber'].substring(data['cardNumber'].length - 4)}";
          }).toList();
          hasSavedPaymentMethods = true;
        });
      }
    }
  }

  Future<void> _fetchSpecialistServices() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(widget.specialistId)
          .get();

      final services = doc.data()?['services'] ?? [];

      if (services.isNotEmpty) {
        setState(() {
          availableServices = List<Map<String, dynamic>>.from(services);
        });
      }
    } catch (e) {
      print('Error fetching services: $e');
    }
  }

   Widget _buildPromoCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Promo Code",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: promoCodeController,
                decoration: InputDecoration(
                  hintText: "Enter Promo Code",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (promoCodeController.text.trim().toUpperCase() == "NEWUSER") {
                    isPromoApplied = true;
                    selectedServiceFee = 0.0; // Make it free
                  } else {
                    isPromoApplied = false;
                    // Reset to the actual service fee if the promo code is wrong
                    selectedServiceFee = availableServices
                        .firstWhere((service) =>
                            service['name'] == selectedService)['fee']
                        .toDouble();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Apply", style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),),
            ),
          ],
        ),
        if (isPromoApplied)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Promo code applied!",
              style: TextStyle(color: Colors.green),
            ),
          ),
        if (!isPromoApplied && promoCodeController.text.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Invalid promo code",
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Payment",
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummarySection(),
                const SizedBox(height: 20),
                _buildServiceSelector(),
                const SizedBox(height: 20),
                _buildPaymentMethodSelector(),
                if (!hasSavedPaymentMethods) _buildAddCardButton(),
                const SizedBox(height: 20),
                _buildPromoCodeSection(),
                const SizedBox(height: 20),
                _buildTotalDueSection(),
                _buildPayNowButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }


    Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Appointment Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow('Specialist', "Dr. ${widget.specialistName}"),
          _buildSummaryRow('Date', '${widget.selectedDate.toLocal()}'.split(' ')[0]),
          _buildSummaryRow('Time', widget.selectedTimeSlot ?? 'N/A'),
          _buildSummaryRow('Appointment Mode', widget.appointmentMode), // New row for appointment mode
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Service",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        availableServices.isEmpty
            ? const Text("No services available for this specialist.")
            : DropdownButtonFormField<String>(
                hint: const Text("Select a service"),
                value: selectedService,
                items: availableServices.map<DropdownMenuItem<String>>((service) {
                  return DropdownMenuItem<String>(
                    value: service['name'],
                    child: Text(
                        '${service['name']} (RM ${service['fee'].toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedService = value;
                    selectedServiceFee = availableServices
                        .firstWhere((service) => service['name'] == value)['fee']
                        .toDouble();
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
      ],
    );
  }

 Widget _buildPaymentMethodSelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Payment Method",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      hasSavedPaymentMethods
          ? DropdownButtonFormField<String>(
              value: selectedPaymentMethod,
              items: [
                ...userPaymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }),
                const DropdownMenuItem(
                  value: 'Credit/Debit Card',
                  child: Text('Add New Debit/Credit Card'),
                ),
              ],
              onChanged: (value) async {
                if (value == 'Credit/Debit Card') {
                  // Show the add card form in a dialog directly here
                  await _showAddCardDialog();
                } else {
                  setState(() {
                    selectedPaymentMethod = value ?? 'Credit/Debit Card';
                  });
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            )
          : const Text(
              "No saved payment methods.",
              style: TextStyle(color: Colors.red),
            ),
    ],
  );
}

// Function to show the add card form
Future<void> _showAddCardDialog() async {
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String formatCardNumber(String input) {
    input = input.replaceAll(RegExp(r'\s+'), '');
    if (input.length > 16) input = input.substring(0, 16);
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      if (i % 4 == 0 && i != 0) {
        buffer.write(' ');
      }
      buffer.write(input[i]);
    }
    return buffer.toString();
  }

  String formatExpiryDate(String input) {
    input = input.replaceAll(RegExp(r'/'), '');
    if (input.length > 4) input = input.substring(0, 4);
    if (input.length >= 2) {
      return '${input.substring(0, 2)}/${input.substring(2)}';
    }
    return input;
  }

  Future<void> addCard() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .add({
        'cardNumber': cardNumberController.text,
        'cardHolder': cardHolderController.text,
        'expiryDate': expiryDateController.text,
        'cvv': cvvController.text,
      });

      // After adding, refresh the payment methods
      await _fetchUserPaymentMethods();
      Navigator.of(context).pop(true);
    }
  }

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Text("Add Payment Method", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                ],
                onChanged: (value) {
                  cardNumberController.value = TextEditingValue(
                    text: formatCardNumber(value),
                    selection: TextSelection.collapsed(offset: formatCardNumber(value).length),
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
                    borderSide: const BorderSide(color: Color.fromARGB(255, 90, 113, 243)),
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
                    borderSide: const BorderSide(color: Color.fromARGB(255, 90, 113, 243)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: expiryDateController,
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (value) {
                  expiryDateController.value = TextEditingValue(
                    text: formatExpiryDate(value),
                    selection: TextSelection.collapsed(offset: formatExpiryDate(value).length),
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
                    borderSide: const BorderSide(color: Color.fromARGB(255, 90, 113, 243)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
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
                    borderSide: const BorderSide(color: Color.fromARGB(255, 90, 113, 243)),
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              if (cardNumberController.text.isEmpty ||
                  cardHolderController.text.isEmpty ||
                  expiryDateController.text.isEmpty ||
                  cvvController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
              } else {
                addCard();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 90, 113, 243),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}




Widget _buildAddCardButton() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () async {
        // Show the add card form in a dialog
        await _showAddCardDialog();
        // If needed, refresh payment methods after closing the dialog
        // Uncomment this if you have logic to check saved payment methods
        _fetchUserPaymentMethods();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 90, 113, 243),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text("Add New Card", style: TextStyle(color: Colors.white)),
    ),
  );
}

  Widget _buildTotalDueSection() {
    final bool isFree = isPromoApplied && selectedServiceFee == 0.0;
    final originalFee = availableServices.isNotEmpty && selectedService != null
        ? availableServices
            .firstWhere((service) => service['name'] == selectedService)['fee']
            .toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total Due",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              if (isFree)
                Text(
                  'RM ${originalFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                isFree ? 'FREE' : 'RM ${selectedServiceFee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isFree ? Colors.blue : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectedService != null &&
                selectedPaymentMethod != 'Credit/Debit Card'
            ? () async {
                setState(() {
                  isPaymentProcessing = true;
                });

                await Future.delayed(const Duration(seconds: 2)); // Simulate payment processing

                setState(() {
                  isPaymentProcessing = false;
                });

                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreen(
                    specialistName: widget.specialistName,
                    specialistId: widget.specialistId,
                    selectedDate: widget.selectedDate,
                    selectedTimeSlot: widget.selectedTimeSlot,
                    appointmentMode: widget.appointmentMode,
                    amountPaid: selectedServiceFee,
                    serviceName: selectedService.toString(),
                    paymentCardUsed: selectedPaymentMethod,
                    appointmentStatus: "Confirmed",
                  ),
                ),
              );

              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 90, 113, 243),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isPaymentProcessing
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),),
      ),
    );
  }
}
