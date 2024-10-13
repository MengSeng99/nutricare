import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'client_info.dart';

class BookingScreen extends StatefulWidget {
   final String specialistName;
  
  const BookingScreen({super.key, required this.specialistName});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  TabController? _tabController;

  final List<String> availableTimeSlots = [
    '9:00 AM',
    '11:00 AM',
    '12:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  String? selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Booking Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
              const SizedBox(height: 30),
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
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
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
            indicatorColor: const Color.fromARGB(255, 33, 82, 243),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
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
                    builder: (context) => ClientInfoScreen(
                      selectedDate: _selectedDay,
                      selectedTimeSlot: selectedTimeSlot,
                      specialistName: widget.specialistName,
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
