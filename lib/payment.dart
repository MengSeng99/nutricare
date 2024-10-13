import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final String? fullName;
  final String? reasonForAppointment;
  final String specialistName;

  const PaymentScreen({
    super.key,
    required this.selectedDate,
    this.selectedTimeSlot,
    this.fullName,
    this.reasonForAppointment, 
    required this.specialistName,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = "Credit/Debit Card";
  bool isPaymentProcessing = false;

  final List<String> paymentMethods = [
    'Credit/Debit Card',
    'PayPal',
    'Apple Pay',
    'Google Pay',
    'Bank Transfer',
  ];

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
            _buildPaymentMethodSelector(),
            const SizedBox(height: 20),
            if (selectedPaymentMethod == 'Credit/Debit Card') _buildCardPaymentFields(),
            const SizedBox(height: 30),
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
          _buildSummaryRow('Name', widget.fullName ?? 'N/A'),
          _buildSummaryRow('Date', '${widget.selectedDate.toLocal()}'.split(' ')[0]),
          _buildSummaryRow('Time', widget.selectedTimeSlot ?? 'N/A'),
          _buildSummaryRow('Reason', widget.reasonForAppointment ?? 'N/A'),

          const SizedBox(height: 10),
          _buildSummaryRow('Consultation Fee', 'RM 50.00', bold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool bold = false}) {
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
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
        DropdownButtonFormField<String>(
          value: selectedPaymentMethod,
          items: paymentMethods.map((method) {
            return DropdownMenuItem(
              value: method,
              child: Text(method),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedPaymentMethod = value ?? "Credit/Debit Card";
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

  Widget _buildCardPaymentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildPayNowButton() {
    return Center(
      child: ElevatedButton(
        onPressed: isPaymentProcessing
            ? null
            : () {
                setState(() {
                  isPaymentProcessing = true;
                });

                // Simulate payment process
                Future.delayed(const Duration(seconds: 3), () {
                  setState(() {
                    isPaymentProcessing = false;
                  });
                  _showPaymentSuccessDialog();
                });
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 90, 113, 243),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isPaymentProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Pay Now",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Payment Successful"),
          content: const Text("Your payment has been processed successfully."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Navigate back to previous screen
              },
            ),
          ],
        );
      },
    );
  }
}
