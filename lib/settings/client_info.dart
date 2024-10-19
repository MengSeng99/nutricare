import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientInfoScreen extends StatefulWidget {
  const ClientInfoScreen({super.key});

  @override
  _ClientInfoScreenState createState() => _ClientInfoScreenState();
}

class _ClientInfoScreenState extends State<ClientInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController nricController;
  late TextEditingController fullNameController;
  late TextEditingController phoneNumberController;

  DateTime? dateOfBirth;
  String? gender;
  String? personalDetailsDocId;

  @override
  void initState() {
    super.initState();
    nricController = TextEditingController();
    fullNameController = TextEditingController();
    phoneNumberController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    nricController.dispose();
    fullNameController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;

    if (user != null) {
      String userId = user.uid;
      // Fetching the personal details
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('personal_details')
          .get();

      if (snapshot.docs.isNotEmpty) {
        DocumentSnapshot doc =
            snapshot.docs.first; // Assuming there's only one document
        setState(() {
          personalDetailsDocId = doc.id; // Store the document ID
          nricController.text = doc['nric'];
          fullNameController.text = doc['fullName'];
          dateOfBirth = (doc['dateOfBirth'] as Timestamp)
              .toDate(); // Adjust according to your Firestore structure
          gender = doc['gender'];
          phoneNumberController.text = doc['phoneNumber'];
        });
      } else {
        _showInfoDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Your Information",
            style: TextStyle(
                color: Color.fromARGB(255, 90, 113, 243),
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNRICField(),
                const SizedBox(height: 16),
                _buildFullNameField(),
                const SizedBox(height: 16),
                _buildDateOfBirthField(),
                const SizedBox(height: 16),
                _buildGenderField(),
                const SizedBox(height: 16),
                _buildPhoneNumberField(),
                const SizedBox(height: 30),
                Center(
                child: ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        255, 90, 113, 243), // Blue background color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 34, vertical: 14), // Appropriate padding
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30), // 30 border radius
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.white, // White text color
                      fontSize: 16, // Appropriate font size
                    ),
                  ),
                ),),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNRICField() {
    return TextFormField(
      controller: nricController,
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
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      controller: fullNameController,
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
        text: dateOfBirth != null
            ? "${dateOfBirth!.toLocal()}".split(' ')[0]
            : '',
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      value: gender,
      decoration: InputDecoration(
        labelText: "Gender",
        prefixIcon: const Icon(Icons.transgender),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      items: <String>['Male', 'Female', 'Other', 'Prefer not to say']
          .map((String value) {
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
      controller: phoneNumberController,
      decoration: InputDecoration(
        labelText: "Phone Number",
        prefixText: "+60 ",
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null ||
            value.isEmpty ||
            value.length < 9 ||
            value.length > 10) {
          return 'Please enter a valid phone number with 9-10 digits';
        }
        return null;
      },
    );
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = _auth.currentUser;
      if (user != null) {
        String userId = user.uid;

        if (personalDetailsDocId == null) {
          // If the document does not exist, create a new one
          await _firestore
              .collection('users') // Adjust the collection name as needed
              .doc(userId)
              .collection('personal_details')
              .add({
            'nric': nricController.text,
            'fullName': fullNameController.text,
            'dateOfBirth': dateOfBirth,
            'gender': gender,
            'phoneNumber': phoneNumberController.text,
          });
        } else {
          // If the document exists, update it
          await _firestore
              .collection('users') // Adjust the collection name as needed
              .doc(userId)
              .collection('personal_details')
              .doc(personalDetailsDocId) // Use the existing document ID
              .update({
            'nric': nricController.text,
            'fullName': fullNameController.text,
            'dateOfBirth': dateOfBirth,
            'gender': gender,
            'phoneNumber': phoneNumberController.text,
          });
        }
        Navigator.pop(context); // Navigate back after saving
      }
    }
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        backgroundColor:
                            const Color.fromARGB(255, 90, 113, 243),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Got it",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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

  Widget _buildDialogSubtitle(
      {required String title, required String description}) {
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
          style: const TextStyle(
              fontSize: 14, color: Color.fromARGB(255, 113, 104, 132)),
        ),
      ],
    );
  }
}
