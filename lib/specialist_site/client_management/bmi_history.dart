import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class BmiHistoryScreen extends StatefulWidget {
  final String clientId;

  const BmiHistoryScreen({super.key, required this.clientId});

  @override
  _BmiHistoryScreenState createState() => _BmiHistoryScreenState();
}

class _BmiHistoryScreenState extends State<BmiHistoryScreen> {
  List<BmiRecord> bmiRecords = [];
  List<BmiRecord> filteredRecords = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = true;
  bool isGraphVisible = true;

  final Color primaryColor = Color.fromARGB(255, 90, 113, 243);

  @override
  void initState() {
    super.initState();
    _loadBmiHistory();
  }

  Future<void> _loadBmiHistory() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bmi-tracker')
        .doc(widget.clientId)
        .collection('bmi-records')
        .orderBy('date', descending: true)
        .get();

    List<BmiRecord> records = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return BmiRecord(
        date: data['date'],
        bmi: double.parse(data['bmi'].toString()),
        height: double.parse(data['height'].toString()), // New fields
        weight: double.parse(data['weight'].toString()),
        age: data['age'],
        gender: data['gender'],
        bmiCategory: data['bmiCategory'],
        idealWeightRange: data['idealWeightRange'],
      );
    }).toList();

    setState(() {
      bmiRecords = records;
      filteredRecords = records; // Initially show all records
      isLoading = false;
    });
}

  Map<String, List<BmiRecord>> _categorizeRecords(List<BmiRecord> records) {
    final Map<String, List<BmiRecord>> categorizedRecords = {
      'This Week': [],
      'Last Week': [],
      'This Month': [],
      'Last Month': [],
    };

    final now = DateTime.now();
    final beginningOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final beginningOfLastWeek = beginningOfThisWeek.subtract(Duration(days: 7));
    final beginningOfThisMonth = DateTime(now.year, now.month, 1);
    final beginningOfLastMonth = DateTime(now.year, now.month - 1, 1);

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record.date);

      if (recordDate.isAfter(beginningOfThisWeek)) {
        categorizedRecords['This Week']!.add(record);
      } else if (recordDate.isAfter(beginningOfLastWeek) &&
          recordDate.isBefore(beginningOfThisWeek)) {
        categorizedRecords['Last Week']!.add(record);
      } else if (recordDate.isAfter(beginningOfThisMonth)) {
        categorizedRecords['This Month']!.add(record);
      } else if (recordDate.isAfter(beginningOfLastMonth) &&
          recordDate.isBefore(beginningOfThisMonth)) {
        categorizedRecords['Last Month']!.add(record);
      }
    }
    return categorizedRecords;
  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedRange != null) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;
        filteredRecords = bmiRecords.where((record) {
          DateTime recordDate = DateTime.parse(record.date);
          return recordDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
              recordDate.isBefore(endDate!.add(Duration(days: 1)));
        }).toList();
      });
    }
  }

  void _resetDateRange() {
    setState(() {
      startDate = null;
      endDate = null;
      filteredRecords = bmiRecords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isLoading)
              Center(child: CircularProgressIndicator(color: primaryColor))
            else if (bmiRecords.isEmpty)
              Expanded(child: _buildNoBmiHistoryWidget())
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _selectDateRange,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            (startDate != null && endDate != null)
                                ? 'Selected: ${startDate!.month}/${startDate!.day} - ${endDate!.month}/${endDate!.day}'
                                : 'Select Date Range',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _resetDateRange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            // Show no records message if needed
            if (filteredRecords.isEmpty && startDate != null && endDate != null)
              Center(
                child: _buildNoRecordsMessage(),
              )
            else if (filteredRecords.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    if (isGraphVisible) _buildBmiChart(filteredRecords),
                    const SizedBox(height: 10),
                    // Centered toggle graph visibility button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isGraphVisible = !isGraphVisible;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isGraphVisible
                                ? Icons.disabled_by_default_outlined
                                : Icons.insert_chart_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isGraphVisible ? 'Hide Graph' : 'Show Graph',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          BmiRecord record = filteredRecords[index];
                          return _buildBmiCard(record);
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBmiHistoryWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 100, color: primaryColor),
            SizedBox(height: 16),
            Text(
              'No BMI History Available Yet!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'The current user has not logged any BMI history yet.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecordsMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 100, color: primaryColor),
          SizedBox(height: 16),
          Text(
            'No BMI records available for the selected date range!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Try selecting a different date range.',
            style: TextStyle(fontSize: 15, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCard(BmiRecord record) {
  return GestureDetector(
    onTap: () {
      // Show BMI detail dialog
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
                      color: Color.fromARGB(255, 90, 113, 243),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'BMI: ${record.bmi.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: getBmiColor(record.bmi), // Get color based on BMI
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.height, 'Height', '${record.height} CM'),
                  _buildDetailRow(Icons.fitness_center, 'Weight', '${record.weight} KG'),
                  _buildDetailRow(Icons.calendar_today, 'Age', '${record.age} years'),
                  _buildDetailRow(Icons.person, 'Gender', record.gender),
                  _buildDetailRow(Icons.category, 'Category', record.bmiCategory),
                  _buildDetailRow(Icons.assignment, 'Ideal Weight', record.idealWeightRange),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'Recorded on: ${record.date}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text('Close', style: TextStyle(color: Colors.white)),
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
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        title: Text('BMI: ${record.bmi.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: getBmiColor(record.bmi))),
        subtitle: Text('Recorded on: ${record.date}',
            style: TextStyle(color: Colors.grey)),
      ),
    ),
  );
}

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

Widget _buildDetailRow(IconData icon, String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: primaryColor, size: 24), // Use the primary color
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    ),
  );
}

  Widget _buildBmiChart(List<BmiRecord> records) {
  List<FlSpot> chartData = records.map((record) {
    final DateTime date = DateTime.parse(record.date);
    return FlSpot(date.millisecondsSinceEpoch.toDouble(), record.bmi);
  }).toList();

  return Container(
    height: MediaQuery.of(context).size.height * 0.45,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey.shade400, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      DateTime date =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      if (value == chartData.first.x || value == chartData.last.x) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${date.month}/${date.day}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        );
                      }
                      return const SizedBox();
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
                          style: const TextStyle(color: Colors.black54),
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
              borderData:
                  FlBorderData(show: true, border: Border.all(color: primaryColor)),
              minX: chartData.isNotEmpty ? chartData.last.x : 0,
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
                  belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                  aboveBarData:
                      BarAreaData(show: false, color: Colors.blue.withOpacity(0.2)),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      DateTime date =
                          DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                      return LineTooltipItem(
                        '${date.month}/${date.day}\nBMI: ${spot.y.toStringAsFixed(1)}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10), // Add spacing between the chart and the description
        // Description Section
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
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
                      "BMI values.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
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
                      "Normal BMI range (18.5 - 24.9).",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

}

class BmiRecord {
  final String date;
  final double bmi;
  final double height; // Additional fields
  final double weight;
  final int age;
  final String gender;
  final String bmiCategory;
  final String idealWeightRange;

  BmiRecord({
    required this.date,
    required this.bmi,
    required this.height,
    required this.weight,
    required this.age, // Add other parameters
    required this.gender,
    required this.bmiCategory,
    required this.idealWeightRange,
  });
}

class BMIHistoryWidget extends StatelessWidget {
  final String clientId;

  const BMIHistoryWidget({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return BmiHistoryScreen(clientId: clientId);
  }
}
