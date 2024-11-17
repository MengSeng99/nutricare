import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentAnalysisScreen extends StatefulWidget {
  const AppointmentAnalysisScreen({super.key});

  @override
  _AppointmentAnalysisScreenState createState() =>
      _AppointmentAnalysisScreenState();
}

class _AppointmentAnalysisScreenState
    extends State<AppointmentAnalysisScreen> {
  String? selectedStatus;
  String? selectedMonth;
  String? selectedMode; // New variable for mode selection
  int? selectedYear;
  List<int> availableYears = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableYears();
  }

  Future<void> _fetchAvailableYears() async {
    final Set<int> yearsSet = {};

    Query query = FirebaseFirestore.instance.collection('appointments');
    QuerySnapshot appointmentSnapshot = await query.get();

    for (var appointmentDoc in appointmentSnapshot.docs) {
      QuerySnapshot detailsSnapshot =
          await appointmentDoc.reference.collection('details').get();

      for (var detailDoc in detailsSnapshot.docs) {
        final detailData = detailDoc.data() as Map<String, dynamic>;
        if (detailData['selectedDate'] != null) {
          DateTime date = (detailData['selectedDate'] as Timestamp).toDate();
          yearsSet.add(date.year);
        }
      }
    }

    setState(() {
      availableYears = yearsSet.toList()..sort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointment Analysis',
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
        iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 90, 113, 243)), // Back button color
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Month",
                          style: TextStyle(color: Colors.grey)),
                      value: selectedMonth,
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value;
                        });
                      },
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All (Month)',style: TextStyle(fontSize: 14),)),
                        ...List.generate(12, (index) {
                          final month =
                              DateFormat('MMMM').format(DateTime(0, index + 1));
                          return DropdownMenuItem(
                              value: month, child: Text(month));
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 0),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Status",
                          style: TextStyle(color: Colors.grey)),
                      value: selectedStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All (Status)',style: TextStyle(fontSize: 14),)),
                        const DropdownMenuItem(
                            value: 'Confirmed', child: Text('Confirmed')),
                        const DropdownMenuItem(
                            value: 'Completed', child: Text('Completed')),
                        const DropdownMenuItem(
                            value: 'Canceled', child: Text('Canceled')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 0),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Mode",
                          style: TextStyle(color: Colors.grey)),
                      value: selectedMode,
                      onChanged: (value) {
                        setState(() {
                          selectedMode = value;
                        });
                      },
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All (Mode)',style: TextStyle(fontSize: 14),)),
                        const DropdownMenuItem(value: 'Online', child: Text('Online')),
                        const DropdownMenuItem(value: 'Physical', child: Text('Physical')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 0),
                  Expanded(
                    child: availableYears.isNotEmpty
                        ? DropdownButton<int>(
                            isExpanded: true,
                            hint: const Text("Select Year",
                                style: TextStyle(color: Colors.grey,fontSize: 14)),
                            value: selectedYear,
                            onChanged: (value) {
                              setState(() {
                                selectedYear = value;
                              });
                            },
                            items: availableYears.map((year) {
                              return DropdownMenuItem(
                                  value: year, child: Text(year.toString()));
                            }).toList(),
                          )
                        : const Text("No Years Available"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _buildChart(),
            ),
            const SizedBox(height: 10), // spacing
            Expanded(
              child: _buildSpecialistChart(),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF6F7FB),
    );
  }

  Widget _buildChart() {
    return FutureBuilder<Map<String, Map<String, int>>>(
      future: _fetchChartData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No Data Available'));
        }

        final data = snapshot.data!;
        List<BarChartGroupData> barGroups = [];
        List<String> filteredDates = data.keys.toList();

        // Filtering by month, year, and mode
        if (selectedMonth != null || selectedYear != null || selectedMode != null) {
          filteredDates = filteredDates.where((date) {
            final parsedDate = DateFormat('MMM dd, yyyy').parse(date);
            bool matchesMonth = selectedMonth == null ||
                DateFormat('MMMM').format(parsedDate) == selectedMonth;
            bool matchesYear =
                selectedYear == null || parsedDate.year == selectedYear!;

            return matchesMonth && matchesYear;
          }).toList();
        }

        filteredDates.sort((a, b) => DateFormat('MMM dd, yyyy')
            .parse(a)
            .compareTo(DateFormat('MMM dd, yyyy').parse(b)));
        double maxY = 0;

        for (int index = 0; index < filteredDates.length; index++) {
          final date = filteredDates[index];
          final statusCounts = data[date]!;

          List<BarChartRodData> rods = [];
          double total = 0;
          if (selectedStatus == null || selectedStatus == 'Confirmed') {
            double confirmedCount = statusCounts['Confirmed']?.toDouble() ?? 0;
            total += confirmedCount;
            rods.add(BarChartRodData(
                toY: confirmedCount, color: Colors.greenAccent));
          }
          if (selectedStatus == null || selectedStatus == 'Completed') {
            double completedCount = statusCounts['Completed']?.toDouble() ?? 0;
            total += completedCount;
            rods.add(
                BarChartRodData(toY: completedCount, color: Colors.blueAccent));
          }
          if (selectedStatus == null || selectedStatus == 'Canceled') {
            double canceledCount = statusCounts['Canceled']?.toDouble() ?? 0;
            total += canceledCount;
            rods.add(BarChartRodData(
                toY: canceledCount, color: Colors.redAccent));
          }

          barGroups
              .add(BarChartGroupData(x: index, barRods: rods, barsSpace: 4));

          if (total > maxY) {
            maxY = total;
          }
        }

        maxY = maxY > 0 ? maxY : 1;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= filteredDates.length) {
                        return Container();
                      }
                      final date = filteredDates[value.toInt()];
                      final formattedDate = DateFormat('MMM dd')
                          .format(DateFormat('MMM dd, yyyy').parse(date));
                      final year = DateFormat('yyyy')
                          .format(DateFormat('MMM dd, yyyy').parse(date));
                      return Column(
                        children: [
                          Text(formattedDate,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 10)),
                          Text(year,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 8)),
                        ],
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: maxY <= 2 ? 1 : (maxY / 4).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value % 1 == 0) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1)),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String status = '';
                    if (rodIndex == 0) {
                      status = 'Confirmed';
                    } else if (rodIndex == 1) {
                      status = 'Completed';
                    } else if (rodIndex == 2) {
                      status = 'Canceled';
                    }
                    return BarTooltipItem(
                      '$status: ${rod.toY.toInt()}',
                      TextStyle(color: rod.color),
                    );
                  },
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, Map<String, int>>> _fetchChartData() async {
    Map<String, Map<String, int>> counts = {};

    Query query = FirebaseFirestore.instance.collection('appointments');
    QuerySnapshot appointmentSnapshot = await query.get();

    for (var appointmentDoc in appointmentSnapshot.docs) {
      QuerySnapshot detailsSnapshot =
          await appointmentDoc.reference.collection('details').get();

      for (var detailDoc in detailsSnapshot.docs) {
        final detailData = detailDoc.data() as Map<String, dynamic>;
        String status = detailData['appointmentStatus'];
        String mode = detailData['appointmentMode'] ?? "Unknown Mode"; // New line
        if (selectedMode != null && selectedMode != mode) continue; // Apply filter

        DateTime date = (detailData['selectedDate'] as Timestamp).toDate();
        String formattedDate = DateFormat('MMM dd, yyyy').format(date);

        if (!counts.containsKey(formattedDate)) {
          counts[formattedDate] = {
            'Confirmed': 0,
            'Completed': 0,
            'Canceled': 0
          };
        }
        if (counts[formattedDate]!.containsKey(status)) {
          counts[formattedDate]![status] = counts[formattedDate]![status]! + 1;
        }
      }
    }
    return counts;
  }

  Future<Map<String, int>> _fetchSpecialistData() async {
  Map<String, int> specialistCounts = {};

  Query query = FirebaseFirestore.instance.collection('appointments');
  QuerySnapshot appointmentSnapshot = await query.get();

  for (var appointmentDoc in appointmentSnapshot.docs) {
    QuerySnapshot detailsSnapshot =
        await appointmentDoc.reference.collection('details').get();

    for (var detailDoc in detailsSnapshot.docs) {
      final detailData = detailDoc.data() as Map<String, dynamic>;
      String specialistName = detailData['specialistName'] ?? "Unknown Specialist"; 
      String mode = detailData['appointmentMode'] ?? "Unknown Mode"; // New line

      // Apply filters for mode, status, and month
      if (selectedMode != null && selectedMode != mode) continue; // Filter by mode
      String status = detailData['appointmentStatus'];
      if (selectedStatus != null && selectedStatus != status) continue; // Filter by status
      DateTime date = (detailData['selectedDate'] as Timestamp).toDate();

      // Check month filter
      if (selectedMonth != null && DateFormat('MMMM').format(date) != selectedMonth) {
        continue; // Filter by month
      }

      // Increment specialist count
      if (specialistCounts.containsKey(specialistName)) {
        specialistCounts[specialistName] = specialistCounts[specialistName]! + 1;
      } else {
        specialistCounts[specialistName] = 1;
      }
    }
  }
  return specialistCounts;
}

  Widget _buildSpecialistChart() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchSpecialistData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No Data Available'));
        }

        final specialistData = snapshot.data!;
        List<PieChartSectionData> sections = [];
        int totalCount = 0;

        List<Color> colorPalette = [
          Colors.blueAccent,
          Colors.greenAccent,
          Colors.redAccent,
          Colors.orangeAccent,
          Colors.purpleAccent,
          Colors.tealAccent,
        ];

        int colorIndex = 0;

        specialistData.forEach((specialistName, count) {
          sections.add(PieChartSectionData(
            value: count.toDouble(),
            title: '$specialistName\n$count',
            titleStyle: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            color: colorPalette[colorIndex % colorPalette.length],
            badgeWidget: const Icon(Icons.favorite, color: Colors.white),
            badgePositionPercentageOffset: 1.5,
          ));
          totalCount += count;
          colorIndex++;
        });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              const Text(
                'Appointments by Specialist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    borderData: FlBorderData(show: false),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        // Handle interactions here, if needed
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Total Appointments: $totalCount',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }
}