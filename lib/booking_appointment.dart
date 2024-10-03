import 'package:flutter/material.dart';

class Specialist {
  final String name;
  final String specialization;
  final String organization;
  final String earliestTimeSlot;
  final String profilePictureUrl;
  bool isFavorite;

  Specialist({
    required this.name,
    required this.specialization,
    required this.organization,
    required this.earliestTimeSlot,
    required this.profilePictureUrl,
    this.isFavorite = false,
  });
}

class BookingAppointmentScreen extends StatefulWidget {
  final String title;

  const BookingAppointmentScreen({super.key, required this.title});

  @override
  _BookingAppointmentScreenState createState() => _BookingAppointmentScreenState();
}

class _BookingAppointmentScreenState extends State<BookingAppointmentScreen> {
  // To control the visibility of the filter options
  bool _showFilters = false;

  // To track selected filter options
  final Set<String> _selectedProfessionalPreferences = {};
  final Set<String> _selectedAvailability = {};

  // Sample data for specialists
  final List<Specialist> specialists = [
    Specialist(
      name: 'Dr. John Doe',
      specialization: 'Nutritionist',
      organization: 'HealthCare Inc.',
      earliestTimeSlot: '10:00 AM',
      profilePictureUrl: 'https://hips.hearstapps.com/hmg-prod/images/portrait-of-a-happy-young-doctor-in-his-clinic-royalty-free-image-1661432441.jpg',
    ),
    Specialist(
      name: 'Dr. Jane Smith',
      specialization: 'Dietitian',
      organization: 'Wellness Center',
      earliestTimeSlot: '11:00 AM',
      profilePictureUrl: 'https://images.theconversation.com/files/304957/original/file-20191203-66986-im7o5.jpg?ixlib=rb-4.1.0&q=45&auto=format&w=926&fit=clip',
    ),
    // Add more specialists as needed
  ];

  // Build the filter options section
  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close Button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showFilters = false; // Close the filter menu
                });
              },
            ),
          ),
          const SizedBox(height: 10), // Space below close button
          // Medical Professional Preference
          const Text(
            'Medical Professional Preference:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              _buildFilterChip(
                label: 'Male',
                selected: _selectedProfessionalPreferences.contains('Male'),
                onSelected: (selected) {
                  setState(() {
                    selected
                        ? _selectedProfessionalPreferences.add('Male')
                        : _selectedProfessionalPreferences.remove('Male');
                  });
                },
              ),
              const SizedBox(width: 10),
              _buildFilterChip(
                label: 'Female',
                selected: _selectedProfessionalPreferences.contains('Female'),
                onSelected: (selected) {
                  setState(() {
                    selected
                        ? _selectedProfessionalPreferences.add('Female')
                        : _selectedProfessionalPreferences.remove('Female');
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between sections
          // Availability options
          const Text(
            'Availability:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 10.0, // Space between chips
            children: [
              _buildFilterChip(
                label: 'Today',
                selected: _selectedAvailability.contains('Today'),
                onSelected: (selected) {
                  setState(() {
                    selected ? _selectedAvailability.add('Today') : _selectedAvailability.remove('Today');
                  });
                },
              ),
              _buildFilterChip(
                label: 'Tomorrow',
                selected: _selectedAvailability.contains('Tomorrow'),
                onSelected: (selected) {
                  setState(() {
                    selected ? _selectedAvailability.add('Tomorrow') : _selectedAvailability.remove('Tomorrow');
                  });
                },
              ),
              _buildFilterChip(
                label: 'Weekday',
                selected: _selectedAvailability.contains('Weekday'),
                onSelected: (selected) {
                  setState(() {
                    selected ? _selectedAvailability.add('Weekday') : _selectedAvailability.remove('Weekday');
                  });
                },
              ),
              _buildFilterChip(
                label: 'Saturday',
                selected: _selectedAvailability.contains('Saturday'),
                onSelected: (selected) {
                  setState(() {
                    selected ? _selectedAvailability.add('Saturday') : _selectedAvailability.remove('Saturday');
                  });
                },
              ),
              _buildFilterChip(
                label: 'Sunday',
                selected: _selectedAvailability.contains('Sunday'),
                onSelected: (selected) {
                  setState(() {
                    selected ? _selectedAvailability.add('Sunday') : _selectedAvailability.remove('Sunday');
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space before action buttons
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Reset all selected filters
                    _selectedProfessionalPreferences.clear();
                    _selectedAvailability.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White background for Reset button
                  side: const BorderSide(color: Color.fromARGB(255, 90, 113, 243)), // Blue border
                ),
                child: const Text('Reset', style: TextStyle(color: Color.fromARGB(255, 90, 113, 243))),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply filter logic here if needed
                  setState(() {
                    _showFilters = false; // Close filter menu after applying
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 90, 113, 243), // Blue background
                ),
                child: const Text('Apply', style: TextStyle(color: Colors.white)), // White font color
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build custom filter chip
  Widget _buildFilterChip({required String label, required bool selected, required Function(bool) onSelected}) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : Colors.black), // White text if selected
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: const Color.fromARGB(255, 90, 113, 243), // Blue color when selected
      backgroundColor: Colors.grey[200],
    );
  }

  // Build the list of specialists
  Widget _buildSpecialistList() {
    return ListView.builder(
      itemCount: specialists.length,
      itemBuilder: (context, index) {
        final specialist = specialists[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
          color: Colors.white, // Set the background color to white
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color.fromARGB(255, 218, 218, 218)), // Add grey border
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(specialist.profilePictureUrl),
            ),
            title: Text(specialist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(specialist.specialization),
                Text(specialist.organization),
                Text('Earliest Time Slot: ${specialist.earliestTimeSlot}'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                specialist.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: specialist.isFavorite ? Colors.blue : null,
              ),
              onPressed: () {
                setState(() {
                  specialist.isFavorite = !specialist.isFavorite;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      specialist.isFavorite
                          ? 'Successfully added to favorites.'
                          : 'Successfully removed from favorites.',
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String placeholder = widget.title; // Placeholder text based on title
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white, // Set the background color to white
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field with Filter Button to the right
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search $placeholder',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.white, // White background for search field
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      icon: Icon(
                        Icons.filter_list,
                        color: _showFilters
                            ? const Color.fromARGB(255, 90, 113, 243) // Blue color when filter is open
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Space below search and filter
                Expanded(child: _buildSpecialistList()), // Display the specialist list here
              ],
            ),
          ),
          // Filter menu overlay
          if (_showFilters)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFilters = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.5), // Darken the background
              ),
            ),
          // Sliding filter options from bottom
          if (_showFilters)
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 2, // Cover half of the page
                child: _buildFilterOptions(),
              ),
            ),
        ],
      ),
    );
  }
}
