import 'dart:io' show Platform;
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:purchases_flutter/purchases_flutter.dart'
    show Package, Offering, CustomerInfo, EntitlementInfo;

Offerings? _offerings;
CustomerInfo? _customerInfo;
String? _loggedInUid;
String _appUserId = '';
String _webPaywallLink = '';
bool _isConfigured = false;

Offerings? get offerings => _offerings;
CustomerInfo? get customerInfo => _customerInfo;
bool get isConfigured => _isConfigured;

set customerInfo(CustomerInfo? customerInfo) => _customerInfo = customerInfo;

Future initialize(
  String appStoreKey,
  String playStoreKey, {
  String webKey = '',
  bool debugLogEnabled = false,
  bool loadDataAfterLaunch = false,
  String webPaywallLink = '',
}) async {
  _webPaywallLink = webPaywallLink;
  try {
    // Set log level before configuration
    await Purchases.setLogLevel(
      debugLogEnabled ? LogLevel.debug : LogLevel.info,
    );

    // Configure based on platform
    PurchasesConfiguration configuration;
    if (kIsWeb) {
      if (webKey.isEmpty) {
        print(
          'RevenueCat web support requires a web API key. '
          'RevenueCat features will be disabled in Test Mode.',
        );
        return;
      }
      configuration = PurchasesConfiguration(webKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(appStoreKey);
    } else if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(playStoreKey);
    } else {
      print("RevenueCat is not supported on this platform.");
      return;
    }

    await Purchases.configure(configuration);
    _isConfigured = true;

    if (loadDataAfterLaunch) {
      loadCustomerInfo();
      loadOfferings();
      loadAppUserId();
    } else {
      await loadCustomerInfo();
      await loadOfferings();
      await loadAppUserId();
    }

    Purchases.addCustomerInfoUpdateListener((info) {
      customerInfo = info;
    });
  } on Exception catch (e) {
    print("RevenueCat initialization failed: $e");
  }
}

// Purchase a package.
Future<bool> purchasePackage(String package) async {
  if (!_isConfigured) {
    print('RevenueCat is not configured. Cannot purchase package.');
    return false;
  }
  try {
    final revenueCatPackage = offerings?.current?.getPackage(package);
    if (revenueCatPackage == null) {
      return false;
    }
    // v9.0+: purchasePackage returns PurchaseResult instead of CustomerInfo
    final result = await Purchases.purchasePackage(revenueCatPackage);
    customerInfo = result.customerInfo;
    return true;
  } catch (_) {
    return false;
  }
}

List<String> get activeEntitlementIds => _customerInfo != null
    ? _customerInfo!.entitlements.active.values
        .map((e) => e.identifier)
        .toList()
    : [];

Future loadOfferings() async {
  if (!_isConfigured) {
    return;
  }
  try {
    _offerings = await Purchases.getOfferings();
  } on PlatformException catch (e) {
    print("Error loading offerings info: $e");
  }
}

Future loadCustomerInfo() async {
  if (!_isConfigured) {
    return;
  }
  try {
    _customerInfo = await Purchases.getCustomerInfo();
  } on PlatformException catch (e) {
    print("Error loading purchaser info: $e");
  }
}

// Return if the user has the entitlement.
// Return null on errors.
// Returns false if RevenueCat is not configured (e.g., no web billing key in Test Mode).
Future<bool?> isEntitled(String entitlementId) async {
  if (!_isConfigured) {
    // Return false instead of null to indicate no entitlement when unconfigured.
    // This allows Test Mode to work without a web billing key.
    return false;
  }
  try {
    customerInfo = await Purchases.getCustomerInfo();
    return customerInfo!.entitlements.all[entitlementId]?.isActive ?? false;
  } on Exception catch (e) {
    print("Unable to check RevenueCat entitlements: $e");
    return null;
  }
}

