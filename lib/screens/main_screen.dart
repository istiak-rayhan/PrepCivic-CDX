import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async'; // 🌟 Required for Timer
import '../config/theme.dart';
import '../services/purchase_service.dart';

import 'dashboard/home_tab.dart';
import 'practice/category_selection_screen.dart';
import 'quiz/quiz_screen.dart';
import 'dashboard/profile_tab.dart';
import 'premium/subscription_screen.dart'; // 🌟 Required for Paywall routing

class MainScreen extends StatefulWidget {
  final String userPackage;
  const MainScreen({super.key, required this.userPackage});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late String _accessTier;
  bool _refreshingAccess = false;
  bool _checkingUpsell = false;
  Timer? _upsellTimer; // 🌟 The Timer instance

  // Build tabs dynamically
  List<Widget> get _tabs => [
    HomeTab(userPackage: _accessTier),
    CategorySelectionScreen(userPackage: _accessTier),
    QuizScreen(
      topicTitle: 'mock_exam'.tr(),
      onDashboard: () => setState(() => _currentIndex = 0),
    ),
    ProfileTab(userPackage: _accessTier, isActive: _currentIndex == 3),
  ];

  @override
  void initState() {
    super.initState();
    _accessTier = widget.userPackage;
    _startUpsellTimer();
  }

  Future<void> _refreshAccess() async {
    if (_refreshingAccess) return;
    _refreshingAccess = true;
    try {
      final tier = await PurchaseService.currentTier();
      if (!mounted) return;
      if (tier != _accessTier) setState(() => _accessTier = tier);
      if (tier != 'free') _upsellTimer?.cancel();
    } finally {
      _refreshingAccess = false;
    }
  }

  @override
  void dispose() {
    _upsellTimer
        ?.cancel(); // 🌟 CRITICAL: Stop timer when screen is destroyed (e.g., Logout)
    super.dispose();
  }

  // 🌟 THE AGGRESSIVE UPSELL TIMER LOGIC
  void _startUpsellTimer() {
    _upsellTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (!mounted ||
          _checkingUpsell ||
          ModalRoute.of(context)?.isCurrent != true)
        return;
      _checkingUpsell = true;
      try {
        final tier = await PurchaseService.currentTier();
        if (!mounted) return;
        if (tier != 'free') {
          _upsellTimer?.cancel();
        } else if (ModalRoute.of(context)?.isCurrent == true) {
          _showPremiumPopup();
        }
      } finally {
        _checkingUpsell = false;
      }
    });
  }

  // 🌟 THE SAFE PAYWALL POPUP (Same as Gatekeeper)
  void _showPremiumPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force interaction
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Column(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 50,
              ),
              const SizedBox(height: 10),
              Text(
                "Passez à Premium", // "Upgrade to Premium"
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        content: Text(
          "Débloquez tous les modules, les tests illimités et supprimez ces interruptions !",
          style: GoogleFonts.poppins(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 🌟 SAFETY PROTOCOL: Just close the popup
              Navigator.of(ctx).pop();
            },
            child: Text(
              "Plus tard", // "Later"
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // 🌟 SAFETY PROTOCOL: Close popup first, THEN navigate
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: Text(
              "Voir les forfaits", // "View Packages"
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _refreshAccess();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.home),
              activeIcon: const Icon(CupertinoIcons.house_fill),
              label: 'nav_home'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.book),
              activeIcon: const Icon(CupertinoIcons.book_fill),
              label: 'nav_courses'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.timer),
              activeIcon: const Icon(CupertinoIcons.timer_fill),
              label: 'nav_exam'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.person),
              activeIcon: const Icon(CupertinoIcons.person_fill),
              label: 'nav_profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
