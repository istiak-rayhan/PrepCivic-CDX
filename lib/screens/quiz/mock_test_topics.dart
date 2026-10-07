import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class MockTestTopicsScreen extends StatelessWidget {
  const MockTestTopicsScreen({super.key});

  // These exactly match the file names we uploaded to Firebase
  final List<String> modules = const [
    'Histoire',
    'Droits',
    'Institutions',
    'Republique',
    'Situations',
    'Societe',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Examen Blanc (Mock Test)",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.withOpacity(0.1),
                child: const Icon(Icons.gavel, color: Colors.indigo),
              ),
              title: Text(
                module,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: const Text(
                "10 Questions Aléatoires",
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.indigo,
              ),
              onTap: () {
                // Routes directly to your Firebase-connected QuizScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(topicTitle: module),
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
