import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RateAdjustmentScreen extends StatefulWidget {
  const RateAdjustmentScreen({super.key});

  @override
  _RateAdjustmentScreenState createState() => _RateAdjustmentScreenState();
}

class _RateAdjustmentScreenState extends State<RateAdjustmentScreen> {
  double? distributionRate;
  double? currentRate;
  String? selectedRate;
  bool isCustom = false;
  String? lastUpdate;
  TextEditingController customRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCurrentRate();
  }

  Future<void> fetchCurrentRate() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('rates')
          .doc('current_rate_doc')
          .get();
      if (snapshot.exists) {
        setState(() {
          currentRate = snapshot.data()?['rate'] ?? 0.0;
          lastUpdate = snapshot.data()?['date']?.toDate().toString() ?? 'Never';
        });
      }
    } catch (e) {
      print("Error fetching current rate: $e");
    }
  }

  Future<void> saveRate() async {
    if (distributionRate != null) {
      await FirebaseFirestore.instance
          .collection('rates')
          .doc('current_rate_doc')
          .set({
        'rate': distributionRate,
        'date': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Distribution rate set to ${distributionRate! * 100}%')),
      );

      fetchCurrentRate();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid distribution rate')),
      );
    }
  }

  void showConfirmationDialog() {
    if (currentRate == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return _buildCustomAlertDialog(
          title: 'Confirm Adjustment',
          content:
              'Are you sure you want to adjust the distribution rate from ${currentRate! * 100}% to ${distributionRate! * 100}%?',
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                saveRate();
              },
            ),
          ],
        );
      },
    );
  }

  AlertDialog _buildCustomAlertDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 90, 113, 243),
        ),
      ),
      content: Text(content),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Adjust Distribution Rate',
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
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Current Distribution Rate:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Rate: ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              TextSpan(
                                text: currentRate != null
                                    ? '${(currentRate! * 100).toStringAsFixed(2)}%'
                                    : 'Loading...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: currentRate != null
                                      ? Color.fromARGB(255, 90, 113, 243)
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline,
                              color: Color.fromARGB(255, 90, 113, 243)),
                          tooltip: 'Current distribution rate info.',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return _buildCustomAlertDialog(
                                  title: 'Current Distribution Rate Info',
                                  content:
                                      'Current distribution rate is ${currentRate! * 100}%. Adjusting this rate will directly impact specialists’ earnings.',
                                  actions: [
                                    TextButton(
                                      child: const Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Last Update: $lastUpdate',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rate Selection Section
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
                      'Select New Distribution Rate:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose a predefined rate or enter a custom value.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedRate,
                      hint: const Text('Select New Distribution Rate'),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        '10',
                        '20',
                        '30',
                        '40',
                        '50',
                        '60',
                        '70',
                        '80',
                        '90',
                        '100',
                        'Other',
                      ].map((String rate) {
                        return DropdownMenuItem<String>(
                          value: rate,
                          child: Text('$rate%'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRate = newValue;
                          isCustom = newValue == 'Other';
                          // Reset distributionRate if not custom
                          distributionRate = newValue != 'Other'
                              ? double.tryParse(newValue!)! / 100
                              : null;
                          // Clear the customRateController if choosing a preset
                          if (newValue != 'Other') {
                            customRateController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    if (isCustom)
                      TextField(
                        controller: customRateController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Custom Rate',
                          hintText: 'Rate as a percentage (e.g., 10 for 10%)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        // Update distributionRate when text changes
                        onChanged: (value) {
                          final doubleValue = double.tryParse(value);
                          if (doubleValue != null && doubleValue > 0) {
                            setState(() {
                              distributionRate =
                                  doubleValue / 100; // Keep in percentage
                            });
                          } else {
                            setState(() {
                              distributionRate = null; // Reset if invalid input
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Save Button
            Center(
              child: GestureDetector(
                onTap: (distributionRate == null || distributionRate! <= 0)
                    ? null
                    : showConfirmationDialog,
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        (distributionRate == null || distributionRate! <= 0)
                            ? null // No gradient when disabled
                            : const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 90, 113, 243),
                                  Color.fromARGB(255, 120, 143, 243),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                    color: (distributionRate == null || distributionRate! <= 0)
                        ? Colors.grey // Grey color when disabled
                        : null, // No color if gradient is applied
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  child: Text(
                    'Save',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
