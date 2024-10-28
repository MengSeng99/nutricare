import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatDetailScreen extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final String receiverId;
  final String specialistName;
  final String profilePictureUrl;

  ChatDetailScreen({
    required this.chatId,
    required this.currentUserId,
    required this.receiverId,
    required this.specialistName,
    required this.profilePictureUrl,
  });

  final TextEditingController _messageController = TextEditingController();

  Future<void> _showSpecialistDetails(BuildContext context) async {
    try {
      DocumentSnapshot specialistDoc = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(receiverId)
          .get();

      if (specialistDoc.exists) {
        var specialistData = specialistDoc.data() as Map<String, dynamic>;

        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 16,
              child: Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        specialistData['profile_picture_url'] ?? 
                        "assets/default_profile.png",
                      ),
                      radius: 40,
                    ),
                    SizedBox(height: 16),
                    Text(
                      specialistData['name'] ?? "Specialist Details",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 90, 113, 243),
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(color: Colors.grey[300]),
                    SizedBox(height: 10),
                    _buildDetailRow("Specialization:", specialistData['specialization'] ?? 'N/A'),
                    _buildDetailRow("Organization:", specialistData['organization'] ?? 'N/A'),
                    _buildDetailRow("Experience:", "${specialistData['experience_years'] ?? 'N/A'} years"),
                    _buildDetailRow("Gender:", specialistData['gender'] ?? 'N/A'),
                    SizedBox(height: 10),
                    Text(
                      "About:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 90, 113, 243),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      specialistData['about'] ?? 'No information available.',
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Dismiss the dialog
                      },
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        print("No specialist found");
      }
    } catch (e) {
      print("Error fetching specialist details: $e");
    }
  }

  static Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 90, 113, 243),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: profilePictureUrl.isNotEmpty
                  ? NetworkImage(profilePictureUrl)
                  : AssetImage("assets/default_profile.png") as ImageProvider,
            ),
            SizedBox(width: 16),
            Text(
              "Dr. $specialistName",
              style: TextStyle(
                color: Color.fromARGB(255, 90, 113, 243),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              _showSpecialistDetails(context);
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        iconTheme: IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index].data() as Map<String, dynamic>;
                    bool isMe = messageData['senderId'] == currentUserId;

                    bool showProfilePicture = index > 0
                        ? messages[index - 1]['senderId'] != currentUserId
                        : true;

                    return _buildMessageBubble(context, messageData, isMe, showProfilePicture);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () => _pickImageAndSend(),
                ),
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: () => _pickFileAndSend(),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Color.fromARGB(255, 90, 113, 243)),
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(chatId);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageAndSend() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    File file = File(pickedFile.path);
    await _uploadAndSendFile(file, isImage: true);
  }
}

  Future<void> _pickFileAndSend() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        File file = File(filePath);
        await _uploadAndSendFile(file, isImage: false);
      }
    }
  }

 Future<void> _uploadAndSendFile(File file, {required bool isImage}) async {
    String fileName = file.path.split('/').last; // Extracting the file name
    String path = isImage
        ? 'chat_images/${DateTime.now().millisecondsSinceEpoch}.${fileName.split('.').last}'
        : 'chat_files/${DateTime.now().millisecondsSinceEpoch}.$fileName';

    Reference ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    String downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': isImage ? null : fileName, // File name for non-image files
      'fileUrl': downloadUrl,
      'isImage': isImage,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
}

  Future<void> _sendMessage(String chatId) async {
    if (_messageController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': _messageController.text,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

 Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> messageData, bool isMe, bool showProfilePicture) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && showProfilePicture)
            CircleAvatar(
              backgroundImage: NetworkImage(profilePictureUrl),
              radius: 18,
            ),
          SizedBox(width: 8),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? Color.fromARGB(255, 90, 113, 243) : Color.fromARGB(255, 233, 242, 255),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2)),
                  ],
                ),
                child: messageData['isImage'] == true
                    ? GestureDetector(
                        onTap: () {
                          // Open image details or with an image viewer
                          launch(messageData['fileUrl']);
                        },
                        child: Image.network(messageData['fileUrl'], height: 200, fit: BoxFit.cover),
                      )
                    : messageData['fileUrl'] != null
                        ? Row(
                            children: [
                              Icon(Icons.attach_file, color: isMe ? Colors.white : Colors.black54),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  launch(messageData['fileUrl']); // Launch the file URL
                                },
                                child: Text(
                                  messageData['text'] ?? "File sent",
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            messageData['text'] ?? "No message",
                            style: TextStyle(
                              fontSize: 16,
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
              ),
            ),
          ),
          SizedBox(width: 8),
          if (isMe && showProfilePicture)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(currentUserId).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return CircleAvatar(
                    backgroundImage: AssetImage("assets/default_profile.png"),
                    radius: 18,
                  );
                }

                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                return CircleAvatar(
                  backgroundImage: NetworkImage(
                    userData['profile_pic'] ?? "assets/default_profile.png",
                  ),
                  radius: 18,
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }
}