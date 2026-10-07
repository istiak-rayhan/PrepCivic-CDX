import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../config/theme.dart';
import '../main_screen.dart';
import '../auth/register_screen.dart';

class PackageScreen extends StatelessWidget {
  const PackageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'choose_profile_title'.tr(),
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'choose_profile_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // FREE TIER
            _buildPackageCard(
              context,
              title: 'free_trial_title'.tr(),
              subtitle: 'free_trial_subtitle'.tr(),
              price: 'free_trial_price'.tr(),
              color: Colors.green,
              packageId: 'free',
              isPopular: false,
              isFree: true,
            ),
            const SizedBox(height: 20),

            // Option 1: 2-4 Years
            _buildPackageCard(
              context,
              title: 'pkg_2_years_title'.tr(),
              subtitle: 'pkg_2_years_sub'.tr(),
              price: 'premium'.tr(),
              color: Colors.blueAccent,
              packageId: '2_year',
              isPopular: false,
            ),
            const SizedBox(height: 20),

            // Option 2: 10 Years +
            _buildPackageCard(
              context,
              title: 'pkg_10_years_title'.tr(),
              subtitle: 'pkg_10_years_sub'.tr(),
              price: 'premium'.tr(),
              color: Colors.orange,
              packageId: '10_year',
              isPopular: true,
            ),
            const SizedBox(height: 20),

            // Option 3: Naturalisation
            _buildPackageCard(
              context,
              title: 'pkg_nat_title'.tr(),
              subtitle: 'pkg_nat_sub'.tr(),
              price: 'premium'.tr(),
              color: AppTheme.secondaryColor,
              packageId: 'citizenship',
              isPopular: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required Color color,
    required String packageId,
    bool isPopular = false,
    bool isFree = false,
  }) {
    return GestureDetector(
      onTap: () async {
        if (isFree) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isGuest', true);

          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(userPackage: 'free'),
              ),
            );
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterScreen(selectedPackage: packageId),
            ),
          );
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPopular ? color : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFree ? Icons.lock_open : Icons.lock,
                    color: color,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          price,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[300],
                  size: 16,
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: -10,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'popular_badge'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
