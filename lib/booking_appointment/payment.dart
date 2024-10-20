import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final String specialistName;
  final String specialistId; // Add specialistId for Firestore retrieval

  const PaymentScreen({
    super.key,
    required this.selectedDate,
    this.selectedTimeSlot,
    required this.specialistName,
    required this.specialistId, // Pass specialistId
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

  @override
  void initState() {
    super.initState();
    _fetchUserPaymentMethods();
    _fetchSpecialistServices(); // Fetch services from Firestore
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

  // Fetch services from Firestore based on specialistId
  Future<void> _fetchSpecialistServices() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('specialist')
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

  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add New Card"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField("Card Number", "1234 5678 9123 4567", Icons.credit_card),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField("Expiry Date", "MM/YY", Icons.date_range)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField("CVV", "***", Icons.lock)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                // Save card logic goes here
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Payment",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummarySection(),
            const SizedBox(height: 20),
            _buildServiceSelector(), // Dynamic service selector from Firestore
            const SizedBox(height: 20),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 20),
            if (selectedPaymentMethod == 'Credit/Debit Card') _buildAddCardButton(),
            const Spacer(),
            _buildTotalDueSection(),
            _buildPayNowButton(),
          ],
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
                value: selectedService,
                items: availableServices.map<DropdownMenuItem<String>>((service) {
                  return DropdownMenuItem<String>(
                    value: service['name'],
                    child: Text('${service['name']} (RM ${service['fee']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedService = value;
                    selectedServiceFee = availableServices
                        .firstWhere((service) => service['name'] == value)['fee'];
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value ?? 'Credit/Debit Card';
                    if (value == 'Credit/Debit Card') {
                      _showAddCardDialog();
                    }
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              )
            : const Text(
                "No saved payment methods. Please add a new debit card.",
                style: TextStyle(color: Colors.red),
              ),
      ],
    );
  }

  Widget _buildAddCardButton() {
    return ElevatedButton(
      onPressed: () => _showAddCardDialog(),
      child: const Text("Add New Card"),
    );
  }

  Widget _buildTotalDueSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total Due",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'RM ${selectedServiceFee.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPayNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectedService != null && selectedPaymentMethod != 'Credit/Debit Card'
            ? () async {
                setState(() {
                  isPaymentProcessing = true;
                });

                // Handle payment process
                await Future.delayed(const Duration(seconds: 2)); // Simulate payment processing

                setState(() {
                  isPaymentProcessing = false;
                });

                // Navigate to confirmation screen or show success message
                Navigator.pop(context); // Example navigation after successful payment
              }
            : null,
        child: isPaymentProcessing
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text("Pay Now"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hintText, IconData icon) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
