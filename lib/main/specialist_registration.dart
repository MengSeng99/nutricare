import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:file_picker/file_picker.dart'; // For picking files
import 'dart:io';

class SpecialistRegistrationScreen extends StatefulWidget {
  const SpecialistRegistrationScreen({super.key});

  @override
  _SpecialistRegistrationScreenState createState() =>
      _SpecialistRegistrationScreenState();
}

class _SpecialistRegistrationScreenState
    extends State<SpecialistRegistrationScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController organizationController;
  late TextEditingController experienceController;
  late TextEditingController aboutController;
  late TextEditingController phoneController;

  late List<dynamic> services;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile; // Variable to store profile picture
  String? _documentPath; // Variable to store the document path (AHP license)
  String? _documentName; // Variable to store the name of the document

  String? selectedGender;
  String? selectedSpecialization;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    organizationController = TextEditingController();
    experienceController = TextEditingController();
    aboutController = TextEditingController();
    phoneController = TextEditingController();
    services = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    organizationController.dispose();
    experienceController.dispose();
    aboutController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> sendRegistrationEnquiry() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
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

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Please upload a profile picture for the specialist!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_documentPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload your AHP license!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    try {
      String? profilePictureUrl = await uploadProfilePicture();
      String? documentUrl = await uploadDocument();

      final newRegistrationEnquiry = {
        'name': nameController.text,
        'email': emailController.text,
        // Prepend "60" to the phone number
        'phone': "60${phoneController.text}",
        'organization': organizationController.text,
        'experience_years': int.tryParse(experienceController.text) ?? 0,
        'gender': selectedGender,
        'specialization': selectedSpecialization,
        'about': aboutController.text,
        'services': services,
        'profile_picture_url': profilePictureUrl,
        'document_url': documentUrl, // Add document URL to Firestore
        'submitDate': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('specialist_registration_enquiries')
          .add(newRegistrationEnquiry);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.white,
            title: const Text(
              "Registration Submitted",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 90, 113, 243)),
            ),
            content: const Text(
                "Your registration enquiry has been submitted successfully! "
                "Our team will review it and contact you via the provided contact info."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pop(context); // Close the registration screen
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending registration enquiry: $e')),
      );
    }
  }

  Future<String?> uploadProfilePicture() async {
    if (_imageFile != null) {
      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        String fileName = _imageFile!.name;
        String uploadedImagePath =
            'profile_pictures/$fileName'; // Store the path
        Reference ref = storage.ref().child(uploadedImagePath);
        await ref.putFile(File(_imageFile!.path));
        return await ref.getDownloadURL(); // Return the download URL
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
    return null; // Return null if there was no image to upload
  }

  // Method to upload the document
  Future<String?> uploadDocument() async {
    if (_documentPath != null) {
      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        String fileName = _documentName ??
            "document"; // Get the file name or default to "document"
        String uploadedDocumentPath = 'documents/$fileName'; // Store the path
        Reference ref = storage.ref().child(uploadedDocumentPath);
        await ref.putFile(File(_documentPath!)); // Directly upload the document
        return await ref.getDownloadURL(); // Return the download URL
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
        );
      }
    }
    return null; // Return null if there was no document to upload
  }

  bool isEmailValid(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> pickImage() async {
    _imageFile = await _picker.pickImage(source: ImageSource.gallery);
    if (_imageFile != null) {
      setState(() {
        // Optionally, you can display a confirmation or preview of the image
      });
    }
  }

  // New method to pick the document using FilePicker
  Future<void> pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Allow any document type, adjust as needed
    );

    if (result != null) {
      setState(() {
        _documentPath =
            result.files.single.path; // Store the selected file path
        _documentName =
            result.files.single.name; // Store the name of the document
      });
    }
  }

  // Method to remove the uploaded document
  void removeDocument() {
    setState(() {
      _documentPath = null; // Clear the document path
      _documentName = null; // Clear the document name
    });
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
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
                      'images/welcome.png',
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Welcome to Our Specialist Community!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 90, 113, 243),
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "We are thrilled to have you here! As a specialist, your expertise is invaluable to us. Together, let's provide exceptional care and make a difference in people's lives.",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogSubtitle(
                      title: "Get Started with Confidence",
                      description:
                          "Our team is here to support you every step of the way.",
                    ),
                    const SizedBox(height: 10),
                    _buildDialogSubtitle(
                      title: "Connect and Collaborate",
                      description:
                          "Join a network of professionals dedicated to quality healthcare.",
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
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
                        "Let's Get Started!",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
            fontSize: 14,
            color: Color.fromARGB(255, 113, 104, 132),
          ),
        ),
      ],
    );
  }

  void showAddServiceDialog() {
    final TextEditingController serviceNameController = TextEditingController();
    final TextEditingController serviceDescriptionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Add Service',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243)),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please fill in the details of the service you provide. Make sure to include both the name and a brief description.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: serviceNameController,
                    decoration:
                        const InputDecoration(labelText: 'Service Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: serviceDescriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                ],
              ),
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
                final serviceDescription = serviceDescriptionController.text;
                if (serviceName.isNotEmpty && serviceDescription.isNotEmpty) {
                  addService(serviceName, serviceDescription);
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

  void addService(String name, String description) {
    final newService = {'name': name, 'description': description};
    setState(() {
      services.add(newService);
    });
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      controller: phoneController,
      decoration: InputDecoration(
        labelText: "Phone Number",
        prefixText: "+60 ",
        prefixIcon:
            const Icon(Icons.phone, color: Color.fromARGB(255, 90, 113, 243)),
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

  Widget _buildNameField() {
    return TextFormField(
      controller: nameController,
      decoration: InputDecoration(
        labelText: "Name",
        prefixIcon:
            const Icon(Icons.person, color: Color.fromARGB(255, 90, 113, 243)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      decoration: InputDecoration(
        labelText: "Email",
        prefixIcon:
            const Icon(Icons.email, color: Color.fromARGB(255, 90, 113, 243)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty || !isEmailValid(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildOrganizationField() {
    return TextFormField(
      controller: organizationController,
      decoration: InputDecoration(
        labelText: "Organization",
        prefixIcon: const Icon(Icons.business,
            color: Color.fromARGB(255, 90, 113, 243)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your organization name';
        }
        return null;
      },
    );
  }

  Widget _buildExperienceField() {
    return TextFormField(
      controller: experienceController,
      decoration: InputDecoration(
        labelText: "Experience (Years)",
        prefixIcon: const Icon(Icons.access_time,
            color: Color.fromARGB(255, 90, 113, 243)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your years of experience';
        }
        return null;
      },
    );
  }

  Widget _buildAboutField() {
    return TextFormField(
      controller: aboutController,
      decoration: InputDecoration(
        labelText: "About",
        prefixIcon:
            const Icon(Icons.info, color: Color.fromARGB(255, 90, 113, 243)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please tell us about yourself';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(
      {required String hint,
      required List<String> items,
      String? selectedValue,
      Function(String?)? onChanged}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      value: selectedValue,
      hint: const Text('Select'),
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Specialist Registration",
            style: TextStyle(
                color: Color.fromARGB(255, 90, 113, 243),
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    backgroundColor: Colors.white,
                    title: const Text(
                      "Important Note",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 90, 113, 243)),
                    ),
                    content: const Text(
                      'This is an inquiry form for specialist registration. '
                      'By submitting this form, you are not directly signing up for an account. '
                      'Our administrator will review your submission and contact you if you are selected to become a part of our community.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child:
              Divider(height: 0.5, color: Color.fromARGB(255, 220, 220, 241)),
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
                      backgroundImage: _imageFile != null
                          ? FileImage(File(_imageFile!.path))
                          : null,
                      child: _imageFile == null
                          ? const Icon(Icons.person,
                              size: 50,
                              color: Color.fromARGB(255, 90, 113, 243))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildNameField(),
                const SizedBox(height: 10),
                _buildEmailField(),
                const SizedBox(height: 10),
                _buildPhoneNumberField(),
                const SizedBox(height: 10),
                _buildOrganizationField(),
                const SizedBox(height: 10),
                _buildExperienceField(),
                const SizedBox(height: 10),
                const Text('Gender',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildDropdownField(
                  hint: 'Select Gender',
                  items: ['Male', 'Female', 'Other'],
                  selectedValue: selectedGender,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedGender = newValue;
                    });
                  },
                ),
                const SizedBox(height: 10),
                const Text('Specialization',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildDropdownField(
                  hint: 'Select Specialization',
                  items: ['Nutritionist', 'Dietitian'],
                  selectedValue: selectedSpecialization,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSpecialization = newValue;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildAboutField(),
                const SizedBox(height: 20),

                // Section for document upload
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('AHP License',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.info_outline,
                          color: Color.fromARGB(255, 90, 113, 243)),
                      tooltip: 'Info',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: Colors.white,
                              title: const Text(
                                "AHP License Upload Information",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 90, 113, 243)),
                              ),
                              content: const Text(
                                'Please upload your AHP license document to prove you are a professional and relevant specialist.',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                // Show file name and remove button if a document is uploaded
                if (_documentPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _documentName ?? 'No document',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: removeDocument,
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: pickDocument,
                    child: const Text('Upload Document (PDF, DOC, etc.)'),
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
                        subtitle: Text(
                            'Description: ${service['description'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: sendRegistrationEnquiry,
                    label: const Text('Submit Inquiry',
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
