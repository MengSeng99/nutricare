import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'client_info.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  final List<String> availableTimeSlots = [
    '9:00 AM',
    '11:00 AM',
    '2:00 PM',
    '4:00 PM',
  ];

  String? selectedTimeSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Date & Time Slot",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const Text(
                "Select an available date:",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildCalendar(),
              const SizedBox(height: 20),
              _buildColorDescriptions(),
              const SizedBox(height: 30),
              const Text(
                "Select an available time slot:",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 1,
            offset: const Offset(0, 1),
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
            color: const Color.fromARGB(255, 90, 113, 243),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerSize: 5.0,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: const TextStyle(fontWeight: FontWeight.bold),
          weekendStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        calendarFormat: CalendarFormat.month,
      ),
    );
  }

  Widget _buildColorDescriptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _ColorDescriptionBox(color: Color.fromARGB(255, 90, 113, 243), description: 'Today'),
        _ColorDescriptionBox(color: Color.fromARGB(255, 33, 82, 243), description: 'Selected Date'),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    return Wrap(
      spacing: 15,
      children: availableTimeSlots.map((timeSlot) {
        final isSelected = selectedTimeSlot == timeSlot;

        return ChoiceChip(
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
            borderRadius: BorderRadius.circular(30),
          ),
        );
      }).toList(),
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
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 90, 113, 243),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Center(
          child: Text(
            "Select",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
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
          width: 15,
          height: 15,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        ),
        const SizedBox(width: 14),
        Text(description, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
