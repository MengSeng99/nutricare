import 'package:flutter/material.dart';

import 'appointment_details.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Removes the back button
          title: const Text(
            "Appointments",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF5A71F3),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50), // Height of TabBar
            child: Container(
              color: Colors.white, // White background for the tab container
              child: const TabBar(
                labelColor: Color(0xFF5A71F3), // Blue text color for selected tab
                unselectedLabelColor: Colors.grey, // Grey text color for unselected tab
                indicatorColor: Color.fromARGB(255, 78, 98, 215), // Blue indicator for selected tab
                indicatorWeight: 3,
                tabs: [
                  Tab(text: "Upcoming"),
                  Tab(text: "Past"),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            UpcomingAppointmentsTab(),
            PastAppointmentsTab(),
          ],
        ),
      ),
    );
  }
}

class UpcomingAppointmentsTab extends StatelessWidget {
  const UpcomingAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildAppointmentCard(
          context,
          date: "October 15, 2024",
          time: "10:00 AM - 11:00 AM",
          nutritionistName: "Dr. Sarah Johnson",
          appointmentStatus: "Confirmed",
          description: "Discuss weight loss goals and create a personalized meal plan.",
        ),
        _buildAppointmentCard(
          context,
          date: "October 20, 2024",
          time: "2:00 PM - 3:00 PM",
          nutritionistName: "Dr. Emily Davis",
          appointmentStatus: "Pending Confirmation",
          description: "Review current diet plan and discuss strategies for maintaining weight.",
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context, {
    required String date,
    required String time,
    required String nutritionistName,
    required String appointmentStatus,
    required String description,
  }) {
    return InkWell(
      onTap: () {
        // Navigate to appointment details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              date: date,
              time: time,
              nutritionistName: nutritionistName,
              description: description,
              status: appointmentStatus,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF5A71F3)),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B3B3B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF5A71F3)),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Nutritionist: $nutritionistName",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B3B3B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appointmentStatus,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: appointmentStatus == "Confirmed"
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              const Divider(height: 24, color: Colors.grey),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PastAppointmentsTab extends StatelessWidget {
  const PastAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildAppointmentCard(
          context,
          date: "September 25, 2024",
          time: "3:00 PM - 4:00 PM",
          nutritionistName: "Dr. Michael Lee",
          appointmentStatus: "Completed",
          description:
              "Reviewed progress and discussed changes to diet for weight management.",
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context, {
    required String date,
    required String time,
    required String nutritionistName,
    required String appointmentStatus,
    required String description,
  }) {
    return InkWell(
      onTap: () {
        // Navigate to appointment details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              date: date,
              time: time,
              nutritionistName: nutritionistName,
              description: description,
              status: appointmentStatus,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF5A71F3)),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B3B3B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF5A71F3)),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Nutritionist: $nutritionistName",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B3B3B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appointmentStatus,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const Divider(height: 24, color: Colors.grey),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
