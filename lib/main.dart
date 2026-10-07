import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟 NEW IMPORT
import 'firebase_options.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // 🌟 NEW (RevenueCat): SDK Import
import 'dart:io' show Platform; // 🌟 NEW (RevenueCat): Platform Check Import
// import 'services/translation_service.dart'; // ⚠️ OBSOLETE: easy_localization replaces this
import 'screens/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 NEW: Initialize the Localization Engine BEFORE the app starts
  await EasyLocalization.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase Initialized Successfully.");
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  // 🌟 NEW (RevenueCat): Initialize RevenueCat SDK
  try {
    await Purchases.setLogLevel(
      kDebugMode ? LogLevel.debug : LogLevel.warn,
    ); // লগের জন্য, প্রোডাকশনে যাওয়ার আগে এটা মুছে দিতে পারেন

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      // আপনার দেওয়া Android API Key
      configuration = PurchasesConfiguration(
        "goog_HbCDeYMYQYNfprQlhnMSqfbQKeY",
      );
    } else if (Platform.isIOS) {
      // যদি ভবিষ্যতে iOS আনেন, তবে এখানে iOS এর Key বসবে। আপাতত একটা placeholder রাখা হলো।
      configuration = PurchasesConfiguration(
        "appl_SQtkiJdmGcjrgwCcyhxyRCNZuUL",
      );
    } else {
      throw UnsupportedError('Purchases are supported on Android and iOS');
    }
    await Purchases.configure(configuration);
    print("RevenueCat Initialized Successfully.");
  } catch (e) {
    print("RevenueCat initialization error: $e");
  }

  // await TranslationService.init(); // Disabled to prevent conflicts with easy_localization

  // 🌟 NEW: Wrap your app with EasyLocalization
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('fr'),
        Locale('bn'),
        Locale('ar'),
        Locale('ur'),
        Locale('ps'),
        Locale('en'), // 🌟 ADDED ENGLISH LOCALE
      ],
      path: 'assets/translations', // Make sure your JSON files are here!
      useFallbackTranslations: true,
      fallbackLocale: const Locale(
        'fr',
      ), // If a translation fails, it defaults to French
      child: const PrepCivicApp(),
    ),
  );
}

class PrepCivicApp extends StatelessWidget {
  const PrepCivicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrepCivic France',
      debugShowCheckedModeBanner: false,

      // 🌟 NEW: Connect the app's internal logic to the localization engine
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}
