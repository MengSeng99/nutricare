import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'specialist_withdrawal.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  _EarningsScreenState createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  List<Map<String, dynamic>> allTransactions = []; // Combined list for both earnings and withdrawals
  String? currentUserId;
  List<int> availableYears = []; // List to hold unique years
  int? selectedMonth;
  int? selectedYear;
  bool noTransactionsForSelectedDate = false; // Indicator for showing no transactions

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
  }

  Future<void> _fetchCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      currentUserId = user.uid;
      await _fetchData(); // Fetch both earnings and withdrawals together
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user is signed in')));
    }
  }

  Future<void> _fetchData() async {
    List<Map<String, dynamic>> earningsList = await _fetchEarnings();
    List<Map<String, dynamic>> withdrawalsList = await _fetchWithdrawals();

    // Combine the lists into one
    List<Map<String, dynamic>> combinedList = [];

    combinedList.addAll(earningsList.map((earning) {
      return {
        'isEarning': true,
        ...earning,
      };
    }).toList());

    combinedList.addAll(withdrawalsList.map((withdrawal) {
      return {
        'isEarning': false,
        ...withdrawal,
      };
    }).toList());

    // Ensure correct sorting by date (latest entries first)
    combinedList.sort((a, b) {
      DateTime aDate = a['isEarning'] ? a['selectedDate'] : a['withdrawDate'];
      DateTime bDate = b['isEarning'] ? b['selectedDate'] : b['withdrawDate'];
      return bDate.compareTo(aDate); // Sort in descending order
    });

    setState(() {
      allTransactions = combinedList; // Store the sorted transactions
    });
}

  Future<List<Map<String, dynamic>>> _fetchEarnings() async {
    List<Map<String, dynamic>> earningsList = [];
    availableYears.clear(); // Reset the year list
    noTransactionsForSelectedDate = false; // Reset the flag

    // Fetch earnings associated with the current user
    var earningsSnapshot = await FirebaseFirestore.instance
        .collection('specialists')
        .doc(currentUserId)
        .collection('earnings')
        .get();

    for (var doc in earningsSnapshot.docs) {
      double amount = doc.data()['amount'] ?? 0.0;
      Timestamp timestamp = doc.data()['date'];
      String appointmentId = doc.data()['appointmentId'] ?? 'N/A';
      String clientName = doc.data()['clientName'] ?? 'N/A';
      double rate = double.tryParse(doc.data()['rate'].toString()) ?? 0.0;
      String service = doc.data()['service'] ?? 'N/A';
      DateTime selectedDate = timestamp.toDate();

      // Gather unique years for the year filter
      if (!availableYears.contains(selectedDate.year)) {
        availableYears.add(selectedDate.year);
      }

      earningsList.add({
        'appointmentId': appointmentId,
        'amount': amount,
        'clientName': clientName,
        'rate': rate,
        'service': service,
        'selectedDate': selectedDate,
      });
    }

    // Filter earnings based on selected month and year
    earningsList = earningsList.where((earning) {
      DateTime date = earning['selectedDate'];
      bool matchMonth = (selectedMonth == null || selectedMonth == 0 || date.month == selectedMonth);
      bool matchYear = (selectedYear == null || date.year == selectedYear);
      return matchMonth && matchYear;
    }).toList();

    if (earningsList.isEmpty) {
      noTransactionsForSelectedDate = true; // Set the flag if no earnings found
    }

    return earningsList; // Return the filtered earnings list
  }

  Future<List<Map<String, dynamic>>> _fetchWithdrawals() async {
    List<Map<String, dynamic>> withdrawalsList = [];
    var withdrawalsSnapshot = await FirebaseFirestore.instance
        .collection('specialists')
        .doc(currentUserId)
        .collection('withdrawal')
        .get();

    for (var doc in withdrawalsSnapshot.docs) {
      double amount = doc.data()['amount'] ?? 0.0;
      String bank = doc.data()['bank'] ?? 'N/A';
      String accountNumber = doc.data()['account_number'] ?? 'N/A';
      String beneficiaryName = doc.data()['beneficiary_name'] ?? 'N/A';
      Timestamp dateTimestamp = doc.data()['withdraw_date'] ?? Timestamp.now();
      DateTime withdrawDate = dateTimestamp.toDate();

      // Apply filtering based on selected month and year for withdrawals
      bool matchMonth = (selectedMonth == null || selectedMonth == 0 || withdrawDate.month == selectedMonth);
      bool matchYear = (selectedYear == null || withdrawDate.year == selectedYear);

      if (matchMonth && matchYear) {
        withdrawalsList.add({
          'amount': amount,
          'bank': bank,
          'accountNumber': accountNumber,
          'beneficiaryName': beneficiaryName,
          'withdrawDate': withdrawDate,
        });
      }
    }

    return withdrawalsList; // Return the withdrawals list
  }

  // Verify total earnings
  double getTotalEarnings() {
    double earningsTotal = allTransactions.where((t) => t['isEarning']).fold(0, (sum, t) => sum + t['amount']);
    double withdrawalsTotal = allTransactions.where((t) => !t['isEarning']).fold(0, (sum, t) => sum + t['amount']);
    return earningsTotal - withdrawalsTotal; // Return earnings minus withdrawals
  }

  // Display filter options
  Widget _buildFilterOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Month Filter
        DropdownButton<int>(
          value: selectedMonth,
          hint: const Text('Month'),
          items: [
            DropdownMenuItem<int>(
              value: 0, // All months
              child: const Text('All'),
            ),
          ] +
              List.generate(12, (index) => index + 1).map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(DateFormat('MMMM').format(DateTime(0, value))),
                );
              }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              selectedMonth = newValue;
              _fetchData(); // Fetch both data based on new filters
            });
          },
        ),
        // Year Filter
        DropdownButton<int>(
          value: selectedYear,
          hint: const Text('Year'),
          items: availableYears.map((int year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString()),
            );
          }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              selectedYear = newValue;
              _fetchData(); // Fetch both data based on new filters
            });
          },
        ),
      ],
    );
  }

  // Handle withdraw action
  void _handleWithdraw() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalScreen(
          totalEarnings: getTotalEarnings(),
          specialistId: currentUserId!,
          onWithdrawalSuccess: (double remainingEarnings) {
            setState(() {
              _fetchData(); // Refresh earnings and withdrawals
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Your Earnings',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFilterOptions(),
          ),
          Expanded(
            child: allTransactions.isEmpty
                ? Center(
                    child: noTransactionsForSelectedDate
                        ? Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 60,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'No Records Found',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'It seems there are no records for earning or withdrawal on the selected month/ year.',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : const CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                      // Total Earnings Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(255, 255, 255, 255),
                              Color.fromARGB(255, 238, 239, 241),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueGrey.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      color: Color.fromARGB(255, 90, 113, 243),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8.0),
                                    const Text(
                                      'Total Earnings:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 90, 113, 243),
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: _handleWithdraw,
                                  style: ElevatedButton.styleFrom(
                                    elevation: 2,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  child: const Text(
                                    'Withdraw',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 90, 113, 243),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'RM ${getTotalEarnings().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 90, 113, 243),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Earnings and Withdrawals List
                      Expanded(
                        child: ListView.builder(
                          itemCount: allTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = allTransactions[index];
                            if (transaction['isEarning']) {
                              // Render earning card
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                                child: Card(
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'RM ${transaction['amount'].toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.teal),
                                            ),
                                            Text('Appt ID: ${transaction['appointmentId'] ?? "N/A"}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(transaction['selectedDate'].toLocal())}',
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Client Name: ${transaction['clientName']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                        const SizedBox(height: 4),
                                        Text('Rate: ${(transaction['rate']! * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                        const SizedBox(height: 4),
                                        Text('Service: ${transaction['service']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              // Render withdrawal card
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                                child: Card(
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'RM ${transaction['amount'].toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.red),
                                            ),
                                            Text('Withdrawn', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Withdraw Date: ${DateFormat('yyyy-MM-dd HH:mm').format(transaction['withdrawDate'].toLocal())}',
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Bank: ${transaction['bank']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                        const SizedBox(height: 4),
                                        Text('Account Number: ${transaction['accountNumber']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                        const SizedBox(height: 4),
                                        Text('Beneficiary: ${transaction['beneficiaryName']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}