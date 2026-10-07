import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'purchase_service.dart';

abstract class BillingClient {
  const BillingClient();
  String? get accountId;
  Future<void> identify();
  Future<Offerings> offerings();
  Future<CustomerInfo> purchase(Package package);
  Future<CustomerInfo> restore();
  Future<void> mirror(CustomerInfo info, String? accountId);
}

class RevenueCatBillingClient extends BillingClient {
  const RevenueCatBillingClient();
  @override
  String? get accountId => FirebaseAuth.instance.currentUser?.uid;
  @override
  Future<void> identify() => PurchaseService.ensureIdentity();
  @override
  Future<Offerings> offerings() => Purchases.getOfferings();
  @override
  Future<CustomerInfo> purchase(Package package) async =>
      (await Purchases.purchase(PurchaseParams.package(package))).customerInfo;
  @override
  Future<CustomerInfo> restore() => Purchases.restorePurchases();
  @override
  Future<void> mirror(CustomerInfo info, String? accountId) =>
      PurchaseService.mirrorTier(info, accountId);
}
