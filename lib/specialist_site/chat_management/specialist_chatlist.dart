import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'specialist_chat_details.dart';

class SpecialistChatListScreen extends StatefulWidget {
  const SpecialistChatListScreen({super.key});

  @override
  _SpecialistChatListScreenState createState() =>
      _SpecialistChatListScreenState();
}

class _SpecialistChatListScreenState extends State<SpecialistChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> chatList = [];
  late String specialistId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    specialistId = _auth.currentUser?.uid ?? "";
    _retrieveChatData();
  }

  String _truncateMessage(String message, {int wordLimit = 10}) {
    List<String> words = message.split(' ');

    if (words.length <= wordLimit) {
      return message; // Return the original message if it's within the limit
    } else {
      return '${words.take(wordLimit).join(' ')}...'; // Return truncated message with ellipsis
    }
  }

  Future<void> _retrieveChatData() async {
    try {
      // Query chats where the current specialist is a part of
      QuerySnapshot querySnapshot = await _firestore
          .collection('chats')
          .where('users', arrayContains: specialistId) // Filter by specialist
          .get();

      if (querySnapshot.docs.isEmpty) {
        // print("No chats found for the specialist.");
        return;
      }

      for (var doc in querySnapshot.docs) {
        List<String> users =
            List<String>.from((doc.data() as Map<String, dynamic>)['users'] ?? []);
        var clientId = users.first == specialistId ? users.last : users.first; // Specify the client ID

        // Fetch client data
        DocumentSnapshot clientDoc =
            await _firestore.collection('users').doc(clientId).get();
        var clientData = clientDoc.data() as Map<String, dynamic>?;

        // Fetch the latest message from the chat
        QuerySnapshot messagesSnapshot = await _firestore
            .collection('chats')
            .doc(doc.id)
            .collection('messages')
            .orderBy('timestamp', descending: true) // Order by most recent timestamp
            .limit(1) // Get only the latest message
            .get();

        var lastMessageDoc = messagesSnapshot.docs.isNotEmpty
            ? messagesSnapshot.docs.first
            : null; // Get the first doc
        var lastMessage = lastMessageDoc?.data() as Map<String, dynamic>?;

        if (lastMessage != null) {
          String messageText = lastMessage['text'] ?? "No text";
          // Check if the last message is from the current specialist and format accordingly
          if (lastMessage['senderId'] == specialistId) {
            messageText = "You: $messageText"; // Prepend "You: " for specialist messages
          }

          // Truncate the message if it's too long
          messageText = _truncateMessage(messageText);

          Timestamp timestamp = lastMessage['timestamp'] as Timestamp? ?? Timestamp.now();

          chatList.add({
            'chatId': doc.id,
            'lastMessage': messageText,
            'lastTimestamp': timestamp,
            'clientName': clientData?['name'] ?? "Unknown",
            'profilePictureUrl': clientData?['profile_pic'] ?? "",
            'clientId': clientId, // Store clientId
          });
        }
      }

      // Sort chatList by lastTimestamp
      chatList.sort((a, b) => b['lastTimestamp'].compareTo(a['lastTimestamp'])); // Sort descending order

      setState(() {
        _isLoading = false; // Set loading to false when done
      });
    } catch (error) {
      // print("Error retrieving chat data: $error");
      setState(() {
        _isLoading = false; // Set loading to false even on error
      });
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
          "Client Chats",
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : chatList.isEmpty
              ? Center(
                  child: Text(
                  "No chat history found.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ))
              : ListView.builder(
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    var chat = chatList[index];

                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
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
                          chat['clientName'],
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
                              builder: (context) => SpecialistChatDetailScreen(
                                chatId: chat['chatId'],
                                currentUserId: specialistId,
                                receiverId: chat['clientId'],
                                clientName: chat['clientName'],
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