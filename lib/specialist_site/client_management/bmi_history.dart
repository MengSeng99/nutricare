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
                    child: const Text('Reset', style: TextStyle(color: Colors.white)),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text('BMI: ${record.bmi.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text('Recorded on: ${record.date}',
            style: TextStyle(color: Colors.grey)),
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
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                // Show only the first and last dates
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
        borderData: FlBorderData(show: true, border: Border.all(color: primaryColor)),
        minX: chartData.isNotEmpty ? chartData.last.x : 0,
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
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
            aboveBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                DateTime date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
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
  );
}
}


class BmiRecord {
  final String date;
  final double bmi;

  BmiRecord({
    required this.date,
    required this.bmi,
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