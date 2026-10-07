import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // ⚠️ TEMPORARY IMPORT
import 'package:csv/csv.dart'; // ⚠️ TEMPORARY IMPORT
import 'package:cloud_firestore/cloud_firestore.dart'; // ⚠️ TEMPORARY IMPORT
import '../dashboard/dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // =========================================================================
  // ⚠️ TEMPORARY FUNCTION TO UPLOAD CSV DATA TO FIREBASE (DELETE LATER)
  // =========================================================================
  Future<void> _uploadAllModulesToFirebase(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Uploading to Firebase... Please wait!"),
        duration: Duration(seconds: 5),
      ),
    );

    final Map<String, String> csvFiles = {
      'histoire': 'assets/mock_test/histoire_french_only.csv',
      'droits': 'assets/mock_test/droits_devoirs_final_clean.csv',
      'institutions': 'assets/mock_test/institutions_french_only.csv',
      'republique': 'assets/mock_test/republique_french_only.csv',
      'situations': 'assets/mock_test/situations_french_only.csv',
      'societe': 'assets/mock_test/societe_french_only.csv',
    };

    final firestore = FirebaseFirestore.instance;

    for (var entry in csvFiles.entries) {
      String moduleName = entry.key;
      String filePath = entry.value;

      try {
        final csvData = await rootBundle.loadString(filePath);
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

        String? currentQuestion;
        List<String> currentOptions = [];
        int currentAnswerIndex = 0;

        Future<void> saveQuestion() async {
          if (currentQuestion != null && currentOptions.isNotEmpty) {
            await firestore.collection('questions').add({
              'module': moduleName,
              'questionText': currentQuestion,
              'options': currentOptions,
              'correctAnswerIndex': currentAnswerIndex,
            });
          }
        }

        for (int i = 0; i < rows.length; i++) {
          var row = rows[i];
          // Skip empty rows
          if (row.isEmpty || row.length < 2 || row[0].toString().trim().isEmpty)
            continue;

          String rowType = row[0].toString().trim().toLowerCase();

          if (rowType == 'question') {
            await saveQuestion(); // Save previous question before starting new one
            currentQuestion = row[1].toString();
            currentOptions = [];
            currentAnswerIndex = 0;
          } else if (rowType == 'answer') {
            currentOptions.add(row[1].toString());
            // Check if this option is marked as correct (1.0 or 1)
            bool isCorrect = row.any(
              (element) =>
                  element.toString().trim() == '1.0' ||
                  element.toString().trim() == '1',
            );
            if (isCorrect) {
              currentAnswerIndex = currentOptions.length - 1;
            }
          }
        }
        await saveQuestion(); // Save the very last question
        print("✅ Successfully uploaded: $moduleName");
      } catch (e) {
        print("❌ Error uploading $moduleName: $e");
      }
    }

    print("🚀🚀 ALL 6 MODULES UPLOADED SUCCESSFULLY!");
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ All 6 Modules Uploaded Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PrepCivic Store"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =========================================================================
          // ⚠️ TEMPORARY UPLOAD BUTTON (DELETE LATER)
          // =========================================================================
          ElevatedButton.icon(
            onPressed: () => _uploadAllModulesToFirebase(context),
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text(
              "UPLOAD FIREBASE DATA",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 20),

          // =========================================================================
          const Text(
            "Select Your Course",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "Choose the plan that fits your residency goal.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // PACKAGE 1: Naturalization
          _buildPackageCard(
            context,
            title: "Naturalisation Française",
            subtitle: "সিভিক প্রস্তুতি (Citizenship)",
            price: "€50",
            color: Colors.indigo,
            isPopular: true,
          ),

          // PACKAGE 2: 10 Years
          _buildPackageCard(
            context,
            title: "Resident Card (10 Years)",
            subtitle: "১০ বছরের রেসিডেন্সি কার্ড",
            price: "€40",
            color: Colors.blue.shade700,
          ),

          // PACKAGE 3: 2-4 Years
          _buildPackageCard(
            context,
            title: "Resident Card (2-4 Years)",
            subtitle: "২/৪ বছরের কার্ডের আবেদন",
            price: "€30",
            color: Colors.blue.shade500,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required Color color,
    bool isPopular = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image Placeholder
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.school, size: 50, color: Colors.white24),
                ),
                if (isPopular)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "POPULAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Bengali Text
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to Dashboard with specific title and color
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DashboardScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                      child: const Text("Enroll Now"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