// https://docs.revenuecat.com/docs/user-ids
Future login(String? uid) async {
  if (!_isConfigured) {
    // The identity is still worth keeping: a Web Purchase Link is a hosted
    // flow that needs no Web Billing key, so a project with mobile keys and a
    // link runs unconfigured on web and still shows a paywall. That link has
    // to carry the app user id (RevenueCat 404s a bare link for an identified
    // customer), and `webPaywallUrl` reads it from here.
    _loggedInUid = uid;
    _appUserId = uid ?? '';
    return;
  }
  // Logging the same user in twice is a no-op worth skipping, but a log out is
  // not: the SDK remembers the identified app user across launches while
  // `_loggedInUid` starts null in every new Dart process, so a log out after a
  // restart has to reach the SDK to actually sign that user out.
  if (uid != null && uid == _loggedInUid) {
    return;
  }
  try {
    if (uid != null) {
      customerInfo = (await Purchases.logIn(uid)).customerInfo;
    } else {
      if (await Purchases.isAnonymous) {
        // Nobody is signed in, and `logOut` throws for an anonymous user.
        _loggedInUid = null;
        return;
      }
      customerInfo = await Purchases.logOut();
    }
    _loggedInUid = uid;
    await loadAppUserId();
    // The offerings a customer sees can depend on who they are, through
    // RevenueCat targeting, so they are stale after an identity change.
    await loadOfferings();
  } on Exception catch (e) {
    print("Unable to logIn or logOut user in RevenueCat: $e");
  }
}

// https://docs.revenuecat.com/docs/restoring-purchases
Future restorePurchases() async {
  if (!_isConfigured) {
    return;
  }
  // Note: On web, purchases are automatically restored by Web Billing.
  // This method is only needed for iOS/Android.
  if (kIsWeb) {
    print(
      'Restore purchases is not needed on web - Web Billing handles this automatically.',
    );
    return;
  }
  try {
    customerInfo = await Purchases.restorePurchases();
  } on PlatformException catch (e) {
    print("Unable to restore purchases in RevenueCat: $e");
  }
}

/// The app user id the SDK is currently identified as.
///
/// Anonymous until something calls [login], in which case RevenueCat's own
/// generated id (`$RCAnonymousID:...`) is what a paywall link needs. While the
/// SDK is unconfigured there is no such id, so this is whoever [login]
/// identified: the same id the app would have logged in with.
String get appUserId => _appUserId;

Future loadAppUserId() async {
  if (!_isConfigured) {
    return;
  }
  try {
    _appUserId = await Purchases.appUserID;
  } on PlatformException catch (e) {
    print("Unable to read the RevenueCat app user id: $e");
  }
}

/// Whether the customer is currently paying for any subscription.
///
/// Reads the cached customer info, so it is safe to call while building a
/// widget. Use the Refresh Customer Info action after a purchase made outside
/// the app.
bool get hasActiveSubscription =>
    _customerInfo?.activeSubscriptions.isNotEmpty ?? false;

/// Every offering configured in the dashboard, current one first.
List<Offering> get allOfferings {
  final all = _offerings?.all.values.toList() ?? [];
  final current = _offerings?.current;
  if (current == null) {
    return all;
  }
  return [
    current,
    ...all.where((offering) => offering.identifier != current.identifier),
  ];
}

/// The offering with [identifier], or null when the dashboard has no such
/// offering.
Offering? offeringById(String identifier) =>
    _offerings?.getOffering(identifier);

// ---------------------------------------------------------------------------
// Customer info
// ---------------------------------------------------------------------------

/// Tells RevenueCat which app user is signed in, so their purchases follow
/// them across devices.
Future identifyUser(String appUserId) => login(appUserId);

/// Returns RevenueCat to a fresh anonymous app user.
Future logOutUser() => login(null);

/// Discards the cached customer info and fetches it again.
///
/// Needed after a purchase, cancellation, or refund that happened outside the
/// app, which the SDK's cache would otherwise keep serving.
Future refreshCustomerInfo() async {
  if (!_isConfigured) {
    return;
  }
  try {
    await Purchases.invalidateCustomerInfoCache();
    customerInfo = await Purchases.getCustomerInfo();
  } on PlatformException catch (e) {
    print("Unable to refresh RevenueCat customer info: $e");
  }
}

