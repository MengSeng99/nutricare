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
  bool noAvailableTimeSlots = false;

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
        .doc(_selectedMode);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data['date_slots'] != null) {
        final dateSlots = Map<String, dynamic>.from(data['date_slots']);
        List<String> slots =
            List<String>.from(dateSlots[selectedDateString] ?? []);

        // Sort time slots manually: AM first, then PM
        slots.sort((a, b) {
          return _compareTimeSlots(a, b);
        });

        setState(() {
          availableTimeSlots = slots;
          noAvailableTimeSlots = slots.isEmpty; // Track if there are no slots
          isLoadingSlots = false;
        });
      }
    } else {
      setState(() {
        availableTimeSlots = [];
        noAvailableTimeSlots = true; // Track as no slots available
        isLoadingSlots = false;
      });
    }
  }

  int _compareTimeSlots(String a, String b) {
    // Parse time strings into DateTime objects (using a fixed date)
    final timeA = DateTime.parse("2000-01-01 $a");
    final timeB = DateTime.parse("2000-01-01 $b");

    // Compare the DateTime objects
    return timeA.compareTo(timeB);
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
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissal of dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(), // Loading indicator
              SizedBox(width: 20), // Add some spacing
              Text("Processing, please wait..."), // Loading message
            ],
          ),
        );
      },
    );

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

      Navigator.pop(context); // Go back after rescheduling

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Appointment successfully rescheduled to $_selectedMode on ${DateFormat('yyyy-MM-dd').format(_selectedDate!)} at $_selectedTimeSlot.'),
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
        List<String> timeSlots =
            List<String>.from(dateSlots[selectedDateString] ?? []);

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
    final originalDateString =
        widget.originalDate.toIso8601String().split('T')[0];

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
        if (!List<String>.from(dateSlots[originalDateString])
            .contains(widget.originalTime)) {
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
      QuerySnapshot chatSnapshot =
          await FirebaseFirestore.instance.collection('chats').get();
      bool chatFound = false;
      String? chatId;

      // Iterate through each document in the chats collection
      for (var chat in chatSnapshot.docs) {
        List<dynamic> users = chat['users'] ?? [];

        // Check if both the currentUserId and specialistId are in the users array
        if (users.contains(currentUserId) &&
            users.contains(widget.specialistId)) {
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
        DocumentReference newChatDoc =
            await FirebaseFirestore.instance.collection('chats').add({
          'users': [currentUserId, widget.specialistId],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Send message with appointment details
        await _sendRescheduleMessage(newChatDoc.id);
      }
    } catch (e) {
      // print('Error checking chat session and creating message: $e');
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
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': messageText,
      'senderId': widget.specialistId, // Set the sender ID to specialist ID
      'isImage': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime endDate = now.add(const Duration(days: 30));

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
            // Original Appointment Details Modernized
            _buildSectionTitle("Original Appointment Details"),
            const SizedBox(height: 16), // Adding spacing

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: widget.appointmentMode == "Physical"
                        ? const Icon(Icons.people_alt_outlined,
                            color: Color.fromARGB(255, 90, 113, 243))
                        : const Icon(Icons.video_call_outlined,
                            color: Color.fromARGB(255, 90, 113, 243)),
                    title: Text(
                      "Original Appointment Mode: ${widget.appointmentMode}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Divider(), // Adds a divider between items
                  ListTile(
                    leading: const Icon(Icons.date_range,
                        color: Color.fromARGB(255, 90, 113, 243)),
                    title: Text(
                      "Original Date: ${DateFormat('yyyy-MM-dd').format(widget.originalDate)}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.access_time,
                        color: Color.fromARGB(255, 90, 113, 243)),
                    title: Text(
                      "Original Timeslot: ${widget.originalTime}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appointment Mode
            _buildSectionTitle("Appointment Mode"),
            const SizedBox(height: 10),
            _buildModeSelector(),
            const SizedBox(height: 24),

            // Calendar for selecting date
            _buildSectionTitle("Select Reschedule Date"),
            _buildSectionSubtitle(
                "You can select any date within 1 month starting from today (Excluding weekends)."),
            const SizedBox(height: 12),
            _buildCalendar(now, endDate),

            // Time slots section
            if (_selectedDate !=
                null) // Show time slots only if date is selected
              _buildTimeSlotSelector(), // Will automatically show empty if no slots

            // Show message if no available time slots
            if (noAvailableTimeSlots)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "No available time slots for the selected date. Please select another date.",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: (_selectedDate != null &&
                        _selectedTimeSlot != null &&
                        !noAvailableTimeSlots)
                    ? _showConfirmationDialog // Change to show confirmation dialog
                    : null,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: (_selectedDate != null &&
                          _selectedTimeSlot != null &&
                          !noAvailableTimeSlots)
                      ? const Color.fromARGB(255, 90, 113, 243)
                      : Colors.grey,
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

  Widget _buildCalendar(DateTime startDate, DateTime endDate) {
    // Go to the next weekday if the start date is Saturday or Sunday
    DateTime effectiveStartDate = startDate;
    if (effectiveStartDate.weekday == DateTime.saturday) {
      effectiveStartDate = effectiveStartDate.add(Duration(days: 2));
    } else if (effectiveStartDate.weekday == DateTime.sunday) {
      effectiveStartDate = effectiveStartDate.add(Duration(days: 1));
    }

    return CalendarDatePicker(
      initialDate: effectiveStartDate, // Ensure this is a valid starting point
      firstDate: startDate,
      lastDate: endDate,
      selectableDayPredicate: (date) {
        // Allow only weekdays (Monday to Friday)
        return date.weekday != DateTime.saturday &&
            date.weekday != DateTime.sunday;
      },
      onDateChanged: (newSelectedDate) {
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
              backgroundColor: Colors.white,
              label: Text(slot),
              side: BorderSide(
                color: Colors.grey,
                width: 1,
              ),
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

  Future<void> _showConfirmationDialog() async {
  final bool? shouldReschedule = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "Confirm Reschedule",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Original Appointment Card
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Original Appointment Details:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Use appropriate icon based on appointment mode
                        Icon(widget.appointmentMode == "Physical"
                            ? Icons.location_on
                            : Icons.video_call_outlined,
                          color: Color.fromARGB(255, 90, 113, 243)),
                        const SizedBox(width: 8),
                        Text("Mode: ${widget.appointmentMode}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.date_range, color: Color.fromARGB(255, 90, 113, 243)),
                        const SizedBox(width: 8),
                        Text("Date: ${DateFormat('yyyy-MM-dd').format(widget.originalDate)}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Color.fromARGB(255, 90, 113, 243)),
                        const SizedBox(width: 8),
                        Text("Time: ${widget.originalTime}"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Arrow Icon
            const Icon(
              Icons.arrow_downward,
              size: 30,
              color: Color.fromARGB(255, 90, 113, 243),
            ),

            const SizedBox(height: 20),

            // New Appointment Card
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "New Appointment Details:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Use appropriate icon based on selected mode
                        Icon(_selectedMode == "Physical"
                            ? Icons.location_on
                            : Icons.video_call_outlined,
                          color: Color.fromARGB(255, 90, 113, 243)),
                        const SizedBox(width: 8),
                        Text("Mode: $_selectedMode"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.date_range, color: Color.fromARGB(255, 90, 113, 243)),
                        const SizedBox(width: 8),
                        Text("Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now())}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Color.fromARGB(255, 90, 113, 243)),
                        const SizedBox(width: 8),
                        Text("Time: $_selectedTimeSlot"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 90, 113, 243),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Confirm",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );

  // Proceed with rescheduling if confirmed
  if (shouldReschedule == true) {
    await _rescheduleAppointment(); // Call the original reschedule method
  }
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
