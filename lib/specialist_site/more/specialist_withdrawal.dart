import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WithdrawalScreen extends StatefulWidget {
  final double totalEarnings;
  final String specialistId;
  final Function(double) onWithdrawalSuccess;

  const WithdrawalScreen({
    super.key,
    required this.totalEarnings,
    required this.specialistId,
    required this.onWithdrawalSuccess,
  });

  @override
  _WithdrawalScreenState createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedBank;
  String? _beneficiaryNumber;
  String? _beneficiaryName;
  final List<Map<String, String>> _banks = [
    {
      'name': 'CIMB Bank',
      'logo': 'https://cdn2.downdetector.com/static/uploads/logo/CIMB-Logo.png',
    },
    {
      'name': 'Public Bank',
      'logo':
          'https://images.seeklogo.com/logo-png/11/1/public-bank-logo-png_seeklogo-113575.png?v=638687197180000000',
    },
    {
      'name': 'Maybank',
      'logo':
          'https://logos-world.net/wp-content/uploads/2023/02/Maybank-Logo.png',
    },
    {
      'name': 'Hong Leong Bank',
      'logo':
          'https://s.hongleongconnect.my/rib/js/chatbot/assets/images/hlb-brand.png',
    },
    {
      'name': 'Bank Islam',
      'logo':
          'https://seeklogo.com/images/B/Bank_Islam-logo-A212255EF5-seeklogo.com.png',
    },
  ];

  void _confirmWithdrawal(BuildContext context) {
    double amount = double.tryParse(_amountController.text) ?? 0.0;

    if (amount > widget.totalEarnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Withdrawal amount cannot exceed RM ${widget.totalEarnings.toStringAsFixed(2)}.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Confirm Withdrawal",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Amount: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: 'RM $amount',
                        style: TextStyle(
                            color: Color.fromARGB(255, 90, 113, 243),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Bank: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '$_selectedBank',
                        style: TextStyle(
                            color: Color.fromARGB(255, 90, 113, 243),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Beneficiary Number: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '$_beneficiaryNumber',
                        style: TextStyle(
                            color: Color.fromARGB(255, 90, 113, 243),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Beneficiary Name: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '$_beneficiaryName',
                        style: TextStyle(
                            color: Color.fromARGB(255, 90, 113, 243),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please double-check before proceeding.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
           actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cancel
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 90, 113, 243),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            onPressed: () async {
              try {
                // Save withdrawal to Firestore
                CollectionReference withdrawals = FirebaseFirestore.instance.collection('specialists')
                    .doc(widget.specialistId)
                    .collection('withdrawal');

                await withdrawals.add({
                  'amount': amount,
                  'bank': _selectedBank,
                  'account_number': _beneficiaryNumber,
                  'beneficiary_name': _beneficiaryName,
                  'withdraw_date': FieldValue.serverTimestamp(),
                });

                double remainingEarnings = widget.totalEarnings - amount;
                widget.onWithdrawalSuccess(remainingEarnings);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Withdrawn RM $amount. Remaining earnings: RM ${remainingEarnings.toStringAsFixed(2)}')),
                );
                Navigator.of(context).pop(); // Navigate back
              } catch (e) {
                // Handle any errors, e.g., show an error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save withdrawal: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

  bool get _isFormValid {
    return _amountController.text.isNotEmpty &&
        _selectedBank != null &&
        _beneficiaryNumber != null &&
        _beneficiaryName != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Withdraw Earnings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        iconTheme: IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings: RM ${widget.totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 90, 113, 243)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount to Withdraw',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.monetization_on),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Bank',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: _selectedBank,
                      items: _banks.map((Map<String, String> bank) {
                        return DropdownMenuItem<String>(
                          value: bank['name'],
                          child: Row(
                            children: [
                              Image.network(
                                bank['logo']!,
                                width: 80,
                                height: 24,
                                fit: BoxFit.fitWidth,
                              ),
                              const SizedBox(width: 12),
                              Text(bank['name']!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBank = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _beneficiaryNumber = value.isNotEmpty
                              ? value
                              : null; // Set to null if empty
                        });
                      },
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Beneficiary Account Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.account_circle),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _beneficiaryName = value.isNotEmpty
                              ? value
                              : null; // Set to null if empty
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Beneficiary Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  _isFormValid ? () => _confirmWithdrawal(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 90, 113, 243),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Withdraw',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
