import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class SpecialistAppointmentsScreen extends StatelessWidget {
  final String specialistId;

  const SpecialistAppointmentsScreen({super.key, required this.specialistId});

   @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  return const Center(child: Text("No appointment time slots found."));
                }

                final appointments = snapshot.data!.docs;
                Map<String, Map<String, dynamic>> groupedAppointments = {};

                // Group appointments by mode and month
                for (var appointmentDoc in appointments) {
                  final appointment = appointmentDoc.data() as Map<String, dynamic>;
                  final appointmentMode = appointmentDoc.id; // This holds the mode (Online or Physical)
                  final dateSlots = appointment['date_slots'] as Map<String, dynamic>?;

                  if (dateSlots != null) {
                    for (String date in dateSlots.keys) {
                      String monthYear = DateFormat('MMMM yyyy').format(DateTime.parse(date));
                      if (!groupedAppointments.containsKey(monthYear)) {
                        groupedAppointments[monthYear] = {};
                      }

                      groupedAppointments[monthYear]![appointmentMode] = dateSlots;
                    }
                  }
                }

                return ListView.builder(
                  itemCount: groupedAppointments.keys.length,
                  itemBuilder: (context, index) {
                    String monthYear = groupedAppointments.keys.elementAt(index);
                    Map<String, dynamic> modes = groupedAppointments[monthYear]!;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                                color: Color(0xFF5A71F3), // Set the month color to blue
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (String mode in modes.keys)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildAppointmentModeSection(mode, modes[mode], context),
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
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
              ),
              onPressed: () => _showAddTimeSlotDialog(context),
              child: const Text("Add Timeslots", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentModeSection(String mode, Map<String, dynamic>? dateSlots, BuildContext context) {
    if (dateSlots == null || dateSlots.isEmpty) {
      return Text("$mode Appointment - No time slots available", style: TextStyle(color: Colors.red));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center( // Center the title
          child: Text(
            "$mode Appointment Slots", 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 8),
        for (String date in dateSlots.keys)
          ExpansionTile(
            title: Text(
              DateFormat("EEEE, yyyy-MM-dd").format(DateTime.parse(date)),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: (dateSlots[date] as List<dynamic>).map((timeSlot) {
                    return Chip(
                      label: Text(timeSlot, style: const TextStyle(color: Colors.white)),
                      backgroundColor: (mode == 'Online') ? const Color(0xFF5A71F3) : const Color(0xFFF35A5A),
                      deleteIcon: const Icon(Icons.delete, size: 18, color: Colors.white),
                      onDeleted: () {
                        _showDeleteConfirmationDialog(context, mode, date, timeSlot);
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
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedMode,
                      items: <String>['Online', 'Physical'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 16)),
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
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Text(
                        selectedDate == null
                            ? "Select Date"
                            : DateFormat("yyyy-MM-dd").format(selectedDate!),
                        style: const TextStyle(fontSize: 16, color: Color(0xFF5A71F3)),
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
                      child: Text(
                        selectedTime == null
                            ? "Select Time"
                            : selectedTime!.format(context),
                        style: const TextStyle(fontSize: 16, color: Color(0xFF5A71F3)),
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
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (selectedDate != null && selectedTime != null) {
                      String formattedDate =
                          DateFormat("yyyy-MM-dd").format(selectedDate!);
                      String timeFormatted = selectedTime!.format(context);
                      _addTimeSlot(selectedMode, formattedDate, timeFormatted);
                      Navigator.of(context).pop();
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

  Future<void> _addTimeSlot(String mode, String dateFormatted, String time) async {
    var appointmentCollection = FirebaseFirestore.instance
        .collection('specialists')
        .doc(specialistId)
        .collection('appointments')
        .doc(mode);

    DocumentSnapshot snapshot = await appointmentCollection.get();

    if (snapshot.exists) {
      Map<String, dynamic> dateSlots =
          (snapshot.data() as Map<String, dynamic>)['date_slots'] ?? {};
      if (dateSlots[dateFormatted] == null) {
        dateSlots[dateFormatted] = [];
      }
      dateSlots[dateFormatted].add(time);
      await appointmentCollection.update({'date_slots': dateSlots});
    } else {
      await appointmentCollection.set({
        'date_slots': {
          dateFormatted: [time]
        }
      });
    }
  }

  Future<void> _deleteTimeSlot(String mode, String dateFormatted, String time) async {
    var appointmentCollection = FirebaseFirestore.instance
        .collection('specialists')
        .doc(specialistId)
        .collection('appointments')
        .doc(mode);

    DocumentSnapshot snapshot = await appointmentCollection.get();

    if (snapshot.exists) {
      Map<String, dynamic> dateSlots =
          (snapshot.data() as Map<String, dynamic>)['date_slots'] ?? {};

      if (dateSlots[dateFormatted] != null) {
        dateSlots[dateFormatted] = (dateSlots[dateFormatted] as List<dynamic>)
            .where((t) => t != time) // Remove the specific time slot
            .toList();

        // Check if the date no longer has any time slots
        if (dateSlots[dateFormatted].isEmpty) {
          dateSlots.remove(dateFormatted);
        }

        await appointmentCollection.update({'date_slots': dateSlots});
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String mode, String date, String timeSlot) {
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
                const TextSpan(text: 'Are you sure you want to delete the time slot on '),
                TextSpan(
                  text: '($date)',
                  style: const TextStyle(color: Color.fromARGB(255, 90, 113, 243)),
                ),
                const TextSpan(text: ' at '),
                TextSpan(
                  text: '($timeSlot)',
                  style: const TextStyle(color: Color.fromARGB(255, 90, 113, 243)),
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
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}