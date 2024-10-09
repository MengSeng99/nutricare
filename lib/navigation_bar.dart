import 'package:flutter/material.dart';
import 'home.dart'; // Import Home screen
import 'diets.dart'; // Import Diets screen
import 'schedule.dart'; // Import Activity screen
import 'more.dart'; // Import More screen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of screens for each navigation item
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),   // Home screen
    DietsScreen(),  // Diets screen
    ScheduleScreen(), // Activity screen
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
            label: 'Home', // Add text label "Home"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank),
            label: 'Diets', // Add text label "Diets"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Schedule', // Add text label "Activity"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More', // Add text label "More"
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 90, 113, 243),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
        //showUnselectedLabels: true, // Show labels for unselected items
      ),
    );
  }
}
