import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:nutricare/specialist_site/client_management/client_details.dart';
import 'package:url_launcher/url_launcher.dart';

class SpecialistChatDetailScreen extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final String receiverId;
  final String clientName; // Changed to clientName
  final String profilePictureUrl;

  SpecialistChatDetailScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.receiverId,
    required this.clientName, // Changed to clientName
    required this.profilePictureUrl,
  });

  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: profilePictureUrl.isNotEmpty
                  ? NetworkImage(profilePictureUrl)
                  : const AssetImage('images/user_profile/default_profile.png')
                      as ImageProvider,
            ),
            SizedBox(width: 16),
            Text(
              clientName, // Changed to clientName
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ClientDetailsScreen(
                    clientId: receiverId,
                    clientName: clientName,
                  ),
                ),
              );
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
                    var messageData =
                        messages[index].data() as Map<String, dynamic>;
                    bool isMe = messageData['senderId'] == currentUserId;

                    // Determine visibility of the profile picture based on the previous message
                    bool showProfilePicture = true; // Default for first message
                    if (index > 0) {
                      var previousMessageData =
                          messages[index - 1].data() as Map<String, dynamic>;
                      showProfilePicture = previousMessageData['senderId'] !=
                          messageData['senderId'];
                    }

                    if (index == 0) {
                      showProfilePicture =
                          true; // Always show for the very first message
                    } else if (messages[index - 1]['senderId'] ==
                        currentUserId) {
                      showProfilePicture =
                          false; // Hide the profile picture for consecutive messages from the same sender
                    } else {
                      showProfilePicture =
                          true; // Show if this message is from a different sender
                    }

                    DateTime? previousMessageDate = index > 0
                        ? (messages[index - 1].data()
                                as Map<String, dynamic>)['timestamp']
                            ?.toDate()
                        : null;

                    return _buildMessageBubble(context, messageData, isMe,
                        showProfilePicture, previousMessageDate);
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
                    maxLines: null,
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
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);

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

  Widget _buildMessageBubble(BuildContext context,
      Map<String, dynamic> messageData, bool isMe, bool showProfilePicture,
      [DateTime? previousMessageDate]) {
    // Get the timestamp
    Timestamp? timestamp = messageData['timestamp'];
    DateTime messageDate = timestamp?.toDate() ?? DateTime.now();

    // Format the timestamp
    String displayTime = _formatTimestamp(timestamp);

    // Check if we need to display the date
    String displayDate = "";
    if (previousMessageDate == null ||
        previousMessageDate.year != messageDate.year ||
        previousMessageDate.month != messageDate.month ||
        previousMessageDate.day != messageDate.day) {
      displayDate = DateFormat('yyyy-MM-dd').format(messageDate);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        children: [
          // Center the date
          if (displayDate.isNotEmpty)
            Center(
              child: Text(
                displayDate,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Only show the client's CircleAvatar for messages not from the sender
              if (!isMe)
                CircleAvatar(
                  backgroundImage: NetworkImage(profilePictureUrl.isNotEmpty
                      ? profilePictureUrl
                      : 'https://cdn-icons-png.freepik.com/512/3177/3177440.png'), // Provide a default image if empty
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
                      color: isMe
                          ? Color.fromARGB(255, 90, 113, 243)
                          : Color.fromARGB(255, 236, 238, 241),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(1, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        messageData['isImage'] == true
                            ? GestureDetector(
                                onTap: () {
                                  launch(messageData['fileUrl']);
                                },
                                child: Image.network(messageData['fileUrl'],
                                    height: 200, fit: BoxFit.cover),
                              )
                            : messageData['fileUrl'] != null
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(Icons.attach_file,
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black54),
                                      SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          launch(messageData[
                                              'fileUrl']); // Launch the file URL
                                        },
                                        child: Text(
                                          messageData['text'] ?? "File sent",
                                          style: TextStyle(
                                              color: isMe
                                                  ? Colors.white
                                                  : Colors.black),
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
                        SizedBox(height: 4),
                        // Display the timestamp inside the bubble
                        Text(
                          displayTime,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : Colors.grey, // Change color based on sender
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Show the specialist's CircleAvatar for messages from the sender
              if (isMe && showProfilePicture)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('specialists')
                      .doc(currentUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    if (!userSnapshot.hasData || userSnapshot.data == null) {
                      return CircleAvatar(
                        backgroundImage: const AssetImage(
                                'images/user_profile/default_profile.png')
                            as ImageProvider,
                        radius: 18,
                      );
                    }

                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    return CircleAvatar(
                      backgroundImage: NetworkImage(
                        userData['profile_picture_url'] ??
                            "https://cdn-icons-png.freepik.com/512/3177/3177440.png",
                      ),
                      radius: 18,
                    );
                  },
                ),
            ],
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
