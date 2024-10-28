import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_details.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> chatList = [];
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid ?? ""; // Ensure it's safe
    _retrieveChatData();
  }

  Future<void> _retrieveChatData() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('chats').get();

      if (querySnapshot.docs.isEmpty) {
        print("No chats found.");
        return;
      }

      for (var doc in querySnapshot.docs) {
        List<String> users = List<String>.from((doc.data() as Map<String, dynamic>)['users'] ?? []);
        var specialistId = users.first == currentUserId ? users.last : users.first; // Specify the specialist ID

        // Fetch specialist data
        DocumentSnapshot specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
        var specialistData = specialistDoc.data() as Map<String, dynamic>?;

        // Fetch the latest message from the chat
        QuerySnapshot messagesSnapshot = await _firestore.collection('chats').doc(doc.id)
            .collection('messages')
            .orderBy('timestamp', descending: true) // Order by most recent timestamp
            .limit(1) // Get only the latest message
            .get();

        var lastMessageDoc = messagesSnapshot.docs.isNotEmpty ? messagesSnapshot.docs.first : null; // Get the first doc
        var lastMessage = lastMessageDoc?.data() as Map<String, dynamic>?;

        if (lastMessage != null) {
          String messageText = lastMessage['text'] ?? "No text";
          // Check if the last message is from the current user and format accordingly
          if (lastMessage['senderId'] == currentUserId) {
            messageText = "You: " + messageText; // Prepend "You: " for messages from the user
          }
          Timestamp timestamp = lastMessage['timestamp'] as Timestamp? ?? Timestamp.now();

          chatList.add({
            'chatId': doc.id,
            'lastMessage': messageText,
            'lastTimestamp': timestamp,
            'specialistName': specialistData?['name'] ?? "Unknown",
            'profilePictureUrl': specialistData?['profile_picture_url'] ?? "",
            'specialistId': specialistId, // Store specialistId
          });
        } else {
          print("No messages found in chat ${doc.id}");
        }
      }

      setState(() {});
    } catch (error) {
      print("Error retrieving chat data: $error");
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 0) {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Chat List",
          style: TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: chatList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: chatList.length,
              itemBuilder: (context, index) {
                var chat = chatList[index];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: CircleAvatar(
                      backgroundImage: chat['profilePictureUrl'].isNotEmpty
                          ? NetworkImage(chat['profilePictureUrl'])
                          : AssetImage("images/user_profile/default_profile.png") as ImageProvider,
                    ),
                    title: Text(
                      chat['specialistName'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      chat['lastMessage'],
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    trailing: Text(
                      _formatTimestamp(chat['lastTimestamp']),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            chatId: chat['chatId'],
                            currentUserId: currentUserId,
                            receiverId: chat['specialistId'],
                            specialistName: chat['specialistName'],
                            profilePictureUrl: chat['profilePictureUrl'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}