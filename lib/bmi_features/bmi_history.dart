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
            return const Center(child: Text('No BMI records found. Add it now from the Calculator!',style: TextStyle(fontSize: 20),));
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isGraphVisible =
                          !_isGraphVisible; // Toggle graph visibility
                    });
                  },
                  child: Text(_isGraphVisible ? 'Hide Graph' : 'Show Graph'),
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
                                        color: Colors
                                            .black, // Keeping the title neutral
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
                                          onPressed: () {
                                            // Confirm deletion
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Confirm Deletion'),
                                                  content: const Text(
                                                      'Are you sure you want to delete this record?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(); // Close the confirmation dialog
                                                      },
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    TextButton(
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
                                                                    'Record deleted successfully!')),
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
                                                              color:
                                                                  Colors.red)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: const Text('Delete',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                          child: const Text('Close'),
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
                        elevation: 0,
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
              color: Colors.blueGrey,
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

  // Method to build a line chart for BMI history
  Widget _buildBmiChart(List<FlSpot> chartData, List<String> chartDates) {
    return Container(
      height: 250, // Reduced height of the chart
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
            255, 255, 255, 255), // Background color for the chart
        borderRadius: BorderRadius.circular(15), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  int index = chartData.indexWhere((spot) => spot.x == value);
                  if (index != -1) {
                    DateTime date =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    // Display dates based on the number of records
                    if (chartData.length <= 5 ||
                        index % (chartData.length ~/ 4) == 0) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '${date.month}/${date.day}', // Display date in MM/DD format
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      );
                    }
                  }
                  return const SizedBox(); // Return an empty widget if not showing the label
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
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
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
              border: Border.all(color: const Color(0xff37434d), width: 1)),
          minX: chartData.isNotEmpty
              ? chartData.last.x
              : 0, // Ensure minX starts from the latest date
          maxX: chartData.isNotEmpty
              ? chartData.first.x
              : DateTime.now().millisecondsSinceEpoch.toDouble(),
          minY: 10,
          maxY: 40,
          lineBarsData: [
            LineChartBarData(
              spots: chartData,
              isCurved: true,
              color: Colors.blueAccent,
              dotData: FlDotData(show: true), // Show markers
              belowBarData: BarAreaData(show: false),
              aboveBarData:
                  BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              // tooltipBgColor: Colors.blueAccent,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index =
                      chartData.indexWhere((data) => data.x == spot.x);
                  if (index != -1) {
                    DateTime date =
                        DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
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
    );
  }
}
