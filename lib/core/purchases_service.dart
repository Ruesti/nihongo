import 'dart:io';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesService {
  static const _rcApiKeyIos = 'appl_REPLACE_WITH_YOUR_KEY';
  static const _rcApiKeyAndroid = 'goog_REPLACE_WITH_YOUR_KEY';

  static const entitlementJapanese = 'japanese_full';
  static const entitlementTravel = 'travel_bundle';
  static const entitlementAll = 'all_languages';

  static String langEntitlement(String code) => 'lang_$code';

  static Future<void> init() async {
    final apiKey = Platform.isIOS ? _rcApiKeyIos : _rcApiKeyAndroid;
    final config = PurchasesConfiguration(apiKey);
    await Purchases.configure(config);
  }

  static Future<bool> isUnlocked(String entitlement) async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlement);
    } catch (_) {
      return false;
    }
  }

  static Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> purchase(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      return true;
    } catch (_) {
      return false;
    }
  }
}
