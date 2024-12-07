import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditSpecialistScreen extends StatefulWidget {
  final String specialistId;
  final Map<String, dynamic> specialistData;

  const EditSpecialistScreen({
    super.key,
    required this.specialistId,
    required this.specialistData,
  });

  @override
  _EditSpecialistScreenState createState() => _EditSpecialistScreenState();
}

class _EditSpecialistScreenState extends State<EditSpecialistScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController organizationController;
  late TextEditingController experienceController;
  late TextEditingController genderController;
  late TextEditingController aboutController;

  late List<dynamic> services;
  late List<dynamic> reviews;

  String? profilePictureUrl;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  // For managing deletions
  List<Map<String, dynamic>> servicesToDelete = [];
  List<Map<String, dynamic>> reviewsToDelete = [];

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.specialistData['name'] ?? '');
    emailController =
        TextEditingController(text: widget.specialistData['email'] ?? '');
    organizationController = TextEditingController(
        text: widget.specialistData['organization'] ?? '');
    experienceController = TextEditingController(
        text: widget.specialistData['experience_years']?.toString() ?? '');
    genderController =
        TextEditingController(text: widget.specialistData['gender'] ?? '');
    aboutController =
        TextEditingController(text: widget.specialistData['about'] ?? '');

    services = widget.specialistData['services'] ?? [];
    reviews = widget.specialistData['reviews'] ?? [];
    profilePictureUrl = widget.specialistData['profile_picture_url'];
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    organizationController.dispose();
    experienceController.dispose();
    genderController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  Future<String?> uploadProfilePicture() async {
    if (_imageFile != null) {
      try {
        FirebaseStorage storage = FirebaseStorage.instance;

        // You can choose to either keep the old file or delete it.
        if (profilePictureUrl != null) {
          Reference previousRef = storage.refFromURL(profilePictureUrl!);
          await previousRef
              .delete(); // Optional: Delete the previous profile picture
        }

        String fileName = _imageFile!.name;
        Reference ref =
            storage.ref().child('specialist_profile_picture/$fileName');
        await ref.putFile(File(_imageFile!.path));
        return await ref.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
    return null; // Return null if no image is uploaded
  }

  Future<void> updateSpecialist() async {
    try {
      final Map<String, dynamic> updates = {};
      if (nameController.text != widget.specialistData['name']) {
        updates['name'] = nameController.text;
      }
      if (emailController.text != widget.specialistData['email']) {
        updates['email'] = emailController.text;
      }
      if (organizationController.text !=
          widget.specialistData['organization']) {
        updates['organization'] = organizationController.text;
      }
      if (experienceController.text !=
          widget.specialistData['experience_years']?.toString()) {
        updates['experience_years'] = int.tryParse(experienceController.text);
      }
      if (genderController.text != widget.specialistData['gender']) {
        updates['gender'] = genderController.text;
      }
      if (aboutController.text != widget.specialistData['about']) {
        updates['about'] = aboutController.text;
      }
      updates['services'] = services;
      if (profilePictureUrl != widget.specialistData['profile_picture_url']) {
        updates['profile_picture_url'] = profilePictureUrl;
      }
      // Check if profile picture needs to be updated
      if (_imageFile != null) {
        String? newImageUrl = await uploadProfilePicture();
        if (newImageUrl != null) {
          updates['profile_picture_url'] = newImageUrl;
        }
      }

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('specialists')
            .doc(widget.specialistId)
            .update(updates);

        // Perform deletions for services
        for (var service in servicesToDelete) {
          await FirebaseFirestore.instance
              .collection('specialists')
              .doc(widget.specialistId)
              .update({
            'services': FieldValue.arrayRemove([service])
          });
        }

        // Perform deletions for reviews
        for (var review in reviewsToDelete) {
          await FirebaseFirestore.instance
              .collection('specialists')
              .doc(widget.specialistId)
              .update({
            'reviews': FieldValue.arrayRemove([review])
          });
        }

        // Clear deletion lists
        servicesToDelete.clear();
        reviewsToDelete.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Specialist details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes made!')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating specialist: $e')),
      );
    }
  }

  Future<void> deleteReview(Map<String, dynamic> review) {
    setState(() {
      reviewsToDelete
          .add(review); // Instead of deleting immediately, we just log it
      reviews.remove(review); // Remove from local list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Review by "${review['reviewer_name']}" has been removed')),
      );
    });
    return Future.value(); // To satisfy the return type
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile; // Store the picked file for later use
        profilePictureUrl = pickedFile.path; // Set the local path to display
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
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Cancel',
                  style: TextStyle(color: Color.fromARGB(255, 90, 113, 243))),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
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
                      content:
                          const Text('Please enter a valid service details'),
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

    FirebaseFirestore.instance
        .collection('specialists')
        .doc(widget.specialistId)
        .update({
      'services': FieldValue.arrayUnion([newService])
    });
  }

  Future<void> deleteService(Map<String, dynamic> service) {
    setState(() {
      servicesToDelete
          .add(service); // Instead of deleting immediately, we just log it
      services.remove(service); // Remove from local list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Service of "${service['name']}" has been removed')),
      );
    });
    return Future.value(); // To satisfy the return type
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Specialist Details",
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
          margin: const EdgeInsets.all(8),
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
                color: Color.fromARGB(255, 221, 222, 226), width: 1),
            borderRadius: BorderRadius.circular(20),
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
                          ? FileImage(File(
                              _imageFile!.path)) // Display the picked image
                          : (profilePictureUrl != null
                              ? NetworkImage(profilePictureUrl!)
                              : null),
                      child: (_imageFile == null && profilePictureUrl == null)
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
                  controller: organizationController,
                  decoration: const InputDecoration(labelText: 'Organization'),
                ),
                TextField(
                  controller: experienceController,
                  decoration:
                      const InputDecoration(labelText: 'Experience (Years)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: genderController,
                  decoration: const InputDecoration(labelText: 'Gender'),
                ),
                TextField(
                  controller: aboutController,
                  decoration: const InputDecoration(labelText: 'About'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Services Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Services',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
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
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            color: Color.fromARGB(255, 221, 222, 226),
                            width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(service['name'] ?? 'Unnamed Service',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Fee: RM ${service['fee'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteService(service),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Reviews Section
                const Text(
                  'Reviews',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  itemCount: reviews.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final review = reviews[index];

                    String reviewDate;
                    if (review['date'] is Timestamp) {
                      reviewDate = (review['date'] as Timestamp)
                          .toDate()
                          .toLocal()
                          .toString()
                          .split(' ')[0];
                    } else if (review['date'] is String) {
                      reviewDate = review['date'];
                    } else {
                      reviewDate = 'N/A';
                    }

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(review['reviewer_name'] ?? 'Anonymous',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: $reviewDate',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                            Text('Rating: ${review['rating'] ?? 'N/A'} / 5',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(review['review'] ?? 'No Review',
                                style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteReview(review),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: updateSpecialist,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('Save',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
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
