import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class SpecialistAppointmentsScreen extends StatelessWidget {
  final String specialistId;

  const SpecialistAppointmentsScreen({super.key, required this.specialistId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('specialists')
                  .doc(specialistId)
                  .collection('appointments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text(
                          "No appointment time slots found for this specialist."));
                }

                final appointments = snapshot.data!.docs;
                // Updated grouping structure
                Map<String, Map<String, Map<String, List<String>>>>
                    groupedAppointments = {};

                for (var appointmentDoc in appointments) {
                  final appointment =
                      appointmentDoc.data() as Map<String, dynamic>;
                  final appointmentMode =
                      appointmentDoc.id; // 'Online' or 'Physical'
                  final dateSlots =
                      appointment['date_slots'] as Map<String, dynamic>?;

                  if (dateSlots != null) {
                    for (String date in dateSlots.keys) {
                      DateTime parsedDate = DateTime.parse(date);
                      if (parsedDate.isAfter(DateTime.now())) {
                        // Filter future dates
                        String monthYear =
                            DateFormat('MMMM yyyy').format(parsedDate);
                        if (!groupedAppointments.containsKey(monthYear)) {
                          groupedAppointments[monthYear] = {};
                        }
                        if (!groupedAppointments[monthYear]!
                            .containsKey(appointmentMode)) {
                          groupedAppointments[monthYear]![appointmentMode] = {};
                        }
                        if (!groupedAppointments[monthYear]![appointmentMode]!
                            .containsKey(date)) {
                          groupedAppointments[monthYear]![appointmentMode]![
                              date] = [];
                        }
                        // Assuming dateSlots[date] is a List<dynamic> of time slots
                        groupedAppointments[monthYear]![appointmentMode]![date]!
                            .addAll(
                          List<String>.from(dateSlots[date] as List<dynamic>),
                        );
                      }
                    }
                  }
                }

                if (groupedAppointments.isEmpty) {
                  return const Center(
                      child: Text("No upcoming appointment time slots."));
                }

                // Sort the groupedAppointments by month and year
                List<String> sortedMonthYears =
                    groupedAppointments.keys.toList()
                      ..sort((a, b) {
                        DateTime dateA = DateFormat('MMMM yyyy').parse(a);
                        DateTime dateB = DateFormat('MMMM yyyy').parse(b);
                        return dateA.compareTo(dateB);
                      });

                return ListView.builder(
                  itemCount: sortedMonthYears.length,
                  itemBuilder: (context, index) {
                    String monthYear = sortedMonthYears[index];
                    Map<String, Map<String, List<String>>> modes =
                        groupedAppointments[monthYear]!;

                    return Card(
                       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                        color: Color.fromARGB(255, 221, 222, 226), width: 1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthYear,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color:
                                    Color(0xFF5A71F3), // Blue color for month
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (String mode in modes.keys)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildAppointmentModeSection(
                                    mode, modes[mode]!, context),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A71F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 14.0, horizontal: 24.0),
              ),
              onPressed: () => _showAddTimeSlotDialog(context),
              child: const Text("Add Timeslots",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentModeSection(
      String mode, Map<String, List<String>> dateSlots, BuildContext context) {
    if (dateSlots.isEmpty) {
      return Text("$mode Appointment - No time slots available",
          style: const TextStyle(color: Colors.red));
    }

    // Sort the dates
    List<String> sortedDates = dateSlots.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "$mode Appointment Slots",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 8),
        for (String date in sortedDates)
          ExpansionTile(
            title: Text(
              "${DateFormat("EEEE, yyyy-MM-dd").format(DateTime.parse(date))} (${dateSlots[date]!.length} slots available)",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: dateSlots[date]!.map((timeSlot) {
                    return Chip(
                      label: Text(timeSlot,
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: (mode.toLowerCase() == 'online')
                          ? const Color(0xFF5A71F3)
                          : const Color(0xFFF35A5A),
                      deleteIcon: const Icon(Icons.delete,
                          size: 18, color: Colors.white),
                      onDeleted: () {
                        _showDeleteConfirmationDialog(
                            context, mode, date, timeSlot);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _showAddTimeSlotDialog(BuildContext context) async {
    String selectedMode = 'Online';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                'Add Appointment Time Slot',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Appointment Mode',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedMode,
                      items: <String>['Online', 'Physical'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child:
                              Text(value, style: const TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedMode = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(Duration(days: 1)),
                          firstDate: DateTime.now().add(Duration(days: 1)),
                          lastDate: DateTime.now().add(Duration(days: 30)),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: Color.fromARGB(255, 90, 113,
                                    243), // Custom color for header
                                hintColor: Color.fromARGB(255, 90, 113,
                                    243), // Custom color for actions
                                colorScheme: ColorScheme.light(
                                    primary: Color.fromARGB(255, 90, 113, 243)),
                                buttonTheme: ButtonThemeData(
                                    textTheme: ButtonTextTheme.primary),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (date != null) {
                          // Check if the selected date is a weekend, and if so, show a warning
                          if (date.weekday == DateTime.saturday ||
                              date.weekday == DateTime.sunday) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Weekends are not allowed. Please select a weekday.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            setState(() {
                              selectedDate = date;
                            });
                          }
                        }
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selectedDate == null
                              ? "Select Date"
                              : DateFormat("yyyy-MM-dd").format(selectedDate!),
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFF5A71F3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selectedTime == null
                              ? "Select Time"
                              : selectedTime!.format(context),
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFF5A71F3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel",
                      style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 90, 113, 243))),
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
                  child:
                      const Text('Add', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (selectedDate != null && selectedTime != null) {
                      String formattedDate =
                          DateFormat("yyyy-MM-dd").format(selectedDate!);
                      String timeFormatted = selectedTime!.format(context);
                      _addTimeSlot(selectedMode, formattedDate, timeFormatted);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '$selectedMode appointment slot on $formattedDate - $timeFormatted added successfully!')),
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              const Text('Please select both date and time.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addTimeSlot(
      String mode, String dateFormatted, String time) async {
    var appointmentCollection = FirebaseFirestore.instance
        .collection('specialists')
        .doc(specialistId)
        .collection('appointments')
        .doc(mode);

    DocumentSnapshot snapshot = await appointmentCollection.get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> dateSlots = data['date_slots'] != null
          ? Map<String, dynamic>.from(data['date_slots'])
          : {};

      if (dateSlots[dateFormatted] == null) {
        dateSlots[dateFormatted] = [];
      }

      List<dynamic> times = dateSlots[dateFormatted] as List<dynamic>;

      if (!times.contains(time)) {
        // Avoid duplicate time slots
        times.add(time);
        await appointmentCollection.update({'date_slots': dateSlots});
      } else {
        // Optionally, notify the user that the time slot already exists
        // This can be handled in the dialog or via a SnackBar
      }
    } else {
      await appointmentCollection.set({
        'date_slots': {
          dateFormatted: [time]
        }
      });
    }
  }

  Future<void> _deleteTimeSlot(
      String mode, String dateFormatted, String timeSlot) async {
    var appointmentCollection = FirebaseFirestore.instance
        .collection('specialists')
        .doc(specialistId)
        .collection('appointments')
        .doc(mode);

    DocumentSnapshot snapshot = await appointmentCollection.get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> dateSlots = data['date_slots'] != null
          ? Map<String, dynamic>.from(data['date_slots'])
          : {};

      if (dateSlots[dateFormatted] != null) {
        List<dynamic> times = dateSlots[dateFormatted] as List<dynamic>;
        times.remove(timeSlot); // Remove the specific time slot

        if (times.isEmpty) {
          dateSlots
              .remove(dateFormatted); // Remove the date if no time slots left
        } else {
          dateSlots[dateFormatted] = times;
        }

        await appointmentCollection.update({'date_slots': dateSlots});
      }
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String mode, String date, String timeSlot) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 90, 113, 243),
            ),
          ),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black),
              children: [
                const TextSpan(
                    text: 'Are you sure you want to delete the time slot on '),
                TextSpan(
                  text: '($date)',
                  style:
                      const TextStyle(color: Color.fromARGB(255, 90, 113, 243)),
                ),
                const TextSpan(text: ' at '),
                TextSpan(
                  text: '($timeSlot)',
                  style:
                      const TextStyle(color: Color.fromARGB(255, 90, 113, 243)),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteTimeSlot(mode, date, timeSlot);
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
