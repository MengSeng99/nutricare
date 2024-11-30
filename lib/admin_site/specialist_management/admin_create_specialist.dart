import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for Firebase Authentication
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateSpecialistScreen extends StatefulWidget {
  const CreateSpecialistScreen({super.key});

  @override
  _CreateSpecialistScreenState createState() => _CreateSpecialistScreenState();
}

class _CreateSpecialistScreenState extends State<CreateSpecialistScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController organizationController;
  late TextEditingController experienceController;
  late TextEditingController aboutController;

  late List<dynamic> services;

  String? profilePictureUrl;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile; // Keep the image file temporarily until add is clicked

  String? selectedGender;
  String? selectedSpecialization;

  bool _isPasswordVisible = false; // For password visibility toggle

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    organizationController = TextEditingController();
    experienceController = TextEditingController();
    aboutController = TextEditingController();

    services = [];
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    organizationController.dispose();
    experienceController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  Future<String?> uploadProfilePicture() async {
    if (_imageFile != null) {
      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        String fileName = _imageFile!.name;
        Reference ref =
            storage.ref().child('specialist_profile_picture/$fileName');
        await ref.putFile(File(_imageFile!.path));
        return await ref.getDownloadURL(); // Return the download URL
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
    return null; // Return null if no image is uploaded
  }

  bool isEmailValid(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> createSpecialist() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        organizationController.text.isEmpty ||
        experienceController.text.isEmpty ||
        aboutController.text.isEmpty ||
        selectedGender == null ||
        selectedSpecialization == null ||
        services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please fill all required fields and add at least one service!'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // Validate email format
    if (!isEmailValid(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please enter a valid email address! Example: specialist@nutricare.com'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password length
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 6 characters long!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create a user in FirebaseAuth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      String specialistId =
          userCredential.user!.uid; // Use the UID as the specialistId

      final newSpecialist = {
        'name': nameController.text,
        'email': emailController.text,
        'organization': organizationController.text,
        'experience_years': int.tryParse(experienceController.text) ?? 0,
        'gender': selectedGender,
        'specialization': selectedSpecialization,
        'about': aboutController.text,
        'services': services,
        'profile_picture_url': null // Initially set to null
      };

      // Save the new specialist information to Firestore using the UID as the document ID
      await FirebaseFirestore.instance
          .collection('specialists')
          .doc(specialistId)
          .set(newSpecialist);

      // Upload the profile picture after the specialist is created
      String? imageUrl = await uploadProfilePicture();
      if (imageUrl != null) {
        // Update the profile picture URL in Firestore
        await FirebaseFirestore.instance
            .collection('specialists')
            .doc(specialistId)
            .update({
          'profile_picture_url': imageUrl,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Specialist created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating specialist: $e')),
      );
    }
  }

  Future<void> pickImage() async {
    _imageFile = await _picker.pickImage(source: ImageSource.gallery);
    if (_imageFile != null) {
      setState(() {
        profilePictureUrl = _imageFile!.path;
      });
    }
  }

  void showAddServiceDialog() {
    final TextEditingController serviceNameController = TextEditingController();
    final TextEditingController serviceFeeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Add Service',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243)),
          ),
          content: SizedBox(
            height: 150,
            child: Column(
              children: [
                TextField(
                  controller: serviceNameController,
                  decoration: const InputDecoration(labelText: 'Service Name'),
                ),
                TextField(
                  controller: serviceFeeController,
                  decoration: const InputDecoration(labelText: 'Fee (RM)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: Color.fromARGB(255, 90, 113, 243))),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 113, 243),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
              onPressed: () {
                final serviceName = serviceNameController.text;
                final serviceFee = double.tryParse(serviceFeeController.text);
                if (serviceName.isNotEmpty && serviceFee != null) {
                  addService(serviceName, serviceFee);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter valid service details'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void addService(String name, double fee) {
    final newService = {'name': name, 'fee': fee};
    setState(() {
      services.add(newService);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Add New Specialist",
          style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side:
                BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profilePictureUrl != null &&
                              profilePictureUrl!.isNotEmpty
                          ? FileImage(File(
                              profilePictureUrl!)) // Use FileImage to display the local image
                          : null,
                      child: (profilePictureUrl == null ||
                              profilePictureUrl!.isEmpty)
                          ? const Icon(Icons.person,
                              size: 50,
                              color: Color.fromARGB(255, 90, 113, 243))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color.fromARGB(255, 90, 113, 243),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                ),
                TextField(
                  controller: organizationController,
                  decoration: const InputDecoration(labelText: 'Organization'),
                ),
                TextField(
                  controller: experienceController,
                  decoration:
                      const InputDecoration(labelText: 'Experience (Years)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                const Text('Gender',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedGender,
                  hint: const Text('Select Gender'),
                  items: <String>['Male', 'Female']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedGender = newValue;
                    });
                  },
                ),
                const SizedBox(height: 10),
                const Text('Specialization',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedSpecialization,
                  hint: const Text('Select Specialization'),
                  items: <String>['Nutritionist', 'Dietitian']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSpecialization = newValue;
                    });
                  },
                ),
                TextField(
                  controller: aboutController,
                  decoration: const InputDecoration(labelText: 'About'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Services',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Color.fromARGB(255, 90, 113, 243)),
                      tooltip: 'Add Service',
                      onPressed: showAddServiceDialog,
                    ),
                  ],
                ),
                ListView.builder(
                  itemCount: services.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(service['name'] ?? 'Unnamed Service',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Fee: RM ${service['fee'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: createSpecialist,
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text('Add',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color.fromARGB(255, 90, 113, 243),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      minimumSize: const Size(150, 50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
