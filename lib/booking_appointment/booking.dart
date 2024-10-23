import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutricare/booking_appointment/payment.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  final String specialistName;
  final String specialistId; // Added specialistId to fetch data

  const BookingScreen({super.key, required this.specialistName, required this.specialistId});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  TabController? _tabController;

  List<String> availableTimeSlots = [];
  String? selectedTimeSlot;
  String _selectedMode = 'Physical'; // Default appointment mode

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch initial data for the default mode
    _fetchAvailableTimeSlots();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableTimeSlots() async {
    final selectedDateString = _selectedDay.toIso8601String().split('T')[0];

    final docRef = FirebaseFirestore.instance
        .collection('specialists')
        .doc(widget.specialistId)
        .collection('appointments')
        .doc(_selectedMode); // Fetch either 'physical' or 'online' document based on selected mode

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data['date_slots'] != null) {
        final dateSlots = Map<String, dynamic>.from(data['date_slots']);
        setState(() {
          availableTimeSlots = List<String>.from(dateSlots[selectedDateString] ?? []);
        });
      }
    } else {
      setState(() {
        availableTimeSlots = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Booking Details",
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
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
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppointmentModeTabs(context),
              const SizedBox(height: 20),
              _buildCalendar(),
              const SizedBox(height: 20),
              _buildColorDescriptions(),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  "Time Slots",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              _buildTimeSlotSelection(),
              const SizedBox(height: 20),
              _buildSelectButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 34, 34, 34).withOpacity(.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 30)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _fetchAvailableTimeSlots(); // Fetch time slots when a new date is selected
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: const Color.fromARGB(255, 33, 82, 243),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color.fromARGB(255, 135, 136, 137),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildColorDescriptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _ColorDescriptionBox(color: Color.fromARGB(255, 135, 136, 137), description: 'Today'),
        _ColorDescriptionBox(color: Color.fromARGB(255, 33, 82, 243), description: 'Selected Date'),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
  // Check if availableTimeSlots is empty
  if (availableTimeSlots.isEmpty) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'The day you selected has no time slots available.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), // Style for the warning message
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2), // Add some spacing
          Text(
            'Please select a different day.',
            style: TextStyle(color: Colors.black54), // Style for the reminder
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // If time slots are available, display them as ChoiceChips
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: availableTimeSlots.map((timeSlot) {
        final isSelected = selectedTimeSlot == timeSlot;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ChoiceChip(
            label: Text(
              timeSlot,
              style: TextStyle(color: isSelected ? Colors.white : Colors.grey[800]),
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                selectedTimeSlot = selected ? timeSlot : null;
              });
            },
            selectedColor: const Color.fromARGB(255, 33, 82, 243),
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

  Widget _buildAppointmentModeTabs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color.fromARGB(255, 90, 113, 243),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _selectedMode = index == 0 ? 'Physical' : 'Online';
                _fetchAvailableTimeSlots(); // Fetch time slots based on the selected mode
              });
            },
            tabs: const [
              Tab(text: 'Physical'),
              Tab(text: 'Online'),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.grey),
          onPressed: () {
            _showModeInfoDialog(context);
          },
        ),
      ],
    );
  }

  void _showModeInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Appointment Modes"),
          content: const Text(
              "Physical Appointment: \nPlease arrive at the clinic 30 minutes before your scheduled time.\n\n"
              "Online Appointment: \nYou will receive a virtual consultation at the scheduled time."),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectButton() {
    return Center(
      child: ElevatedButton(
        onPressed: selectedTimeSlot != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      selectedDate: _selectedDay,
                      selectedTimeSlot: selectedTimeSlot,
                      specialistName: widget.specialistName,
                      specialistId: widget.specialistId,
                      appointmentMode: _selectedMode,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 90, 113, 243),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Select",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class _ColorDescriptionBox extends StatelessWidget {
  final Color color;
  final String description;

  const _ColorDescriptionBox({required this.color, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        ),
        const SizedBox(width: 14),
        Text(description, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
