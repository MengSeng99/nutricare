import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String specialistName = "Dr. John Doe"; // Example specialist name
  final String specialistImageUrl = 'https://hips.hearstapps.com/hmg-prod/images/portrait-of-a-happy-young-doctor-in-his-clinic-royalty-free-image-1661432441.jpg';

  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(specialistImageUrl),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Text(specialistName,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5A71F3),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: const [
                ChatBubble(
                  isSentByUser: true,
                  message: "Hello, I have a question about my diet plan.",
                ),
                ChatBubble(
                  isSentByUser: false,
                  message: "Sure! How can I assist you today?",
                ),
                ChatBubble(
                  isSentByUser: true,
                  message: "Can I replace my lunch item with something else?",
                ),
                ChatBubble(
                  isSentByUser: false,
                  message:
                      "Yes, you can replace it with any food items in the same category.",
                ),
              ],
            ),
          ),
          const ChatInputField(),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isSentByUser;
  final String message;

  const ChatBubble({super.key, required this.isSentByUser, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSentByUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isSentByUser ? 12 : 0),
            bottomRight: Radius.circular(isSentByUser ? 0 : 12),
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  const ChatInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // IconButton(
          //   icon: const Icon(Icons.camera_alt, color: Color(0xFF5A71F3)),
          //   onPressed: () {
          //     // Handle camera functionality
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.mic, color: Color(0xFF5A71F3)),
          //   onPressed: () {
          //     // Handle audio functionality
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.attach_file, color: Color(0xFF5A71F3)),
            onPressed: () {
              // Handle file upload functionality
            },
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Type your message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF5A71F3)),
            onPressed: () {
              // Handle send button functionality
            },
          ),
        ],
      ),
    );
  }
}
