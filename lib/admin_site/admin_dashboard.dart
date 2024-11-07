import 'package:flutter/material.dart';
import 'appointment_management/admin_appointment.dart';
import 'admin_settings.dart';
import 'articles_management/admin_articles.dart';
import 'recipe_management/admin_recipe.dart';
import 'specialist_management/admin_specialist.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // Handle the selected index

  // Add the Settings screen to the list of screens
  static const List<Widget> _screens = <Widget>[
    AdminRecipeScreen(), 
    AdminSpecialistsScreen(), 
    AdminArticlesScreen(),
    AdminAppointmentScreen(),
    AdminSettingsScreen(), // New settings screen
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
                    ? (index == 0 ? Icons.receipt_outlined :
                       index == 1 ? Icons.person_outlined :
                       index == 2 ? Icons.article_outlined :
                       index == 3 ? Icons.event_outlined : // Appointments
                       Icons.settings_outlined) // Settings
                    : (index == 0 ? Icons.receipt :
                       index == 1 ? Icons.person :
                       index == 2 ? Icons.article :
                       index == 3 ? Icons.event :
                       Icons.settings), // Settings
                color: iconColor,
                size: 30, // Icon size
              ),
              const SizedBox(height: 4), // Space between icon and text
              Text(
                index == 0 ? 'Recipe' :
                index == 1 ? 'Specialist' :
                index == 2 ? 'Articles' :
                index == 3 ? 'Appointment' : // Appointments
                'Settings', // Settings
                style: TextStyle(
                  color: iconColor, 
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
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

// Placeholder screens for navigation (You need to create these as separate widgets).
class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Recipe Screen'));
  }
}

class SpecialistScreen extends StatelessWidget {
  const SpecialistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Specialist Screen'));
  }
}

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Articles Screen'));
  }
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Appointments Screen'));
  }
}