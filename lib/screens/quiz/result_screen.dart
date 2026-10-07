import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟 The magic package

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final VoidCallback onRestart;
  final VoidCallback? onDashboard;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.onRestart,
    this.onDashboard,
  });

  @override
  Widget build(BuildContext context) {
    // Logic: 60% is generally the passing mark for French naturalization simulations
    final percentage = (totalQuestions == 0 ? 0 : score / totalQuestions * 100)
        .round();
    final isPassed = percentage >= 60;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Dynamic Illustration Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed
                      ? Icons.emoji_events_rounded
                      : Icons.error_outline_rounded,
                  size: 100,
                  color: isPassed ? Colors.green : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 30),

              // 2. Bilingual Feedback
              Text(
                isPassed
                    ? 'congratulations'.tr()
                    : 'keep_revising'.tr(), // 🌟 REPLACED
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPassed
                    ? 'passed_msg'
                          .tr() // 🌟 REPLACED
                    : 'failed_msg'.tr(), // 🌟 REPLACED
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // 3. The Score Visualization Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'your_score_upper'.tr(), // 🌟 REPLACED
                      style: GoogleFonts.poppins(
                        letterSpacing: 2,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "$score",
                          style: GoogleFonts.poppins(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: isPassed ? Colors.green : Colors.redAccent,
                          ),
                        ),
                        Text(
                          " / $totalQuestions",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "$percentage% ${'success_rate'.tr()}", // 🌟 REPLACED
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isPassed
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // 4. Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRestart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'restart_test'.tr(), // 🌟 REPLACED
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDashboard?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.indigo),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'dashboard'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
