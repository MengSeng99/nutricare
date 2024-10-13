import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'payment.dart';

class ClientInfoScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final String specialistName;

  const ClientInfoScreen({super.key, required this.selectedDate, this.selectedTimeSlot, String? selectedMode, required this.specialistName});

  @override
  _ClientInfoScreenState createState() => _ClientInfoScreenState();
}

class _ClientInfoScreenState extends State<ClientInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? nric;
  String? fullName;
  DateTime? dateOfBirth;
  String? gender;
  String? phoneNumber;
  String? reasonForAppointment;
  String? customReason;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInfoDialog();
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Image.asset(
                      'images/health-record-3.png',
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Your personal details are important for us",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildDialogSubtitle(
                      title: "Get Verified",
                      description:
                          "Your personal details will be verified by our Specialist during consultation.",
                    ),
                    const SizedBox(height: 10),
                    _buildDialogSubtitle(
                      title: "Maintain accurate Medical records",
                      description:
                          "We collect your personal details to ensure that you get accurate medical certificates and seamless service, matching with your identity proof.",
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Got it",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogSubtitle({required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 113, 104, 132)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Information",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text(
                //   "Please fill in your information:",
                //   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                // ),
                const SizedBox(height: 20),
                _buildNRICField(),
                const SizedBox(height: 16),
                _buildFullNameField(),
                const SizedBox(height: 16),
                _buildDateOfBirthField(),
                const SizedBox(height: 16),
                _buildGenderField(),
                const SizedBox(height: 16),
                _buildPhoneNumberField(),
                const SizedBox(height: 16),
                _buildReasonForAppointmentField(),
                if (reasonForAppointment == "Other") ...[
                  const SizedBox(height: 16),
                  _buildCustomReasonField(),
                ],
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNRICField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "NRIC",
        prefixIcon: const Icon(Icons.perm_identity),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty || value.length != 12) {
          return 'Please enter a valid 12-digit NRIC (e.g., 951234001234)';
        }
        return null;
      },
      onSaved: (value) => nric = value,
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Full Name",
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        return null;
      },
      onSaved: (value) => fullName = value,
    );
  }

  Widget _buildDateOfBirthField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Date of Birth (YYYY-MM-DD)",
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: dateOfBirth ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null && pickedDate != dateOfBirth) {
          setState(() {
            dateOfBirth = pickedDate;
          });
        }
      },
      readOnly: true,
      validator: (value) {
        if (dateOfBirth == null) {
          return 'Please select your date of birth';
        }
        return null;
      },
      controller: TextEditingController(
        text: dateOfBirth != null ? "${dateOfBirth!.toLocal()}".split(' ')[0] : '',
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Gender",
        prefixIcon: const Icon(Icons.transgender),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      items: <String>['Male', 'Female', 'Other', 'Prefer not to say'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          gender = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select your gender';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Phone Number",
        prefixText: "+60 ",
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty || value.length < 9 || value.length > 10) {
          return 'Please enter a valid phone number with 9-10 digits';
        }
        return null;
      },
      onSaved: (value) => phoneNumber = value,
    );
  }

  Widget _buildReasonForAppointmentField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Reason for Appointment",
        prefixIcon: const Icon(Icons.question_answer),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      items: <String>['General Consultation', 'Nutrition Advice', 'Follow-up', 'Other']
          .map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          reasonForAppointment = value;
          if (value != "Other") customReason = null;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a reason for your appointment';
        }
        return null;
      },
    );
  }

  Widget _buildCustomReasonField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Custom Reason",
        prefixIcon: const Icon(Icons.edit),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please specify your reason';
        }
        return null;
      },
      onSaved: (value) => customReason = value,
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Information submitted: NRIC: $nric, Name: $fullName, DOB: ${dateOfBirth.toString()}, Gender: $gender, Phone: $phoneNumber, Reason: ${customReason ?? reasonForAppointment}'),
              ),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  selectedDate: widget.selectedDate,
                  selectedTimeSlot: widget.selectedTimeSlot,
                  fullName: fullName, // Pass fullName
                  reasonForAppointment: customReason ?? reasonForAppointment, // Pass reason
                  specialistName: widget.specialistName
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 90, 113, 243),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Submit",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
