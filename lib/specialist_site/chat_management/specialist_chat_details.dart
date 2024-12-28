import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:nutricare/specialist_site/client_management/client_details.dart';
import 'package:url_launcher/url_launcher.dart';

class SpecialistChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String receiverId;
  final String clientName; // Changed to clientName
  final String profilePictureUrl;

  const SpecialistChatDetailScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.receiverId,
    required this.clientName, // Changed to clientName
    required this.profilePictureUrl,
  });

  @override
  _SpecialistChatDetailScreenState createState() => _SpecialistChatDetailScreenState();
}

class _SpecialistChatDetailScreenState extends State<SpecialistChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.profilePictureUrl.isNotEmpty
                  ? NetworkImage(widget.profilePictureUrl)
                  : const AssetImage('images/user_profile/default_profile.png') as ImageProvider,
            ),
            SizedBox(width: 16),
            Text(
              widget.clientName, // Changed to clientName
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
                    clientId: widget.receiverId,
                    clientName: widget.clientName,
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
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                // Scroll to the bottom after messages are fetched
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController, // Set the controller here
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index].data() as Map<String, dynamic>;
                    bool isMe = messageData['senderId'] == widget.currentUserId;

                    // Determine visibility of profile picture based on the previous message
                    bool showProfilePicture = true; // Default for first message
                    if (index > 0) {
                      var previousMessageData =
                          messages[index - 1].data() as Map<String, dynamic>;
                      showProfilePicture = previousMessageData['senderId'] !=
                          messageData['senderId'];
                    }

                    return _buildMessageBubble(context, messageData, isMe,
                        showProfilePicture);
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
                  onPressed: () => _pickImageAndSend(context),
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
                    _sendMessage(widget.chatId);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageAndSend(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      _showImagePreviewDialog(context, file);
    }
  }

  void _showImagePreviewDialog(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Image Preview",
              style: TextStyle(
                  color: Color.fromARGB(255, 90, 113, 243),
                  fontWeight: FontWeight.bold)),
          content: Image.file(file, height: 200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text("Send", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _uploadAndSendFile(file, isImage: true);
              },
            ),
          ],
        );
      },
    );
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
    String fileName = file.path.split('/').last;
    String path = isImage
        ? 'chat_images/${DateTime.now().millisecondsSinceEpoch}.${fileName.split('.').last}'
        : 'chat_files/${DateTime.now().millisecondsSinceEpoch}.$fileName';

    Reference ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    String downloadUrl = await ref.getDownloadURL();

    String messageType = isImage ? 'image' : 'document';

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': isImage ? null : fileName,
      'fileUrl': downloadUrl,
      'isImage': isImage,
      'senderId': widget.currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'messageType': messageType,
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
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'messageType': 'text',
      });
      _messageController.clear();
    }
  }

  Widget _buildMessageBubble(BuildContext context,
    Map<String, dynamic> messageData, bool isMe, bool showProfilePicture,
    [DateTime? previousMessageDate]) {
    // Get the timestamp
    Timestamp? timestamp = messageData['timestamp'];

    // Format the timestamp
    String displayTime = _formatTimestamp(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Only show the profile picture for messages not from the sender
          if (!isMe && showProfilePicture)
            CircleAvatar(
              backgroundImage: NetworkImage(widget.profilePictureUrl.isNotEmpty
                  ? widget.profilePictureUrl
                  : 'https://cdn-icons-png.freepik.com/512/3177/3177440.png'), // Default image if empty
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
                    if (messageData['messageType'] == 'image')
                      GestureDetector(
                        onTap: () {
                          launch(messageData['fileUrl']);
                        },
                        child: Image.network(
                          messageData['fileUrl'],
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (messageData['messageType'] == 'document')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.attach_file,
                              color: isMe ? Colors.white : Colors.black54),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              launch(messageData['fileUrl']);
                            },
                            child: Text(
                              messageData['text'] ?? "File sent",
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black),
                            ),
                          ),
                        ],
                      )
                    else // text message
                      Text(
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
                        color: isMe ? Colors.white : Colors.grey,
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
          if (isMe)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('specialists')
                  .doc(widget.currentUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return CircleAvatar(
                    backgroundImage: const AssetImage(
                        'images/user_profile/default_profile.png') as ImageProvider,
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
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }
}