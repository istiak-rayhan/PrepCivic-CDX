import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'language_screen.dart'; // Navigates here next

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _onIntroEnd(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LanguageScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Civic Exam Prep",
          body: "Ace your French Civic interview.",
          image: const Center(
            child: Icon(Icons.school, size: 100, color: Color(0xFF4F46E5)),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        PageViewModel(
          title: "Bilingual Support",
          body: "Explanations in Bengali & French.",
          image: const Center(
            child: Icon(Icons.translate, size: 100, color: Color(0xFF4F46E5)),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
