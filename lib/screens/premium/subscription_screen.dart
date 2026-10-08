import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/billing_client.dart';
import 'package:flutter/services.dart';
import '../../services/purchase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  final BillingClient billing;
  const SubscriptionScreen({
    super.key,
    this.billing = const RevenueCatBillingClient(),
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Package? _pkg2to4Year;
  Package? _pkg10Year;
  Package? _pkgNationality;

  String _selectedPackageId = 'pkg_2_4_year';
  bool _isLoading = true;
  String? _packageError;

  Package? get _selectedPackage => switch (_selectedPackageId) {
    'pkg_2_4_year' => _pkg2to4Year,
    'pkg_10_year' => _pkg10Year,
    'pkg_nationality' => _pkgNationality,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    setState(() {
      _isLoading = true;
      _packageError = null;
      _pkg2to4Year = null;
      _pkg10Year = null;
      _pkgNationality = null;
    });
    try {
      await widget.billing.identify().timeout(const Duration(seconds: 20));
      final offerings = await widget.billing.offerings().timeout(
        const Duration(seconds: 20),
      );
      if (!mounted) return;
      final current = offerings.current;
      if (current == null) {
        debugPrint(
          'RevenueCat: no current offering. Available offering IDs: '
          '${offerings.all.keys.join(', ')}',
        );
      }
      setState(() {
        for (final pkg in current?.availablePackages ?? <Package>[]) {
          debugPrint(
            'RevenueCat package ${pkg.identifier}, '
            'product ${pkg.storeProduct.identifier}',
          );
          switch (pkg.identifier) {
            case 'pkg_2_4_year':
              _pkg2to4Year = pkg;
            case 'pkg_10_year':
              _pkg10Year = pkg;
            case 'pkg_nationality':
              _pkgNationality = pkg;
          }
        }
        if (_selectedPackage == null) {
          final available = _pkg2to4Year ?? _pkg10Year ?? _pkgNationality;
          if (available != null) _selectedPackageId = available.identifier;
        }
        if (_pkg2to4Year == null ||
            _pkg10Year == null ||
            _pkgNationality == null) {
          _packageError = 'packages_unavailable';
        }
      });
    } catch (error) {
      debugPrint('RevenueCat offerings failed: $error');
      if (mounted) {
        final unavailableBilling =
            error is PlatformException &&
            PurchasesErrorHelper.getErrorCode(error) ==
                PurchasesErrorCode.purchaseNotAllowedError;
        setState(
          () => _packageError = unavailableBilling
              ? 'billing_not_supported'
              : 'packages_load_error',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _message(String key, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(key.tr()),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _processSubscription() async {
    if (_isLoading) return;
    final package = _selectedPackage;
    if (package == null) {
      _message('packages_unavailable');
      return;
    }
    final entitlement =
        PurchaseService.packageEntitlements[package.identifier]!;
    final uid = widget.billing.accountId;
    setState(() => _isLoading = true);
    try {
      await widget.billing.identify();
      if (widget.billing.accountId != uid) {
        _message('account_changed');
        return;
      }
      final result = await widget.billing.purchase(package);
      if (widget.billing.accountId != uid) {
        _message('account_changed');
        return;
      }
      if (!result.entitlements.active.containsKey(entitlement)) {
        debugPrint(
          'Purchase returned without expected entitlement $entitlement; '
          'active: ${result.entitlements.active.keys}',
        );
        _message('purchase_access_pending');
        return;
      }
      await widget.billing.mirror(result, uid);
      if (!mounted) return;
      _message('payment_success', success: true);
      Navigator.pop(context, true);
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      debugPrint('RevenueCat purchase failed: $code; ${error.message}');
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        _message(
          code == PurchasesErrorCode.paymentPendingError
              ? 'purchase_access_pending'
              : 'payment_error',
        );
      }
    } catch (error) {
      debugPrint('Purchase failed: $error');
      _message('payment_error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    if (_isLoading) return;
    final uid = widget.billing.accountId;
    setState(() => _isLoading = true);
    try {
      await widget.billing.identify();
      if (widget.billing.accountId != uid) {
        _message('account_changed');
        return;
      }
      final info = await widget.billing.restore();
      if (widget.billing.accountId != uid) {
        _message('account_changed');
        return;
      }
      await widget.billing.mirror(info, uid);
      if (!mounted) return;
      if (PurchaseService.tier(info) != 'free') {
        _message('restore_success', success: true);
        Navigator.pop(context, true);
      } else {
        _message('restore_empty');
      }
    } catch (error) {
      debugPrint('RevenueCat restore failed: $error');
      _message('restore_error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'premium_plans_title'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'premium_plans_subtitle'.tr(),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                _isLoading && _pkg2to4Year == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.indigo),
                      )
                    : Column(
                        children: [
                          if (_packageError != null) ...[
                            Text(
                              _packageError!.tr(),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _fetchPackages,
                              child: Text('retry'.tr()),
                            ),
                          ],
                          _buildPlanCard(
                            package: _pkg2to4Year,
                            fallbackId: 'pkg_2_4_year',
                            title: 'tier_2_4_years'.tr(),

                            features: 'features_2_4_years'.tr(),
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 15),
                          _buildPlanCard(
                            package: _pkg10Year,
                            fallbackId: 'pkg_10_year',
                            title: 'tier_10_years'.tr(),

                            features: 'features_10_years'.tr(),
                            icon: Icons.star_border_rounded,
                            isPopular: true,
                          ),
                          const SizedBox(height: 15),
                          _buildPlanCard(
                            package: _pkgNationality,
                            fallbackId: 'pkg_nationality',
                            title: 'tier_nationality'.tr(),

                            features: 'features_nationality'.tr(),
                            icon: Icons.account_balance_outlined,
                          ),
                        ],
                      ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 60),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          onPressed: _isLoading || _selectedPackage == null
                              ? null
                              : _processSubscription,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'btn_subscribe'.tr(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      child: Text(
                        'later'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'lifetime_legal_disclaimer'.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        InkWell(
                          onTap: () async {
                            final url = Uri.parse(
                              'https://prepcivic.com/terms',
                            );
                            if (await canLaunchUrl(url)) await launchUrl(url);
                          },
                          child: Text(
                            'terms_of_use'.tr(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.indigo,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Text(
                          "   •   ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        InkWell(
                          onTap: () async {
                            final url = Uri.parse(
                              'https://prepcivic.com/privacy',
                            );
                            if (await canLaunchUrl(url)) await launchUrl(url);
                          },
                          child: Text(
                            'privacy_policy'.tr(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.indigo,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: _isLoading ? null : _restorePurchases,
                      child: Text(
                        'restore_purchases'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required Package? package,
    required String fallbackId,
    required String title,
    required String features,
    required IconData icon,
    bool isPopular = false,
  }) {
    String currentId = package?.identifier ?? fallbackId;
    bool isSelected = _selectedPackageId == currentId;
    String displayPrice =
        package?.storeProduct.priceString ?? 'plan_unavailable'.tr();

    return GestureDetector(
      onTap: _isLoading || package == null
          ? null
          : () => setState(() => _selectedPackageId = currentId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.indigo.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'popular_badge'.tr(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? Colors.indigo : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.indigo : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    displayPrice,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.indigo : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              features,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
