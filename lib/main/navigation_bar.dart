import 'package:flutter/material.dart';
import 'package:nutricare/scheduled_appointment/chat_list.dart';
import 'home.dart'; // Import Home screen
import '../diet_tracker/diets.dart'; // Import Diets screen
import '../scheduled_appointment/schedule.dart'; // Import Schedule screen
import 'more.dart'; // Import More screen

class MainScreen extends StatefulWidget {
  final int initialIndex;

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
    HomeScreen(),
    DietsScreen(),
    ScheduleScreen(),
    ChatListScreen(),
    MoreScreen(),
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
      body: SafeArea(
        child: Stack(
          children: [
            // Main screen content
            Padding(
              padding: const EdgeInsets.only(bottom: 80), // Adjust for the height of the navigation bar
              child: _screens[_selectedIndex],
            ),

            // Floating Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCustomNavigationBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavigationBar() {
    return Container(
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Color.fromRGBO(255, 255, 255, 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: Offset(0, -2), // Shadow above the bar
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_screens.length, (index) {
          return _buildNavItem(index);
        }),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    final iconColor = isSelected 
        ? Color.fromARGB(255, 79, 105, 255) 
        : const Color.fromARGB(255, 136, 136, 136); // Color for selected/unselected

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 100), 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            // Optionally, add a background color when selected
            color: isSelected ? Color.fromARGB(255, 234, 234, 234).withOpacity(0.5) : Colors.transparent,
            border: Border(
              bottom: isSelected 
                  ? BorderSide(color: Color.fromARGB(255, 90, 113, 243), width: 2.0) 
                  : BorderSide.none,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 3.0), 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, 
            children: <Widget>[
              Icon(
                isSelected 
                    ? (index == 0 ? Icons.home_outlined :
                       index == 1 ? Icons.food_bank_outlined :
                       index == 2 ? Icons.calendar_month_outlined :
                       index == 3 ? Icons.chat_outlined : 
                       Icons.more_horiz_outlined) 
                    : (index == 0 ? Icons.home :
                       index == 1 ? Icons.food_bank :
                       index == 2 ? Icons.calendar_month :
                       index == 3 ? Icons.chat : 
                       Icons.more_horiz),
                color: iconColor,
                size: 30, // Icon size
              ),
              SizedBox(height: 5), 
              Text(
                index == 0 ? 'Home' :
                index == 1 ? 'Diets' :
                index == 2 ? 'Schedule' :
                index == 3 ? 'Messages' : // Text for new Messages tab
                'More',
                style: TextStyle(
                  color: iconColor, // Keep icon color for text
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center, // Center the text
              ),
            ],
          ),
        ),
      ),
    );
  }
}
