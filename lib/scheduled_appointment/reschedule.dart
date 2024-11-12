import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RescheduleScreen extends StatefulWidget {
  final String appointmentId;
  final String specialistId;
  final String appointmentMode;
  final DateTime originalDate;
  final String originalTime;
  final String specialistName;
  final Function onRefresh;

  const RescheduleScreen({
    required this.appointmentId,
    required this.specialistId,
    required this.appointmentMode,
    required this.originalDate,
    required this.originalTime,
    required this.specialistName,
    required this.onRefresh,
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
    _selectedMode = widget.appointmentMode; // Set the initial mode
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
      List<String> slots = List<String>.from(dateSlots[selectedDateString] ?? []);

      // Sort time slots manually: AM first, then PM
      slots.sort((a, b) {
        return _compareTimeSlots(a, b);
      });

      setState(() {
        availableTimeSlots = slots;
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

int _compareTimeSlots(String a, String b) {
  // Extract AM/PM and time parts
  final ampmA = a.split(' ').last; // Get AM or PM
  final ampmB = b.split(' ').last;

  // If both are AM, compare times directly
  if (ampmA == 'AM' && ampmB == 'AM') {
    return a.compareTo(b);
  }
  // If both are PM, compare times directly
  else if (ampmA == 'PM' && ampmB == 'PM') {
    return a.compareTo(b);
  }
  // If one is AM and the other is PM, place AM before PM
  else {
    return ampmA == 'AM' ? -1 : 1; // AM comes before PM
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

  // Reference to the details collection
  final detailsCollectionRef = FirebaseFirestore.instance
      .collection('appointments')
      .doc(widget.appointmentId)
      .collection('details');

  // Fetch the details document
  final detailsSnapshot = await detailsCollectionRef.get();

  // Check if there are any documents in the details collection
  if (detailsSnapshot.docs.isNotEmpty) {
    // Update the first document in the details collection
    DocumentReference detailDocRef = detailsSnapshot.docs.first.reference;

    await detailDocRef.update({
      'appointmentMode': _selectedMode,
      'selectedDate': _selectedDate,
      'selectedTimeSlot': _selectedTimeSlot,
      'appointmentStatus': 'Confirmed',
    });

    // Call onRefresh after successful reschedule
    widget.onRefresh();

    // Check for chat and send a message about rescheduling
    await _checkForChatAndCreateMessage();

    // Add the original date and time slot back into Firebase Firestore
    await _addOriginalDateAndTimeSlot();

    // Remove the newly selected time slot from the date_slots
    await _removeNewSelectedTimeSlot();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment successfully rescheduled to $_selectedMode on ${DateFormat('yyyy-MM-dd').format(_selectedDate!)} at $_selectedTimeSlot.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context); // Go back after rescheduling
  } else {
    // Handle case when there are no detail documents
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No appointment details found."),
      ),
    );
  }
}

Future<void> _removeNewSelectedTimeSlot() async {
  // Prepare the selected date string
  final selectedDateString = _selectedDate!.toIso8601String().split('T')[0];

  // Reference to the date slots collection for the specialist
  final docRef = FirebaseFirestore.instance
      .collection('specialists')
      .doc(widget.specialistId)
      .collection('appointments')
      .doc(_selectedMode); // Fetch based on selected mode

  // Fetch the document
  final docSnapshot = await docRef.get();

  if (docSnapshot.exists) {
    final data = docSnapshot.data();
    final dateSlots = Map<String, dynamic>.from(data?['date_slots'] ?? {});

    // Check if the selected date exists
    if (dateSlots.containsKey(selectedDateString)) {
      List<String> timeSlots = List<String>.from(dateSlots[selectedDateString] ?? []);

      // Remove the selected time slot from the date's time slots
      timeSlots.remove(_selectedTimeSlot);

      // If the timeslots array is empty, remove the date entry
      if (timeSlots.isEmpty) {
        dateSlots.remove(selectedDateString);
      } else {
        // Update the time slots for that date
        dateSlots[selectedDateString] = timeSlots;
      }

      // Update Firestore document with the modified date slots
      await docRef.update({'date_slots': dateSlots});
    }
  }
}
Future<void> _addOriginalDateAndTimeSlot() async {
  // Prepare the original date string
  final originalDateString = widget.originalDate.toIso8601String().split('T')[0];

  // Reference to the date slots collection for the specialist
  final docRef = FirebaseFirestore.instance
      .collection('specialists')
      .doc(widget.specialistId)
      .collection('appointments')
      .doc(_selectedMode); // Fetch based on selected mode

  // Fetch the document
  final docSnapshot = await docRef.get();

  // If the document exists
  if (docSnapshot.exists) {
    final data = docSnapshot.data();
    final dateSlots = Map<String, dynamic>.from(data?['date_slots'] ?? {});

    // Check if the original date exists
    if (dateSlots.containsKey(originalDateString)) {
      // Check if the timeslot already exists
      if (!List<String>.from(dateSlots[originalDateString]).contains(widget.originalTime)) {
        // Add the original time slot to the existing date
        dateSlots[originalDateString].add(widget.originalTime);
      }
    } else {
      // If the date does not exist, create it and add the original time slot
      dateSlots[originalDateString] = [widget.originalTime];
    }

    // Update Firestore with the updated date slots
    await docRef.update({'date_slots': dateSlots});
  }
}

  Future<void> _checkForChatAndCreateMessage() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Get the reference to the chats collection
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance.collection('chats').get();
      bool chatFound = false;
      String? chatId;

      // Iterate through each document in the chats collection
      for (var chat in chatSnapshot.docs) {
        List<dynamic> users = chat['users'] ?? [];

        // Check if both the currentUserId and specialistId are in the users array
        if (users.contains(currentUserId) && users.contains(widget.specialistId)) {
          chatFound = true;
          chatId = chat.id;

          // Send message with appointment details
          await _sendRescheduleMessage(chatId);
          return; // Exit the function after sending the message
        }
      }

      // If no chat session is found, create a new chat
      if (!chatFound) {
        // Create a new chat document
        DocumentReference newChatDoc = await FirebaseFirestore.instance.collection('chats').add({
          'users': [currentUserId, widget.specialistId],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Send message with appointment details
        await _sendRescheduleMessage(newChatDoc.id);
      }
    } catch (e) {
      print('Error checking chat session and creating message: $e');
    }
  }

  Future<void> _sendRescheduleMessage(String chatId) async {
    // Prepare the success message for reschedule confirmation
    String messageText = '''
Your appointment has been successfully rescheduled!

New Appointment Details:
- Appointment ID: ${widget.appointmentId}
- Specialist: Dr. ${widget.specialistName}
- Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}
- Time: $_selectedTimeSlot
- Mode: $_selectedMode
- Status: Confirmed

Please review the details above and let us know if you spot any errors.
''';

    // Send the message to Firestore
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
      'text': messageText,
      'senderId': widget.specialistId, // Set the sender ID to specialist ID
      'isImage': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
Widget build(BuildContext context) {
  DateTime now = DateTime.now();
  DateTime twoDaysBeforeOriginal = widget.originalDate.subtract(const Duration(days: 2));
  DateTime endDate = now.add(const Duration(days: 30)); // End date is 30 days from now

  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text(
        "Reschedule Appointment",
        style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 0.5, color: Color.fromARGB(255, 220, 220, 241)),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Original Appointment Details"),
          Text(
            "Original Appointment Mode: ${widget.appointmentMode}",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Text(
            "Original Date: ${DateFormat('yyyy-MM-dd').format(widget.originalDate)}",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Text(
            "Original Timeslots: ${widget.originalTime}",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          
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
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Color.fromARGB(255, 90, 113, 243),
              ),
              child: const Text(
                "Reschedule Appointment",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
          color: isSelected ? const Color.fromARGB(255, 90, 113, 243) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 1, blurRadius: 10)] : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54, size: 30),
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

  Widget _buildCalendar(DateTime startDate, DateTime endDate, DateTime twoDaysBeforeOriginal) {
    DateTime initialDate = DateTime.now().isAfter(twoDaysBeforeOriginal) ? DateTime.now() : twoDaysBeforeOriginal;

    return CalendarDatePicker(
      initialDate: initialDate,
      firstDate: startDate,
      lastDate: endDate,
      selectableDayPredicate: (date) {
        return date.isAfter(twoDaysBeforeOriginal) || date == twoDaysBeforeOriginal;
      },
      onDateChanged: (newSelectedDate) {
        if (newSelectedDate.isBefore(twoDaysBeforeOriginal)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You must reschedule at least 2 days before the appointment."),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 90, 113, 243),
      ),
    );
  }

  Widget _buildSectionSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: const TextStyle(fontSize: 14, color: Colors.black54),
    );
  }
}