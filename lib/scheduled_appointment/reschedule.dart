import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RescheduleScreen extends StatefulWidget {
  final String appointmentId;
  final String specialistId;
  final String appointmentMode;
  final DateTime originalDate;

  const RescheduleScreen({
    required this.appointmentId,
    required this.specialistId,
    required this.appointmentMode,
    required this.originalDate,
    super.key,
  });

  @override
  _RescheduleScreenState createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String _selectedMode = "Physical"; // Default to "Physical"
  List<String> availableTimeSlots = [];
  bool isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget
        .appointmentMode; // Set the initial mode to the original appointment mode
  }

  Future<void> _fetchAvailableTimeSlots() async {
    if (_selectedDate == null) return;

    final selectedDateString = _selectedDate!.toIso8601String().split('T')[0];
    final docRef = FirebaseFirestore.instance
        .collection('specialists')
        .doc(widget.specialistId)
        .collection('appointments')
        .doc(_selectedMode); // Fetch based on selected mode

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data['date_slots'] != null) {
        final dateSlots = Map<String, dynamic>.from(data['date_slots']);
        setState(() {
          availableTimeSlots =
              List<String>.from(dateSlots[selectedDateString] ?? []);
          isLoadingSlots = false;
        });
      }
    } else {
      setState(() {
        availableTimeSlots = [];
        isLoadingSlots = false;
      });
    }
  }

  Future<void> _rescheduleAppointment() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a date and a time slot."),
        ),
      );
      return;
    }

    // Update Firestore
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('appointments')
        .doc(widget.appointmentId)
        .update({
      'appointmentMode': _selectedMode,
      'selectedDate': _selectedDate,
      'selectedTimeSlot': _selectedTimeSlot,
      'appointmentStatus':
          'Pending Confirmation', // Always set to Pending Confirmation
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment successfully reschedule to $_selectedMode Appointment, on $_selectedDate | $_selectedTimeSlot.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context); // Go back after reschedule
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime twoDaysBeforeOriginal =
        widget.originalDate.subtract(const Duration(days: 2));
    DateTime endDate =
        now.add(const Duration(days: 30)); // End date is 30 days from now

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Reschedule Appointment",
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
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Appointment Mode"),
            const SizedBox(height: 10),
            _buildModeSelector(), // Physical or Online mode selector
            const SizedBox(height: 24),

            // Calendar for selecting date
            _buildSectionTitle("Select Reschedule Date"),
            _buildSectionSubtitle(
              "Reschedule date only allowed for at least 2 days before the original appointment.",
            ),
            const SizedBox(height: 12),
            _buildCalendar(now, endDate, twoDaysBeforeOriginal),
            const SizedBox(height: 0),

            // Time slots section
            if (isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (availableTimeSlots.isEmpty)
              const Text(
                "No available time slots for the selected date.",
                style: TextStyle(fontSize: 16, color: Colors.redAccent),
              )
            else
              _buildTimeSlotSelector(),

            const SizedBox(height: 30),

            // Reschedule button
            Center(
              child: ElevatedButton(
                onPressed: _rescheduleAppointment,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Color.fromARGB(255, 90, 113, 243),
                ),
                child: const Text(
                  "Reschedule Appointment",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mode selection UI
  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildModeOption("Physical", Icons.location_on),
        _buildModeOption("Online", Icons.video_call),
      ],
    );
  }

  Widget _buildModeOption(String mode, IconData icon) {
    bool isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          _fetchAvailableTimeSlots(); // Fetch slots when the mode changes
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 90, 113, 243)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 10)
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.black54, size: 30),
            const SizedBox(height: 10),
            Text(
              mode,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildCalendar(
    DateTime startDate, DateTime endDate, DateTime twoDaysBeforeOriginal) {
  // Ensure the initial date is valid based on the selectable predicate
  DateTime initialDate = DateTime.now().isAfter(twoDaysBeforeOriginal)
      ? DateTime.now()
      : twoDaysBeforeOriginal;

  return CalendarDatePicker(
    initialDate: initialDate,
    firstDate: startDate,
    lastDate: endDate,
    selectableDayPredicate: (date) {
      // Allow dates after or on twoDaysBeforeOriginal
      return date.isAfter(twoDaysBeforeOriginal) || date == twoDaysBeforeOriginal;
    },
    onDateChanged: (newSelectedDate) {
      if (newSelectedDate.isBefore(twoDaysBeforeOriginal)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "You must reschedule at least 2 days before the appointment."),
          ),
        );
        return;
      }

      setState(() {
        _selectedDate = newSelectedDate;
        isLoadingSlots = true;
        availableTimeSlots.clear();
      });

      _fetchAvailableTimeSlots();
    },
  );
}



  // Time slot selection widget
  Widget _buildTimeSlotSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Available Time"),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: availableTimeSlots.map((slot) {
            return ChoiceChip(
              label: Text(slot),
              selected: _selectedTimeSlot == slot,
              onSelected: (selected) {
                setState(() {
                  _selectedTimeSlot = selected ? slot : null;
                });
              },
              selectedColor: const Color.fromARGB(255, 90, 113, 243),
              labelStyle: TextStyle(
                color: _selectedTimeSlot == slot ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Section title widget
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 90, 113, 243)),
    );
  }

  // Section subtitle widget
  Widget _buildSectionSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: const TextStyle(fontSize: 14, color: Colors.black54),
    );
  }
}
