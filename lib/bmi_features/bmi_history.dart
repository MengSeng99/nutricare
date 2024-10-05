import 'package:flutter/material.dart';

class BmiHistoryScreen extends StatelessWidget {
  const BmiHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bmi History Screen'),
      ),
      body: const Center(
        child: Text('Welcome to the Bmi History Screen!'),
      ),
    );
  }
}
