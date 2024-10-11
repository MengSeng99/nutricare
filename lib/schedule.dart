import 'package:flutter/material.dart';
import 'appointment_details.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Schedule",
            style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold, fontSize: 22),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: TabBar(
              labelColor: Color(0xFF5A71F3),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color.fromARGB(255, 78, 98, 215),
              indicatorWeight: 3,
              tabs: [
                Tab(text: "Upcoming"),
                Tab(text: "Completed"),
                Tab(text: "Canceled"),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            UpcomingAppointmentsTab(),
            PastAppointmentsTab(),
            CanceledAppointmentsTab(),
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
          time: "10:00 AM",
          nutritionistName: "Dr. Sarah Johnson",
          appointmentStatus: "Confirmed",
          description: "Discuss weight loss goals and create a personalized meal plan.",
          showButtons: true,
        ),
        _buildAppointmentCard(
          context,
          date: "October 20, 2024",
          time: "2:00 PM",
          nutritionistName: "Dr. Emily Davis",
          appointmentStatus: "Pending Confirmation",
          description: "Review current diet plan and discuss strategies for maintaining weight.",
          showButtons: true,
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
    required bool showButtons,
  }) {
    return InkWell(
      onTap: () {
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
        color: Colors.white, // Set card background to white
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    radius: 30,
                    child: Text(
                      nutritionistName.split(" ").first[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nutritionistName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: appointmentStatus == "Confirmed"
                                  ? Colors.green
                                  : appointmentStatus == "Pending Confirmation"
                                      ? Colors.orange
                                      : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              appointmentStatus,
                              style: TextStyle(
                                color: appointmentStatus == "Confirmed"
                                    ? Colors.green
                                    : appointmentStatus == "Pending Confirmation"
                                        ? Colors.orange
                                        : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$date | $time",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6D6D6D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.grey),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6D6D6D),
                ),
              ),
              if (showButtons) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Implement the cancel appointment functionality here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 232, 235, 247), // Grey background
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Color.fromARGB(255, 59, 59, 59), fontSize: 16), // Black text
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Implement the reschedule functionality here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 90, 113, 243), // Blue background
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Reschedule",
                        style: TextStyle(color: Colors.white, fontSize: 16), // White text
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// For Completed and Canceled tabs
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
          time: "3:00 PM",
          nutritionistName: "Dr. Michael Lee",
          appointmentStatus: "Completed",
          description:
              "Reviewed progress and discussed changes to diet for weight management.",
          showButtons: false, // Hide buttons for completed appointments
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
    required bool showButtons,
  }) {
    return UpcomingAppointmentsTab()._buildAppointmentCard(
      context,
      date: date,
      time: time,
      nutritionistName: nutritionistName,
      appointmentStatus: appointmentStatus,
      description: description,
      showButtons: showButtons,
    );
  }
}

class CanceledAppointmentsTab extends StatelessWidget {
  const CanceledAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildAppointmentCard(
          context,
          date: "October 10, 2024",
          time: "4:00 PM",
          nutritionistName: "Dr. John Doe",
          appointmentStatus: "Canceled",
          description:
              "Initial consultation was canceled due to scheduling conflicts.",
          showButtons: false, // Hide buttons for canceled appointments
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
    required bool showButtons,
  }) {
    return UpcomingAppointmentsTab()._buildAppointmentCard(
      context,
      date: date,
      time: time,
      nutritionistName: nutritionistName,
      appointmentStatus: appointmentStatus,
      description: description,
      showButtons: showButtons,
    );
  }
}
