// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class BmiHistoryScreen extends StatefulWidget {
  const BmiHistoryScreen({super.key});

  @override
  _BmiHistoryScreenState createState() => _BmiHistoryScreenState();
}

class _BmiHistoryScreenState extends State<BmiHistoryScreen> {
  bool _isGraphVisible = true; // State to manage graph visibility

  // Function to determine the BMI category and color based on BMI value
  Color getBmiColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.blue; // Underweight
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return Colors.green; // Normal weight
    } else if (bmi >= 25.0 && bmi <= 29.9) {
      return Colors.orange; // Pre-obesity
    } else if (bmi >= 30.0 && bmi <= 34.9) {
      return Colors.red; // Obesity class I
    } else if (bmi >= 35.0 && bmi <= 39.9) {
      return Colors.red.shade700; // Obesity class II
    } else {
      return Colors.red.shade900; // Obesity class III
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user from Firebase Auth
    User? user = FirebaseAuth.instance.currentUser;

    // Ensure user is logged in
    if (user == null) {
      return Scaffold(
        body: const Center(
          child: Text('Please log in to view your BMI history.'),
        ),
      );
    }

    String userId = user.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bmi-tracker')
            .doc(userId)
            .collection('bmi-records')
            .orderBy('date', descending: true) // Sort by date (latest first)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data.'));
          }

          final records = snapshot.data?.docs;

          if (records == null || records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 100,
                      color: Color.fromARGB(255, 90, 113, 243),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No BMI records available yet!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You can add a new record using the Calculator.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Prepare data for the chart
          List<FlSpot> chartData = [];
          List<String> chartDates =
              []; // Store the dates corresponding to the chart data
          for (var record in records) {
            final recordData = record.data() as Map<String, dynamic>;
            final double bmi = double.parse(recordData['bmi'].toString());
            final String dateString = recordData['date'];
            final DateTime date = DateTime.parse(
                dateString); // Assuming the date is in ISO format
            final double x = date.millisecondsSinceEpoch.toDouble();
            chartData.add(FlSpot(x, bmi));
            chartDates.add(dateString); // Store the corresponding date
          }

          return Column(
            children: [
              // Button to toggle graph visibility
              // Button to toggle graph visibility
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isGraphVisible =
                          !_isGraphVisible; // Toggle graph visibility
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        255, 90, 113, 243), // Background color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30), // Rounded corners
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // To fit the content
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isGraphVisible
                            ? Icons.disabled_by_default_outlined
                            : Icons.insert_chart_outlined,
                        color: Colors.white, // Icon color
                      ),
                      const SizedBox(width: 8), // Spacing between icon and text
                      Text(
                        _isGraphVisible ? 'Hide Graph' : 'Show Graph',
                        style:
                            const TextStyle(color: Colors.white), // Text color
                      ),
                    ],
                  ),
                ),
              ),
              // Show graph only if _isGraphVisible is true
              if (_isGraphVisible)
                _buildBmiChart(
                    chartData, chartDates), // Add the chart at the top
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record =
                        records[index].data() as Map<String, dynamic>;
                    final double bmi = double.parse(record['bmi'].toString());
                    final Color bmiColor = getBmiColor(bmi);
                    final String formattedDate = record['date'];
                    final String formattedTime = record['time'];
                    final String recordId =
                        records[index].id; // Get the document ID for deletion

                    return GestureDetector(
                      onTap: () {
                        // Show the details in a dialog when the user taps the BMI value
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 16,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'BMI Details',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 90, 113,
                                            243), // Keeping the title neutral
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Divider(color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    // Display the BMI with the appropriate color
                                    Text(
                                      'BMI: ${record['bmi']}',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            bmiColor, // Color according to the BMI category
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildDetailRow(Icons.height, 'Height',
                                        '${record['height']} CM'),
                                    _buildDetailRow(Icons.fitness_center,
                                        'Weight', '${record['weight']} KG'),
                                    _buildDetailRow(Icons.calendar_today, 'Age',
                                        '${record['age']} years'),
                                    _buildDetailRow(Icons.person, 'Gender',
                                        record['gender']),
                                    _buildDetailRow(Icons.category, 'Category',
                                        record['bmiCategory']),
                                    _buildDetailRow(
                                        Icons.assignment,
                                        'Ideal Weight',
                                        record['idealWeightRange']),
                                    const SizedBox(height: 10),
                                    Divider(color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Recorded on: $formattedDate at $formattedTime',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.red, // Blue background
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          onPressed: () {
                                            // Confirm deletion
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                  title: const Text(
                                                    'Confirm Deletion',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color.fromARGB(
                                                            255, 90, 113, 243)),
                                                  ),
                                                  content: const Text(
                                                    'Are you sure you want to delete this record?',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                  actions: [
                                                    ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor: const Color
                                                            .fromARGB(
                                                            255,
                                                            90,
                                                            113,
                                                            243), // Blue background
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(); // Close the confirmation dialog
                                                      },
                                                      child: const Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor: Colors
                                                            .red, // Blue background
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30),
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        // Delete the record from Firestore
                                                        try {
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'bmi-tracker')
                                                              .doc(userId)
                                                              .collection(
                                                                  'bmi-records')
                                                              .doc(recordId)
                                                              .delete();

                                                          Navigator.of(context)
                                                              .pop(); // Close the confirmation dialog
                                                          Navigator.of(context)
                                                              .pop(); // Close the details dialog
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Record deleted successfully!'),
                                                              backgroundColor:
                                                                  Colors.green,
                                                            ),
                                                          );
                                                        } catch (e) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                                content: Text(
                                                                    'Failed to delete record: $e')),
                                                          );
                                                        }
                                                      },
                                                      child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: const Text('Delete',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
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
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                          child: const Text(
                                            'Close',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Card(
                        color: Colors.white, // Set card background to whitez
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.2), // Add grey border
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween, // Align items
                            children: [
                              Expanded(
                                child: Text(
                                  'BMI: ${record['bmi']}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        bmiColor, // Color according to the BMI category
                                  ),
                                ),
                              ),
                              Icon(Icons.expand_more,
                                  color:
                                      Colors.grey.shade400), // Static view icon
                            ],
                          ),
                          subtitle: Text(
                            'Recorded on: $formattedDate',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // Updated Method to build a row for detail display in the dialog
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 8.0), // Vertical padding for spacing
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Align icons and text vertically
        children: [
          Icon(icon,
              color: const Color.fromARGB(255, 90, 113, 243),
              size: 20), // Reduced icon size for better alignment
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title, // Title on the left
              style:
                  const TextStyle(fontSize: 16), // Uniform text size for titles
            ),
          ),
          Text(
            value, // Value on the right
            style:
                const TextStyle(fontSize: 16), // Uniform text size for values
            textAlign: TextAlign.right, // Align text to the right
          ),
        ],
      ),
    );
  }

  Widget _buildBmiChart(List<FlSpot> chartData, List<String> chartDates) {
  return Card(
    elevation: 2, // Add some elevation for shadow effect
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Margins around the card
    child: Container(
      height: 400, // Adjusted height to fit chart and description
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, // Ensuring the card background is white
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade400, width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Chart Section
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        int index =
                            chartData.indexWhere((spot) => spot.x == value);
                        if (index != -1) {
                          DateTime date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          if (chartData.length <= 5 ||
                              index % (chartData.length ~/ 4) == 0) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '${date.month}/${date.day}', // MM/DD format
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            );
                          }
                        }
                        return const SizedBox(); // Empty widget if no label
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toString(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                        color: const Color(0xff37434d), width: 1)),
                minX: chartData.isNotEmpty
                    ? chartData.last.x
                    : 0, // Ensure minX starts from latest date
                maxX: chartData.isNotEmpty
                    ? chartData.first.x
                    : DateTime.now().millisecondsSinceEpoch.toDouble(),
                minY: 10,
                maxY: 40,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 18.5,
                      color: Colors.green.withOpacity(0.8),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                    HorizontalLine(
                      y: 24.9,
                      color: Colors.green.withOpacity(0.8),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: Colors.blueAccent,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                        show: true, color: Colors.blue.withOpacity(0.2)),
                    aboveBarData: BarAreaData(
                        show: false, color: Colors.blue.withOpacity(0.2)),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index =
                            chartData.indexWhere((data) => data.x == spot.x);
                        if (index != -1) {
                          DateTime date = DateTime.fromMillisecondsSinceEpoch(
                              spot.x.toInt());
                          return LineTooltipItem(
                            'Date: ${date.month}/${date.day}\nBMI: ${spot.y.toStringAsFixed(1)}',
                            const TextStyle(color: Colors.white),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    // Handle touch response
                  },
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10), // Space between chart and description
          // Description Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Your BMI values",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 2,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Normal BMI range (18.5 - 24.9)",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
