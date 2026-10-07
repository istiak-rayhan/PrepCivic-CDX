import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟 The magic package
import 'package:firebase_auth/firebase_auth.dart'; // 🌟 Required for Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 Required for Firebase
import '../../services/database_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Map<String, dynamic>> results = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCombinedStats();
  }

  // 🌟 THE UNIFIED DATA PIPELINE 🌟
  Future<void> _loadCombinedStats() async {
    List<Map<String, dynamic>> combinedResults = [];

    // 1. Fetch Practice Sessions from SQLite (Local)
    try {
      final sqliteData = await DatabaseHelper.instance.getResults();
      combinedResults.addAll(sqliteData);
    } catch (e) {
      print("Error loading SQLite stats: $e");
    }

    // 2. Fetch Mock Tests from Firebase (Remote)
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('mock_scores')
            .get();

        for (var doc in querySnapshot.docs) {
          final data = doc.data();

          // Safely handle Firestore timestamps
          final timestamp = data['timestamp'] as Timestamp?;
          final dateStr = timestamp != null
              ? timestamp.toDate().toIso8601String()
              : DateTime.now().toIso8601String();

          combinedResults.add({
            'score': data['score'] ?? 0,
            'total_questions': data['total'] ?? 0,
            'date': dateStr,
            'test_type': 'mock_exam', // We use a translation key here!
          });
        }
      }
    } catch (e) {
      print("Error loading Firebase stats: $e");
    }

    // 3. Sort Everything by Date (Newest First)
    combinedResults.sort((a, b) {
      DateTime dateA =
          DateTime.tryParse(a['date'].toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      DateTime dateB =
          DateTime.tryParse(b['date'].toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA); // Reverse chronological order
    });

    if (mounted) {
      setState(() {
        results = combinedResults;
        isLoading = false;
      });
    }
  }

  // Calculate the overall average score for the header
  int _calculateOverallAverage() {
    if (results.isEmpty) return 0;
    double totalPercentage = 0;
    for (var item in results) {
      final score = item['score'];
      final total = item['total_questions'];
      if (total > 0) {
        totalPercentage += (score / total) * 100;
      }
    }
    return (totalPercentage / results.length).round();
  }

  // Helper to translate the test type cleanly
  String _getLocalizedTestType(String type) {
    if (type.toLowerCase().contains('mock')) {
      return 'mock_exam'.tr().toUpperCase();
    }
    return 'practice_session'.tr().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final int averageScore = _calculateOverallAverage();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'my_stats'.tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_history'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // --- SUMMARY HEADER ---
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'average_score'.tr().toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$averageScore",
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "%",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- HISTORY LIST ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'recent_sessions'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final score = item['score'];
                      final total = item['total_questions'];
                      final percentage = total > 0 ? (score / total) * 100 : 0;
                      final bool isPass =
                          percentage >= 60; // Standard passing grade

                      // Parse date nicely
                      final dateStr = item['date'].toString().substring(0, 10);
                      final displayType = _getLocalizedTestType(
                        item['test_type'].toString(),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isPass
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPass ? Icons.check_circle : Icons.cancel,
                              color: isPass ? Colors.green : Colors.redAccent,
                            ),
                          ),
                          title: Text(
                            isPass ? 'success'.tr() : 'fail'.tr(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            "$dateStr • $displayType", // 🌟 Dynamically shows Mock vs Practice
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "$score / $total",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isPass
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                              ),
                              Text(
                                "${percentage.round()}%",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
