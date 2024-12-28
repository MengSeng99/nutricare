import 'package:flutter/material.dart';
import 'package:nutricare/specialist_site/more/specialist_more.dart';
import 'package:nutricare/specialist_site/appointment_management/specialist_schedule.dart';
import 'package:nutricare/specialist_site/articles_management/specialist_articles.dart';
import '../admin_site/recipe_management/admin_recipe.dart';
import 'client_management/client.dart';

class SpecialistDashboard extends StatefulWidget {
  const SpecialistDashboard({super.key});

  @override
  _SpecialistDashboardState createState() => _SpecialistDashboardState();
}

class _SpecialistDashboardState extends State<SpecialistDashboard> {
  int _selectedIndex = 0; // Handle the selected index

  // Updated list of screens with 'AdminRecipeScreen' as the first one
  static const List<Widget> _screens = <Widget>[
    AdminRecipeScreen(),          // Recipes
    SpecialistArticlesScreen(),   // Articles
    SpecialistSchedulesScreen(),  // Schedule
    SpecialistClientScreen(),     // Client Screen
    SpecialistMoreScreen(),       // More
  ];

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
            Padding(
              padding: const EdgeInsets.only(bottom: 80), // Adjust for the height of the navigation bar
              child: _screens[_selectedIndex],
            ),
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
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
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
          duration: const Duration(milliseconds: 100), 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isSelected ? Color.fromARGB(255, 234, 234, 234).withOpacity(0.5) : Colors.transparent,
            border: Border(
              bottom: isSelected 
                  ? BorderSide(color: Color.fromARGB(255, 90, 113, 243), width: 2.0) 
                  : BorderSide.none,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 3.0), // Some padding for touch area
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                isSelected 
                    ? (
                       index == 0 ? Icons.food_bank_outlined : // Recipes icon
                       index == 1 ? Icons.article_outlined :
                       index == 2 ? Icons.calendar_month_outlined :
                       index == 3 ? Icons.people_outlined : // Client icon
                       Icons.more_horiz_outlined) 
                    : (
                       index == 0 ? Icons.food_bank : // Recipes icon
                       index == 1 ? Icons.article :
                       index == 2 ? Icons.calendar_month :
                       index == 3 ? Icons.people :
                       Icons.more_horiz), 
                color: iconColor,
                size: 30, // Icon size
              ),
              const SizedBox(height: 4), // Space between icon and text
              Text(
                index == 0 ? 'Recipes' : // Updated label for Recipes
                index == 1 ? 'Articles' :
                index == 2 ? 'Schedule' :
                index == 3 ? 'Client' : // Label for the Client option
                'More',
                style: TextStyle(
                  color: iconColor, 
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}