import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static const packageEntitlements = {
    'pkg_2_4_year': 'access_basic',
    'pkg_10_year': 'access_pro',
    'pkg_nationality': 'access_max',
  };
  static Future<void>? _identityOperation;
  static final _verifiedTiers = <String?, String>{};

  /// Serialize identity changes so parallel screen loads cannot log each
  /// other out. Recheck Firebase after an in-flight change completes.
  static Future<void> ensureIdentity() async {
    while (_identityOperation != null) {
      await _identityOperation;
    }
    final operation = _identify();
    _identityOperation = operation;
    try {
      await operation;
    } finally {
      _identityOperation = null;
    }
  }

  static Future<void> _identify() async {
    if (!await Purchases.isConfigured) {
      throw StateError('RevenueCat is not configured');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final currentId = await Purchases.appUserID;
    if (uid != null && currentId != uid) {
      await Purchases.logIn(uid);
    } else if (uid == null && !await Purchases.isAnonymous) {
      _verifiedTiers.remove(null);
      await Purchases.logOut();
    }
  }

  static String tierFromEntitlements(Iterable<String> active) {
    final ids = active.toSet();
    if (ids.contains('access_max')) return 'nationality';
    if (ids.contains('access_pro')) return '10_years';
    if (ids.contains('access_basic')) return '2_years';
    return 'free';
  }

  static String tier(CustomerInfo info) =>
      tierFromEntitlements(info.entitlements.active.keys);

  /// RevenueCat entitlements grant access even if the Firestore mirror fails.
  static Future<String> currentTier() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      await ensureIdentity().timeout(const Duration(seconds: 20));
      final info = await Purchases.getCustomerInfo().timeout(
        const Duration(seconds: 20),
      );
      if (FirebaseAuth.instance.currentUser?.uid != uid) return 'free';
      return _verifiedTiers[uid] = tier(info);
    } catch (error) {
      debugPrint('RevenueCat access lookup failed: $error');
      // Only retain access previously returned by RevenueCat in this process.
      // A client-written Firestore field is not proof of a purchase.
      return FirebaseAuth.instance.currentUser?.uid == uid
          ? _verifiedTiers[uid] ?? 'free'
          : 'free';
    }
  }

  static Future<void> mirrorTier(CustomerInfo info, String? expectedUid) async {
    if (FirebaseAuth.instance.currentUser?.uid == expectedUid) {
      _verifiedTiers[expectedUid] = tier(info);
    }
    if (expectedUid == null ||
        FirebaseAuth.instance.currentUser?.uid != expectedUid) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(expectedUid)
          .set({'subscription_tier': tier(info)}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      debugPrint('Purchase succeeded; Firestore tier sync failed: $error');
    }
  }
}
