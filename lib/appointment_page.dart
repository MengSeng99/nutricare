// import 'package:flutter/material.dart';

// import 'booking.dart';
// import 'client_info.dart';
// import 'payment.dart';
// // Import your existing screens here


// class AppointmentProcessScreen extends StatefulWidget {
//   @override
//   _AppointmentProcessScreenState createState() =>
//       _AppointmentProcessScreenState();
// }

// class _AppointmentProcessScreenState extends State<AppointmentProcessScreen> {
//   int _currentStep = 0; // Track the current step

//   // Methods to control navigation between steps
//   void _goToStep(int step) {
//     setState(() {
//       _currentStep = step;
//     });
//   }

//   void _nextStep() {
//     if (_currentStep < 2) {
//       setState(() {
//         _currentStep += 1;
//       });
//     }
//   }

//   void _previousStep() {
//     if (_currentStep > 0) {
//       setState(() {
//         _currentStep -= 1;
//       });
//     }
//   }

//   // Progress bar widget
//   Widget _buildProgressBar() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _buildStepIndicator(0, Icons.person, "Booking"),
//         _buildStepIndicator(1, Icons.edit, "Client Info"),
//         _buildStepIndicator(2, Icons.payment, "Payment"),
//       ],
//     );
//   }

//   // Step indicator with modern design and animation
//   Widget _buildStepIndicator(int stepIndex, IconData icon, String title) {
//     bool isActive = _currentStep == stepIndex;
//     bool isCompleted = _currentStep > stepIndex;

//     return GestureDetector(
//       onTap: () => _goToStep(stepIndex), // Allow step navigation
//       child: Column(
//         children: [
//           AnimatedContainer(
//             duration: Duration(milliseconds: 300),
//             height: 50,
//             width: 50,
//             decoration: BoxDecoration(
//               color: isCompleted
//                   ? Colors.green
//                   : (isActive ? Colors.blue : Colors.grey.shade300),
//               shape: BoxShape.circle,
//               boxShadow: isActive
//                   ? [BoxShadow(color: Colors.blue.shade100, blurRadius: 10)]
//                   : [],
//             ),
//             child: Icon(
//               isCompleted ? Icons.check : icon,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 14,
//               color: isActive ? Colors.blue : Colors.black54,
//               fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // This method returns the corresponding screen widget based on the current step
//   Widget _buildCurrentScreen() {
//     switch (_currentStep) {
//       case 0:
//         return BookingScreen(specialistName: 'Louis Koh',); // Your BookingScreen here
//       case 1:
//         return ClientInfoScreen(selectedDate: DateTime.now(), specialistName: 'Louis Koh',); // Your ClientInfoScreen here
//       case 2:
//         return PaymentScreen(selectedDate: DateTime.now(), specialistName: 'Louis Koh',); // Your PaymentScreen here
//       default:
//         return BookingScreen(specialistName: 'Louis Koh',); // Default to the first step
//     }
//   }

//   // Navigation buttons
//   Widget _buildNavigationButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         ElevatedButton(
//           onPressed: _previousStep,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.grey.shade400,
//             padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           child: Text('Previous'),
//         ),
//         ElevatedButton(
//           onPressed: _nextStep,
//           style: ElevatedButton.styleFrom(
//             padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             backgroundColor: Colors.blue,
//           ),
//           child: Row(
//             children: [
//               Text('Next', style: TextStyle(color: Colors.white)),
//               SizedBox(width: 8),
//               Icon(Icons.arrow_forward, color: Colors.white),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Appointment Process'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Progress bar
//             _buildProgressBar(),
//             const SizedBox(height: 32),

//             // Step content area
//             Expanded(
//               child: _buildCurrentScreen(),
//             ),

//             // Navigation buttons
//             _buildNavigationButtons(),
//           ],
//         ),
//       ),
//     );
//   }
// }
