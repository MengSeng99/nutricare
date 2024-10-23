import 'package:flutter/material.dart';
import 'home.dart'; // Import Home screen
import '../diet_tracker/diets.dart'; // Import Diets screen
import '../scheduled_appointment/schedule.dart'; // Import Activity screen
import 'more.dart'; // Import More screen

class MainScreen extends StatefulWidget {
  final int initialIndex; // Add this parameter to pass the index

  const MainScreen({super.key, this.initialIndex = 0}); // Default is 0 (Home)

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Initialize with passed index
  }

  // List of screens for each navigation item
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),   // Home screen
    DietsScreen(),  // Diets screen
    ScheduleScreen(), // Schedule screen
    MoreScreen(),   // More screen
  ];

  // Function to handle navigation tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display selected screen
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank),
            label: 'Diets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 90, 113, 243),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