/// Pushes any store purchases RevenueCat has not seen yet.
///
/// https://docs.revenuecat.com/docs/restoring-purchases#syncing-purchases
Future syncPurchases() async {
  if (!_isConfigured || kIsWeb) {
    return;
  }
  try {
    await Purchases.syncPurchases();
    await refreshCustomerInfo();
  } on PlatformException catch (e) {
    print("Unable to sync RevenueCat purchases: $e");
  }
}

/// Sets subscriber attributes on the current customer.
///
/// Empty values clear the attribute, which is what RevenueCat's own API does
/// with an empty string.
/// https://docs.revenuecat.com/docs/subscriber-attributes
Future setCustomerAttributes({
  String? email,
  String? displayName,
  String? phoneNumber,
  Map<String, String> attributes = const {},
}) async {
  if (!_isConfigured) {
    return;
  }
  try {
    if (email != null) {
      await Purchases.setEmail(email);
    }
    if (displayName != null) {
      await Purchases.setDisplayName(displayName);
    }
    if (phoneNumber != null) {
      await Purchases.setPhoneNumber(phoneNumber);
    }
    if (attributes.isNotEmpty) {
      await Purchases.setAttributes(attributes);
    }
  } on PlatformException catch (e) {
    print("Unable to set RevenueCat subscriber attributes: $e");
  }
}

/// The entitlements the customer has access to right now.
List<EntitlementInfo> activeEntitlements(CustomerInfo? info) =>
    info?.entitlements.active.values.toList() ?? [];

/// Every entitlement the customer has ever had, active or expired.
List<EntitlementInfo> allEntitlements(CustomerInfo? info) =>
    info?.entitlements.all.values.toList() ?? [];

/// The customer's entitlement with [identifier], active or expired.
EntitlementInfo? entitlementById(CustomerInfo? info, String identifier) =>
    info?.entitlements.all[identifier];

/// A RevenueCat date, which the SDK reports as an ISO-8601 string.
DateTime? revenueCatDate(String? value) =>
    value == null ? null : DateTime.tryParse(value);

/// Whether [entitlement] is inside a free trial.
bool isInTrial(EntitlementInfo? entitlement) =>
    entitlement?.periodType == PeriodType.trial;

/// Whether [entitlement] is inside a paid introductory offer.
bool isInIntroOffer(EntitlementInfo? entitlement) =>
    entitlement?.periodType == PeriodType.intro;

/// Whether RevenueCat has seen a failing payment for [entitlement].
bool hasBillingIssue(EntitlementInfo? entitlement) =>
    entitlement?.billingIssueDetectedAt != null;

// ---------------------------------------------------------------------------
// Pricing
// ---------------------------------------------------------------------------

/// Whether [package] has an introductory offer — a free trial or a discounted
/// first period.
bool hasIntroOffer(Package? package) =>
    package?.storeProduct.introductoryPrice != null;

/// Whether [package]'s introductory offer is a free trial rather than a
/// discount.
bool hasFreeTrial(Package? package) =>
    (package?.storeProduct.introductoryPrice?.price ?? -1) == 0;

/// How long [package]'s introductory offer runs, in words — `month`,
/// `3 months`. Empty when there is no introductory offer.
String introPeriodLabel(Package? package) {
  final intro = package?.storeProduct.introductoryPrice;
  if (intro == null) {
    return '';
  }
  return _periodLabel(intro.periodUnit, intro.periodNumberOfUnits);
}

/// [package]'s billing period in words — `month`, `year`. Empty for a product
/// with no subscription period, such as a lifetime purchase.
String subscriptionPeriodLabel(Package? package) {
  final period = _parseIso8601Period(package?.storeProduct.subscriptionPeriod);
  return period == null ? '' : _periodLabel(period.$1, period.$2);
}

/// [package]'s price normalized to one month, so packages of different
/// lengths can be compared or a "per month" line can be shown.
///
/// 0 for a product with no subscription period.
double pricePerMonth(Package? package) {
  final product = package?.storeProduct;
  final months = _periodInMonths(product?.subscriptionPeriod);
  if (product == null || months == null || months <= 0) {
    return 0.0;
  }
  return product.price / months;
}

/// [pricePerMonth] formatted in the product's own currency.
String pricePerMonthString(Package? package) {
  final perMonth = pricePerMonth(package);
  final currencyCode = package?.storeProduct.currencyCode;
  if (perMonth <= 0 || currencyCode == null || currencyCode.isEmpty) {
    return '';
  }
  return NumberFormat.simpleCurrency(name: currencyCode).format(perMonth);
}

String _periodLabel(PeriodUnit unit, int count) {
  final name = switch (unit) {
    PeriodUnit.day => 'day',
    PeriodUnit.week => 'week',
    PeriodUnit.month => 'month',
    PeriodUnit.year => 'year',
    PeriodUnit.unknown => '',
  };
  if (name.isEmpty) {
    return '';
  }
  return count == 1 ? name : '$count ${name}s';
}

/// The number of months [iso8601] covers, for normalizing prices.
///
/// Days and weeks are converted with the same 30-day month RevenueCat's own
/// dashboard uses, so a weekly package still compares sensibly against a
/// monthly one.
double? _periodInMonths(String? iso8601) {
  final period = _parseIso8601Period(iso8601);
  if (period == null) {
    return null;
  }
  final (unit, count) = period;
  return switch (unit) {
    PeriodUnit.day => count / 30.0,
    PeriodUnit.week => count * 7 / 30.0,
    PeriodUnit.month => count.toDouble(),
    PeriodUnit.year => count * 12.0,
    PeriodUnit.unknown => null,
  };
}

/// Parses the ISO-8601 duration the stores report a subscription period as —
/// `P1M`, `P3M`, `P1Y`, `P1W`.
(PeriodUnit, int)? _parseIso8601Period(String? iso8601) {
  if (iso8601 == null || iso8601.isEmpty) {
    return null;
  }
  final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(iso8601.toUpperCase());
  if (match == null) {
    return null;
  }
  final count = int.tryParse(match.group(1)!);
  if (count == null) {
    return null;
  }
  return switch (match.group(2)) {
    'D' => (PeriodUnit.day, count),
    'W' => (PeriodUnit.week, count),
    'M' => (PeriodUnit.month, count),
    'Y' => (PeriodUnit.year, count),
    _ => null,
  };
}

// ---------------------------------------------------------------------------
// Hosted pages
// ---------------------------------------------------------------------------

/// The RevenueCat Web Paywall URL for the current app user, or null when no
/// paywall link is configured in App Settings.
///
/// https://docs.revenuecat.com/docs/web-paywall-links
String? get webPaywallUrl {
  if (_webPaywallLink.isEmpty) {
    return null;
  }
  final link = _webPaywallLink.startsWith('http')
      ? _webPaywallLink
      : 'https://pay.rev.cat/$_webPaywallLink';
  return _appUserId.isEmpty ? link : '$link/${Uri.encodeComponent(_appUserId)}';
}

/// Opens the RevenueCat Web Paywall in the browser.
///
/// Returns whether there was a paywall link to open.
Future<bool> openWebPaywall() async {
  final url = webPaywallUrl;
  if (url == null) {
    print(
      'No RevenueCat Web Paywall link is set. Add one under '
      'Settings > RevenueCat to use this action.',
    );
    return false;
  }
  return _launch(url);
}

/// Opens the store's own subscription management page for this customer.
///
/// Returns whether the customer had a management URL — they will not until
/// they have subscribed at least once.
Future<bool> openManageSubscriptions() async {
  final url = _customerInfo?.managementURL;
  if (url == null || url.isEmpty) {
    print(
      'This customer has no RevenueCat management URL, which means they have '
      'no store subscription to manage.',
    );
    return false;
  }
  return _launch(url);
}

Future<bool> _launch(String url) async {
  try {
    // Awaited inside the try so a failed launch is reported here rather than
    // thrown out of the action that called it.
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (e) {
    print('Could not launch $url: $e');
    return false;
  }
}
