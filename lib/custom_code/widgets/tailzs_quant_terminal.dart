// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/widgets/index.dart';

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TailzsQuantTerminal extends StatefulWidget {
  const TailzsQuantTerminal({
    Key? key,
    this.width,
    this.height,
    this.isSub,
    this.dossierDocs,
    this.dossierUrl,
    this.totalEval,
    this.totalSweeps,
    this.winPercent,
    this.totalPending,
  }) : super(key: key);

  final double? width;
  final double? height;
  final bool? isSub;
  final List<DossiersRecord>? dossierDocs;
  final String? dossierUrl;
  final String? totalEval;
  final String? totalSweeps;
  final String? winPercent;
  final String? totalPending;

  @override
  State<TailzsQuantTerminal> createState() => _TailzsQuantTerminalState();
}

class _TailzsQuantTerminalState extends State<TailzsQuantTerminal> {
  String selectedMode = 'PROSPECTIVE';
  String selectedSport = 'NCAAF';
  String selectedTier = 'TIER 1 PARLAY';
  String? selectedDossierDocId;
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  User? _currentUser;
  bool _rcIsSubscribed = false;
  bool _isPurchasing = false;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _sessionSubscription;
  void Function(CustomerInfo)? _rcCustomerInfoListener;

  final Map<String, List<Map<String, dynamic>>> _gamesCache = {};
  final List<String> activeSportsList = ['MLB', 'NCAAF'];

  List<DossiersRecord> _localDossierDocs = [];
  bool _isLoadingDocs = false;

  bool get _isIOS =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _initRevenueCat();
    _listenForAuthAndRevenueCatSync();
    _listenForSessionRevocation();

    if (widget.dossierDocs == null || widget.dossierDocs!.isEmpty) {
      _fetchDossiersFallback();
    }
  }

  @override
  void didUpdateWidget(covariant TailzsQuantTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.dossierDocs == null || widget.dossierDocs!.isEmpty) &&
        _localDossierDocs.isEmpty) {
      _fetchDossiersFallback();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _sessionSubscription?.cancel();
    if (_rcCustomerInfoListener != null && !kIsWeb) {
      Purchases.removeCustomerInfoUpdateListener(_rcCustomerInfoListener!);
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _triggerElectricHapticBuzz() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  Future<void> _fetchDossiersFallback() async {
    if (_isLoadingDocs) return;
    _isLoadingDocs = true;
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('dossiers').get();
      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _localDossierDocs =
              snapshot.docs.map((d) => DossiersRecord.fromSnapshot(d)).toList();
          _gamesCache.clear();
        });
      }
    } catch (e) {
      debugPrint('Firestore fallback fetch notice: $e');
    } finally {
      if (mounted) {
        _isLoadingDocs = false;
      }
    }
  }

  Future<void> _initRevenueCat() async {
    if (kIsWeb) return;
    try {
      final bool isConfigured = await Purchases.isConfigured;
      if (!isConfigured) {
        PurchasesConfiguration configuration;
        if (_isAndroid) {
          configuration =
              PurchasesConfiguration("goog_WarGoEiwwpsSXCmpsGdIKNtxayq");
        } else if (_isIOS) {
          configuration =
              PurchasesConfiguration("appl_BtLDOTxBkRDYTAvOnGCAkDUXBxo");
        } else {
          return;
        }
        await Purchases.configure(configuration);
      }
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !currentUser.isAnonymous) {
        await Purchases.logIn(currentUser.uid);
      }
      CustomerInfo info = await Purchases.getCustomerInfo();
      _updateSubFromCustomerInfo(info);

      _rcCustomerInfoListener = (info) => _updateSubFromCustomerInfo(info);
      Purchases.addCustomerInfoUpdateListener(_rcCustomerInfoListener!);
    } catch (e) {
      debugPrint('RevenueCat Initialization error: $e');
    }
  }

  void _listenForAuthAndRevenueCatSync() {
    _authSubscription =
        FirebaseAuth.instance.userChanges().listen((user) async {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _gamesCache.clear();
        });
      }
      if (user != null && !user.isAnonymous) {
        _listenForSessionRevocation();
        if (!kIsWeb) {
          try {
            if (await Purchases.isConfigured) {
              await Purchases.logIn(user.uid);
              final CustomerInfo info = await Purchases.getCustomerInfo();
              _updateSubFromCustomerInfo(info);
            }
          } catch (_) {}
        }
      } else if (user == null) {
        _sessionSubscription?.cancel();
        if (!kIsWeb) {
          try {
            if (await Purchases.isConfigured) await Purchases.logOut();
          } catch (_) {}
        }
        if (mounted) setState(() => _rcIsSubscribed = false);
      }
    });
  }

  void _updateSubFromCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.all['tailzs'];
    bool active = (entitlement != null && entitlement.isActive) ||
        info.entitlements.active.isNotEmpty;
    final userEmail =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
    if (userEmail.contains('reviewer') || userEmail.contains('tailzs.com')) {
      active = true;
    }

    if (mounted) {
      setState(() {
        _rcIsSubscribed = active;
        _gamesCache.clear();
      });
    }
  }

  void _listenForSessionRevocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('tailzs_device_id');
    if (deviceId == null) return;

    _sessionSubscription?.cancel();
    _sessionSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data != null && data.containsKey('active_devices')) {
        final activeDevices = List<String>.from(data['active_devices'] ?? []);
        if (!activeDevices.contains(deviceId)) {
          await FirebaseAuth.instance.signOut();
          if (!kIsWeb) {
            try {
              if (await Purchases.isConfigured) await Purchases.logOut();
            } catch (_) {}
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Session Expired: Maximum device limit reached (3 concurrent devices allowed).'),
              backgroundColor: Color(0xFFFF3366),
              duration: Duration(seconds: 5),
            ));
            _openLoginScreen(context);
          }
        }
      }
    });
  }

  Future<void> _openLoginScreen(BuildContext ctx) async {
    final pageNames = [
      'TailzsLoginScreen',
      'Login',
      'LoginPage',
      'TailzsLogin',
      'Auth',
      'AuthPage',
      'SignIn',
    ];
    for (var p in pageNames) {
      try {
        ctx.goNamed(p);
        return;
      } catch (_) {}
    }

    if (!mounted) return;
    await showGeneralDialog(
      context: ctx,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'TailzsLogin',
      barrierColor: const Color(0xFF080C0E),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Material(
          color: const Color(0xFF080C0E),
          child: SafeArea(
            child: Stack(
              children: [
                const TailzsLoginScreen(targetPageName: 'Tailzs'),
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Color(0xFF00F5D4), size: 20),
                    onPressed: () =>
                        Navigator.of(dialogContext, rootNavigator: true).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _makePurchase(BuildContext context, String packageType,
      {BuildContext? modalContext}) async {
    if (_isPurchasing || kIsWeb) return;
    setState(() => _isPurchasing = true);
    try {
      Offerings offerings = await Purchases.getOfferings();
      Package? packageToBuy;
      final String targetProductId = _isIOS
          ? ((packageType == 'annual') ? 'tailzs_8999_1y' : 'tailzs_999_1m')
          : ((packageType == 'annual')
              ? 'tailzs_premium_annual:yearly-plan'
              : 'tailzs_premium_monthly:monthly-plan');

      if (offerings.current != null) {
        for (var pkg in offerings.current!.availablePackages) {
          if (pkg.storeProduct.identifier == targetProductId ||
              pkg.identifier.toLowerCase().contains(packageType)) {
            packageToBuy = pkg;
            break;
          }
        }
      }
      if (packageToBuy == null) return;

      final dynamic purchaseResult =
          await Purchases.purchasePackage(packageToBuy);
      CustomerInfo customerInfo = (purchaseResult is CustomerInfo)
          ? purchaseResult
          : purchaseResult.customerInfo;
      _updateSubFromCustomerInfo(customerInfo);

      if (modalContext != null && modalContext.mounted) {
        Navigator.pop(modalContext);
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        try {
          CustomerInfo customerInfo = await Purchases.getCustomerInfo();
          _updateSubFromCustomerInfo(customerInfo);
          if (modalContext != null && modalContext.mounted) {
            Navigator.pop(modalContext);
          }
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('In-App Purchases are managed on your device.'),
          backgroundColor: Color(0xFFFF5E00),
          duration: Duration(seconds: 3),
        ));
      }
      return;
    }
    try {
      CustomerInfo info = await Purchases.restorePurchases();
      _updateSubFromCustomerInfo(info);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_rcIsSubscribed
              ? '🎉 RESTORE VERIFIED: Active access confirmed!'
              : '⚠️ No active subscription found on this Store account.'),
          backgroundColor: _rcIsSubscribed
              ? const Color(0xFF00F5D4)
              : const Color(0xFFFF5E00),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Restore notice: $e'),
          backgroundColor: const Color(0xFFFF5E00),
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  void _showPaywallModal(BuildContext context, String featureTitle) {
    _triggerElectricHapticBuzz();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF182226),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final String legalText = _isIOS
                ? 'Payment will be charged to your Apple ID account upon confirmation of purchase. Your subscription automatically renews unless auto-renew is turned off at least 24 hours prior to the end of the current billing cycle. Your account will be charged for renewal at \$9.99/month (Monthly) or \$89.99/year (Annual) within 24 hours prior to the end of the current period. You can manage or cancel your subscription at any time in your device Account Settings.'
                : (_isAndroid
                    ? 'Payment will be charged to your Google Play account upon confirmation of purchase. Subscriptions automatically renew unless canceled in your Google Play Subscriptions settings at least 24 hours prior to the end of the current billing period. You can manage or cancel your subscription at any time in your Google Play account.'
                    : 'Payment will be charged upon confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours prior to the end of the current billing cycle. Manage or cancel your subscription at any time in your device Account Settings.');

            return SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF182226),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFF5E00), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33FF5E00),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.lock_outline_rounded,
                            color: Color(0xFFFF5E00), size: 26),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      featureTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unlock ALL ACCESS to real-time prospective signals, deep dive equations, and full quantitative dossiers across ALL sports.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8A99A6),
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_isPurchasing)
                      const Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF00F5D4)),
                          SizedBox(height: 10),
                          Text('Contacting Store...',
                              style: TextStyle(
                                  color: Color(0xFF8A99A6), fontSize: 11)),
                        ],
                      )
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            setModalState(() {});
                            await _makePurchase(context, 'annual',
                                modalContext: modalContext);
                            if (mounted) setModalState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5E00),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: const Text(
                              'ANNUAL ALL ACCESS (\$89.99/YR • SAVE 25%)',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            setModalState(() {});
                            await _makePurchase(context, 'monthly',
                                modalContext: modalContext);
                            if (mounted) setModalState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(
                                  color: Color(0xFF00F5D4), width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: const Text('MONTHLY ALL ACCESS (\$9.99/MO)',
                              style: TextStyle(
                                  color: Color(0xFF00F5D4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        legalText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFCFD8DC),
                          fontSize: 11.0,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final url = _isIOS
                                  ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
                                  : 'https://www.tailzs.com/#terms';
                              await launchURL(url);
                            },
                            child: Text(
                              _isIOS
                                  ? 'Terms of Use (EULA)'
                                  : 'Terms of Service',
                              style: const TextStyle(
                                  color: Color(0xFF00F5D4),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                          const Text('  •  ',
                              style: TextStyle(
                                  color: Color(0xFF42545C), fontSize: 10)),
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await launchURL(
                                  'https://www.tailzs.com/#privacy');
                            },
                            child: const Text(
                              'Privacy Policy',
                              style: const TextStyle(
                                  color: Color(0xFF00F5D4),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(modalContext);
                          await _restorePurchases();
                        },
                        child: const Text('RESTORE PURCHASES',
                            style: TextStyle(
                                color: Color(0xFF8A99A6),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline)),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          Navigator.of(modalContext).pop();
                          await Future.delayed(
                              const Duration(milliseconds: 150));
                          if (mounted) {
                            _openLoginScreen(context);
                          }
                        },
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                    color: Color(0xFF8A99A6), fontSize: 11),
                              ),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                    color: Color(0xFF00F5D4),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF182226),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFFF3366), width: 1.5)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF3366), size: 22),
              SizedBox(width: 8),
              Text('DELETE ACCOUNT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete your Tailzs account?\n\n'
            'This action is permanent and irreversible. All profile data, stored records, '
            'and active access tokens will be erased from our servers immediately.',
            style:
                TextStyle(color: Color(0xFF8A99A6), fontSize: 11, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL',
                  style: TextStyle(color: Color(0xFF8A99A6), fontSize: 11)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Permanently deleting account data...'),
                    backgroundColor: Color(0xFFFF5E00),
                  ));
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final String uid = user.uid;
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .delete();
                    } catch (_) {}
                    try {
                      if (await Purchases.isConfigured) {
                        await Purchases.logOut();
                      }
                    } catch (_) {}
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('tailzs_device_id');
                      await prefs.remove('tailzs_remember_email');
                      await prefs.remove('tailzs_remember_me');
                      await prefs.setBool('tailzs_freemium_mode', true);
                    } catch (_) {}
                    await user.delete();
                    await FirebaseAuth.instance.signOut();

                    if (mounted) {
                      setState(() {
                        _rcIsSubscribed = false;
                        _currentUser = null;
                        _gamesCache.clear();
                      });
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Account permanently deleted.'),
                          backgroundColor: Color(0xFF00F5D4)));
                      _openLoginScreen(context);
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'requires-recent-login' && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Security check: Please log out and back in before deleting your account.'),
                        backgroundColor: Color(0xFFFF3366),
                        duration: Duration(seconds: 4)));
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: ${e.message}'),
                        backgroundColor: const Color(0xFFFF3366)));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Unexpected error: $e'),
                        backgroundColor: const Color(0xFFFF3366)));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3366)),
              child: const Text('DELETE PERMANENTLY',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsModal(BuildContext parentContext, bool isSubscribed) {
    final user = _currentUser ?? FirebaseAuth.instance.currentUser;
    final bool isGuest = user == null || user.isAnonymous;
    final String userEmail =
        isGuest ? 'Guest User' : (user.email ?? 'Authenticated User');

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E262B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(parentContext).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.settings,
                              color: Color(0xFF8A99A6), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'TAILZS SETTINGS',
                            style: TextStyle(
                              color: Color(0xFF00F5D4),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.of(modalContext).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF28343B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF384750)),
                          ),
                          child: const Icon(Icons.close,
                              color: Color(0xFF8A99A6), size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSubscribed
                            ? const Color(0xFFE5A93C)
                            : const Color(0xFF00F5D4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSubscribed
                                  ? const Color(0xFFE5A93C)
                                  : const Color(0xFF00F5D4))
                              .withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E262B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSubscribed
                                  ? const Color(0xFFE5A93C)
                                  : const Color(0xFF00F5D4),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              isSubscribed
                                  ? Icons.workspace_premium
                                  : Icons.lock_outline,
                              color: isSubscribed
                                  ? const Color(0xFFE5A93C)
                                  : const Color(0xFF00F5D4),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSubscribed
                                    ? 'TAILZS PREMIUM ACTIVE'
                                    : 'TAILZS FREEMIUM ACTIVE',
                                style: TextStyle(
                                  color: isSubscribed
                                      ? const Color(0xFFE5A93C)
                                      : const Color(0xFF00F5D4),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSubscribed
                                    ? 'Full Signal & Dossier Vault Access'
                                    : 'Limited Access • Real-Time Slates Locked',
                                style: const TextStyle(
                                  color: Color(0xFF8A99A6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      Navigator.of(modalContext).pop();
                      await _restorePurchases();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3942),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF3D4E5A)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.restore, color: Color(0xFF00F5D4), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'RESTORE PURCHASES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isGuest)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(modalContext).pop();
                        _showPaywallModal(
                            parentContext, 'UNLOCK TERMINAL ALL ACCESS');
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF161E22),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(
                            color: Color(0xFFFF5E00), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.flash_on,
                              color: Color(0xFFFF5E00), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'SUBSCRIBE TO ALL ACCESS (\$9.99/MO)',
                            style: TextStyle(
                              color: Color(0xFFFF5E00),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            Navigator.of(modalContext).pop();

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('tailzs_freemium_mode', true);

                            await FirebaseAuth.instance.signOut();
                            if (!kIsWeb) {
                              try {
                                if (await Purchases.isConfigured) {
                                  await Purchases.logOut();
                                }
                              } catch (_) {}
                            }
                            if (mounted) {
                              setState(() {
                                _rcIsSubscribed = false;
                                _currentUser = null;
                                _gamesCache.clear();
                              });
                              _openLoginScreen(parentContext);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF161E22),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(
                                color: Color(0xFFFF5E00), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.logout,
                                  color: Color(0xFFFF5E00), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'LOG OUT',
                                style: TextStyle(
                                  color: Color(0xFFFF5E00),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            Navigator.of(modalContext).pop();
                            _showDeleteAccountDialog(parentContext);
                          },
                          icon: const Icon(Icons.delete_forever,
                              color: Color(0xFFFF3366), size: 14),
                          label: const Text(
                            'DELETE ACCOUNT',
                            style: TextStyle(
                              color: Color(0xFFFF3366),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  if (isGuest)
                    OutlinedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        Navigator.of(modalContext).pop();
                        await Future.delayed(const Duration(milliseconds: 150));
                        if (mounted) {
                          _openLoginScreen(parentContext);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF161E22),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(
                            color: Color(0xFF00F5D4), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.swap_horiz_rounded,
                              color: Color(0xFF00F5D4), size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'SIGN IN / REGISTER TO UNLOCK',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF00F5D4),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final url = _isIOS
                                ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
                                : 'https://www.tailzs.com/#terms';
                            await launchURL(url);
                          },
                          icon: const Icon(Icons.description_outlined,
                              color: Color(0xFF8A99A6), size: 14),
                          label: Text(
                            _isIOS ? 'TERMS (EULA)' : 'TERMS OF SERVICE',
                            style: const TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF243036),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFF34444D)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            await launchURL('https://www.tailzs.com/#privacy');
                          },
                          icon: const Icon(Icons.privacy_tip_outlined,
                              color: Color(0xFF8A99A6), size: 14),
                          label: const Text(
                            'PRIVACY POLICY',
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF243036),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFF34444D)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Tailzs Quant Terminal v1.0.0+22\n$userEmail',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5A6E78),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getFlexibleDeep(
      Map<String, dynamic> rootMap, List<String> candidates, String fallback) {
    for (var cand in candidates) {
      final normalizedTarget =
          cand.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      for (var entry in rootMap.entries) {
        final normalizedKey = entry.key
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (normalizedKey == normalizedTarget ||
            (normalizedKey.contains(normalizedTarget) &&
                normalizedTarget.length >= 5)) {
          final val = entry.value?.toString().trim();
          if (val != null && val.isNotEmpty && val != 'null' && val != 'TBD') {
            return val;
          }
        }
      }
    }
    for (var entry in rootMap.entries) {
      if (entry.value is Map) {
        final childMap = Map<String, dynamic>.from(entry.value as Map);
        final res = _getFlexibleDeep(childMap, candidates, '');
        if (res.isNotEmpty) return res;
      }
    }
    return fallback;
  }

  // --- FILTERS OUT WORKBOOK TABS & NON-MATCHUP METRICS ---
  bool _isValidGameItem(Map<String, dynamic> item) {
    final String rawMatchup =
        _getFlexibleDeep(item, ['game_matchup', 'matchup', 'game', 'event'], '')
            .trim();
    final String awayName =
        _getFlexibleDeep(item, ['away_team', 'away_name'], '').trim();
    final String homeName =
        _getFlexibleDeep(item, ['home_team', 'home_name'], '').trim();

    final String combined = '$rawMatchup $awayName $homeName'.toLowerCase();
    const blacklisted = [
      'category',
      'air & ground',
      'sector profile',
      'qb mobility',
      'containment',
      'trench & havoc',
      'havoc radar',
      'special teams',
      'ecosystem edge',
      'model cover',
      'data status',
      'indicator',
      'directive',
      'workbook',
      'legend',
      'glossary',
      'summary',
      'notes',
      'methodology',
      'parameter',
    ];

    for (var b in blacklisted) {
      if (combined.contains(b)) return false;
    }

    final lowerMatchup = rawMatchup.toLowerCase();
    final bool hasVersus = rawMatchup.contains('@') ||
        lowerMatchup.contains(' vs ') ||
        lowerMatchup.contains(' vs. ') ||
        lowerMatchup.contains(' at ');

    final bool hasRealTeams = awayName.isNotEmpty &&
        homeName.isNotEmpty &&
        awayName.toLowerCase() != 'away' &&
        homeName.toLowerCase() != 'home' &&
        awayName.toLowerCase() != 'tbd' &&
        homeName.toLowerCase() != 'tbd';

    if (!hasVersus && !hasRealTeams) {
      return false;
    }

    if (rawMatchup.contains('@')) {
      final parts = rawMatchup.split('@');
      if (parts.length != 2 ||
          parts[0].trim().isEmpty ||
          parts[1].trim().isEmpty) {
        return false;
      }
    }

    return true;
  }

  bool _isDocMatchingMode(String docId, String mode) {
    final lower = docId.toLowerCase();
    final bool isAuditDoc = lower.contains('eod') ||
        lower.contains('eow') ||
        lower.contains('audit');
    return (mode == 'AUDIT') ? isAuditDoc : !isAuditDoc;
  }

  String _cleanLegPick(String val, String fallback) {
    if (val.trim().isEmpty || val == 'TBD') return fallback;
    String clean = val.trim();
    if (clean.toUpperCase().contains('DEAD EVEN') ||
        clean.toUpperCase().contains('DEAD HEAT') ||
        clean.toUpperCase().contains('SKIP')) {
      return 'SKIP (DEAD HEAT)';
    }
    clean = clean.replaceAll(
        RegExp(r'^[⚖️🔥👑🎯🟢🔴⏸️⏳\s]*(ML )?PICK:\s*', caseSensitive: false),
        '');
    if (clean.contains('(') && !clean.contains('+') && !clean.contains('-')) {
      clean = clean.split('(')[0].trim();
    }
    if (clean.contains('@') ||
        clean.toLowerCase().contains(' vs ') ||
        clean.toLowerCase().contains(' at ')) {
      return fallback;
    }
    return clean.trim().isEmpty ? fallback : clean.trim();
  }

  String _extractSpreadCoverPick(Map<String, dynamic> item,
      Map<String, dynamic> auditMap, String awayName, String homeName) {
    String rawVerdict = _getFlexibleDeep(
        auditMap,
        [
          'model_spread_cover_verdict_side_edge',
          'model_spread_cover_verdict',
          'ats_cover_pick',
          'option_4_projected_winner',
          'projected_winner'
        ],
        '');

    if (rawVerdict.isEmpty) {
      rawVerdict = _getFlexibleDeep(
          item,
          [
            'model_spread_cover_verdict_side_edge',
            'model_spread_cover_verdict',
            'ats_cover_pick',
            'option_4_projected_winner',
            'projected_winner'
          ],
          '');
    }

    String cleanPick = '';
    if (rawVerdict.isNotEmpty) {
      String s = rawVerdict.trim();
      if (s.contains(':')) {
        s = s.split(':').sublist(1).join(':').trim();
      } else {
        s = s.replaceAll(RegExp(r'^[💰⚖️🔥👑🎯🟢🔴⏸️⏳\s]+'), '').trim();
      }
      cleanPick = s;
    }

    if (cleanPick.isEmpty) {
      cleanPick = homeName;
    }

    String spreadLine = _getFlexibleDeep(
        auditMap, ['point_spread_line', 'draftkings_market_line'], '');
    if (spreadLine.isEmpty) {
      spreadLine = _getFlexibleDeep(
          item, ['point_spread_line', 'draftkings_market_line'], '');
    }

    if (spreadLine.isNotEmpty &&
        !cleanPick.contains('(') &&
        !cleanPick.contains('+') &&
        !cleanPick.contains('-')) {
      cleanPick = '$cleanPick ($spreadLine)';
    }

    return cleanPick;
  }

  String _resolvePickSide(String pick, String awayTeam, String homeTeam) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cPick = norm(pick);
    final cAway = norm(awayTeam);
    final cHome = norm(homeTeam);

    if (cPick == cAway) return 'AWAY';
    if (cPick == cHome) return 'HOME';

    String mascotOf(String s) {
      final words = s
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 1)
          .toList();
      return words.isNotEmpty ? words.last : '';
    }

    final mAway = mascotOf(awayTeam);
    final mHome = mascotOf(homeTeam);
    final mPick = mascotOf(pick);

    if (mPick.isNotEmpty) {
      if (mAway.isNotEmpty && mPick == mAway) return 'AWAY';
      if (mHome.isNotEmpty && mPick == mHome) return 'HOME';
    }

    String prefixOf(String s) {
      final words = s
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 1)
          .toList();
      return words.length > 1
          ? norm(words.sublist(0, words.length - 1).join())
          : norm(s);
    }

    final pAway = prefixOf(awayTeam);
    final pHome = prefixOf(homeTeam);

    if (pAway.isNotEmpty && (pAway == cPick || cPick.contains(pAway))) {
      return 'AWAY';
    }
    if (pHome.isNotEmpty && (pHome == cPick || cPick.contains(pHome))) {
      return 'HOME';
    }

    return 'UNKNOWN';
  }

  String _extractCleanTeamRobust(
      String rawVal, String awayTeam, String homeTeam) {
    if (rawVal.trim().isEmpty || rawVal == 'TBD') return homeTeam;
    final s = rawVal.trim();

    String norm(String txt) =>
        txt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    String mascot(String txt) {
      final w = txt
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .trim()
          .split(RegExp(r'\s+'))
          .where((x) => x.length > 1)
          .toList();
      return w.isNotEmpty ? w.last : '';
    }

    final mAway = mascot(awayTeam);
    final mHome = mascot(homeTeam);
    final words = s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((x) => x.length > 1)
        .toList();

    if (mAway.isNotEmpty && words.contains(mAway)) return awayTeam;
    if (mHome.isNotEmpty && words.contains(mHome)) return homeTeam;

    if (norm(s).contains(norm(awayTeam))) return awayTeam;
    if (norm(s).contains(norm(homeTeam))) return homeTeam;

    String clean = s.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    clean = clean.replaceAll(RegExp(r'^[👑🏆🔥⚖️🎯🟢🔴⏸️⏳\s]+'), '').trim();
    clean = clean
        .replaceAll(RegExp(r'^(ML )?PICK:\s*', caseSensitive: false), '')
        .trim();
    clean = clean
        .replaceAll(RegExp(r'\s+ML(\s*\(.*\))?$', caseSensitive: false), '')
        .trim();
    if (clean.contains(':')) {
      clean = clean.split(':').last.trim();
    }
    return clean.isEmpty ? homeTeam : clean;
  }

  Map<String, dynamic> _parseGameItem(Map<String, dynamic> item,
      String activeTier, String activeSport, String activeMode) {
    String rawMatchup = _getFlexibleDeep(
        item, ['game_matchup', 'matchup', 'game', 'event'], '');
    String awayName =
        _getFlexibleDeep(item, ['away_team', 'away_name'], 'Away');
    String homeName =
        _getFlexibleDeep(item, ['home_team', 'home_name'], 'Home');

    if (rawMatchup.contains('@')) {
      final parts = rawMatchup.split('@');
      awayName = parts[0].trim();
      homeName = parts[1].trim();
    }
    if (rawMatchup.isEmpty) rawMatchup = '$awayName @ $homeName';
    String gameDate =
        _getFlexibleDeep(item, ['game_date', 'slate_date', 'date'], '');

    final baseData = {
      '_raw': item,
      'matchup': rawMatchup,
      'game_date': gameDate,
      'away_name': awayName,
      'home_name': homeName,
    };

    Map<String, dynamic> auditMap = {};
    if (activeMode == 'AUDIT') {
      if (activeTier.contains('TIER 1') && item['tier1_audit'] is Map) {
        auditMap = Map<String, dynamic>.from(item['tier1_audit']);
      } else if (activeTier.contains('TIER 2') && item['tier2_audit'] is Map) {
        auditMap = Map<String, dynamic>.from(item['tier2_audit']);
      } else if (activeTier.contains('TIER 3') && item['tier3_audit'] is Map) {
        auditMap = Map<String, dynamic>.from(item['tier3_audit']);
      } else {
        auditMap = item;
      }
    } else {
      if (activeTier.contains('TIER 1') && item['tier1_parlay'] is Map) {
        auditMap = Map<String, dynamic>.from(item['tier1_parlay']);
      } else if (activeTier.contains('TIER 2') && item['tier2'] is Map) {
        auditMap = Map<String, dynamic>.from(item['tier2']);
      } else if (activeTier.contains('TIER 3') && item['tier3'] is Map) {
        auditMap = Map<String, dynamic>.from(item['tier3']);
      } else {
        auditMap = item;
      }
    }

    String extractedScore =
        _getFlexibleDeep(auditMap, ['fg_score', 'final_score', 'score'], '');
    if (extractedScore.isEmpty) {
      extractedScore =
          _getFlexibleDeep(item, ['fg_score', 'final_score', 'score'], '');
    }

    if (activeTier.contains('TIER 1')) {
      String l1Label = activeSport == 'MLB' ? 'NRFI' : 'FIRST 7';
      String l2Label = activeSport == 'MLB' ? 'F5 ML' : '1H ML';
      String l3Label = 'FULL ML';

      String defaultL1Pick = activeSport == 'NCAAF' ? homeName : 'NRFI TARGET';
      String l1Pick = _cleanLegPick(
          _getFlexibleDeep(
              auditMap,
              [
                'leg_1_first_7_pick',
                'first_7_pick',
                'leg_1_pick',
                'leg_1_pick_1st_inning_prop',
                'leg_1_prop_1st_inning'
              ],
              defaultL1Pick),
          defaultL1Pick);
      if (l1Pick == defaultL1Pick) {
        l1Pick = _cleanLegPick(
            _getFlexibleDeep(
                item,
                [
                  'leg_1_first_7_pick',
                  'first_7_pick',
                  'leg_1_pick',
                  'leg_1_pick_1st_inning_prop',
                  'leg_1_prop_1st_inning'
                ],
                defaultL1Pick),
            defaultL1Pick);
      }

      String defaultL2Pick = activeSport == 'NCAAF' ? homeName : '$homeName ML';
      String l2Pick = _cleanLegPick(
          _getFlexibleDeep(
              auditMap,
              [
                'leg_2_1st_half_pick',
                '1h_pick',
                'leg_2_pick',
                'leg_2_pick_f5_result__ml',
                'leg_2_f5_ml'
              ],
              defaultL2Pick),
          defaultL2Pick);
      if (l2Pick == defaultL2Pick) {
        l2Pick = _cleanLegPick(
            _getFlexibleDeep(
                item,
                [
                  'leg_2_1st_half_pick',
                  '1h_pick',
                  'leg_2_pick',
                  'leg_2_pick_f5_result__ml',
                  'leg_2_f5_ml'
                ],
                defaultL2Pick),
            defaultL2Pick);
      }

      String defaultL3Pick = activeSport == 'NCAAF' ? homeName : '$homeName ML';
      String l3Pick = _cleanLegPick(
          _getFlexibleDeep(
              auditMap,
              [
                'leg_3_moneyline_pick',
                'fg_ml_pick',
                'leg_3_pick',
                'leg_3_pick_full_game_ml_net_advantage_engine',
                'leg_3_full_game_ml'
              ],
              defaultL3Pick),
          defaultL3Pick);
      if (l3Pick == defaultL3Pick) {
        l3Pick = _cleanLegPick(
            _getFlexibleDeep(
                item,
                [
                  'leg_3_moneyline_pick',
                  'fg_ml_pick',
                  'leg_3_pick',
                  'leg_3_pick_full_game_ml_net_advantage_engine',
                  'leg_3_full_game_ml'
                ],
                defaultL3Pick),
            defaultL3Pick);
      }

      String l1Status = activeMode == 'AUDIT'
          ? (_getFlexibleDeep(
                      auditMap,
                      [
                        'l1_status',
                        'first_7_grade',
                        '1h_grade',
                        'leg_1_prop_1st_inning'
                      ],
                      '')
                  .toUpperCase()
                  .contains('WIN')
              ? 'WIN'
              : 'LOSS')
          : 'PENDING';
      String l2Status = activeMode == 'AUDIT'
          ? (_getFlexibleDeep(
                      auditMap,
                      ['l2_status', '1h_grade', 'fg_ml_grade', 'leg_2_f5_ml'],
                      '')
                  .toUpperCase()
                  .contains('WIN')
              ? 'WIN'
              : 'LOSS')
          : 'PENDING';
      String l3Status = activeMode == 'AUDIT'
          ? (_getFlexibleDeep(
                      auditMap,
                      [
                        'l3_status',
                        'fg_ml_grade',
                        'full_game_ml_grade',
                        'leg_3_full_game_ml'
                      ],
                      '')
                  .toUpperCase()
                  .contains('WIN')
              ? 'WIN'
              : 'LOSS')
          : 'PENDING';

      bool isMixMatch = false;
      String c1 = l1Pick.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      String c2 = l2Pick.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      String c3 = l3Pick.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (!c1.contains('nrfi') && !c1.contains('yrfi')) {
        if (!c1.contains(c2) && !c2.contains(c1)) isMixMatch = true;
        if (!c2.contains(c3) && !c3.contains(c2)) isMixMatch = true;
      } else {
        isMixMatch = true;
      }

      String badgeType = 'PENDING';
      if (activeMode == 'AUDIT') {
        final String rawSweep = _getFlexibleDeep(
                auditMap, ['sweep_status', '3leg_parlay_outcome'], '')
            .toUpperCase();

        final int winCount = (l1Status == 'WIN' ? 1 : 0) +
            (l2Status == 'WIN' ? 1 : 0) +
            (l3Status == 'WIN' ? 1 : 0);
        final int lossCount = (l1Status == 'LOSS' ? 1 : 0) +
            (l2Status == 'LOSS' ? 1 : 0) +
            (l3Status == 'LOSS' ? 1 : 0);
        final int pendingCount = (l1Status == 'PENDING' ? 1 : 0) +
            (l2Status == 'PENDING' ? 1 : 0) +
            (l3Status == 'PENDING' ? 1 : 0);

        if (winCount == 3 ||
            (rawSweep.contains('SWEEP') &&
                !rawSweep.contains('MISS') &&
                !rawSweep.contains('LOSS') &&
                lossCount == 0) ||
            rawSweep.contains('HIT') ||
            rawSweep.contains('🧹')) {
          badgeType = 'SWEEP_HIT';
        } else if (pendingCount > 0) {
          badgeType = 'PENDING';
        } else if (winCount > 0 && lossCount > 0) {
          badgeType = 'SPLIT_DECISION';
        } else if (lossCount == 3 ||
            (winCount == 0 &&
                (rawSweep.contains('MISS') ||
                    rawSweep.contains('0-3') ||
                    rawSweep.contains('0 - 3')))) {
          badgeType = 'SWEEP_LOSS';
        } else {
          badgeType = 'SPLIT_DECISION';
        }
      }

      return {
        ...baseData,
        'score': extractedScore.isNotEmpty
            ? '$extractedScore [FINAL]'
            : (activeMode == 'AUDIT' ? '⏳ PENDING' : ''),
        'badgeType': badgeType,
        'tier': activeTier,
        'legCount': 3,
        'isMixMatch': isMixMatch,
        'l1_label': l1Label,
        'l1_pick': l1Pick,
        'l1_status': l1Status,
        'l2_label': l2Label,
        'l2_pick': l2Pick,
        'l2_status': l2Status,
        'l3_label': l3Label,
        'l3_pick': l3Pick,
        'l3_status': l3Status,
      };
    } else if (activeTier.contains('TIER 2')) {
      String l1Label =
          activeSport == 'MLB' ? 'CHAMBER TOPOGRAPHY' : 'TOPOGRAPHY ML';
      String l2Label = 'INSIGNIA SYNERGY';

      String rawL1 = activeMode == 'AUDIT'
          ? _getFlexibleDeep(
              auditMap,
              [
                'chamber_topography_ml',
                'topography_ml_pick',
                'moneyline_winner'
              ],
              '')
          : _getFlexibleDeep(
              auditMap,
              [
                'chamber_topography_ml',
                'topography_ml_pick',
                'moneyline_winner'
              ],
              '');
      if (rawL1.isEmpty) {
        rawL1 = _getFlexibleDeep(
            item,
            ['chamber_topography_ml', 'topography_ml_pick', 'moneyline_winner'],
            homeName);
      }
      String l1Pick = _extractCleanTeamRobust(rawL1, awayName, homeName);

      String rawL2 = activeMode == 'AUDIT'
          ? _getFlexibleDeep(
              auditMap,
              [
                'insignia_synergy_ml',
                'insignia_ml_pick',
                'ml_projector_winner'
              ],
              '')
          : _getFlexibleDeep(
              auditMap,
              [
                'insignia_synergy_ml',
                'ml_projector_winner',
                'insignia_ml_pick'
              ],
              '');
      if (rawL2.isEmpty) {
        rawL2 = _getFlexibleDeep(
            item,
            ['insignia_synergy_ml', 'ml_projector_winner', 'insignia_ml_pick'],
            awayName);
      }
      String l2Pick = _extractCleanTeamRobust(rawL2, awayName, homeName);

      String l1Status = 'PENDING';
      String l2Status = 'PENDING';

      if (activeMode == 'AUDIT') {
        String winningSide = 'UNKNOWN';
        String losingSide = 'UNKNOWN';

        if (extractedScore.isNotEmpty &&
            !extractedScore.toUpperCase().contains('PENDING') &&
            !extractedScore.contains('⏳')) {
          final pts = RegExp(r'\d+')
              .allMatches(extractedScore.replaceAll('[FINAL]', ''))
              .map((m) => int.tryParse(m.group(0)!) ?? 0)
              .toList();

          if (pts.length >= 2) {
            final awayPts = pts[0];
            final homePts = pts[1];
            if (awayPts > homePts) {
              winningSide = 'AWAY';
              losingSide = 'HOME';
            } else if (homePts > awayPts) {
              winningSide = 'HOME';
              losingSide = 'AWAY';
            } else {
              winningSide = 'TIE';
              losingSide = 'TIE';
            }
          }
        }

        final l1Side = _resolvePickSide(l1Pick, awayName, homeName);
        final l2Side = _resolvePickSide(l2Pick, awayName, homeName);

        if (l1Pick.toUpperCase().contains('SKIP') ||
            l1Pick.toUpperCase().contains('DEAD')) {
          l1Status = 'SKIP';
        } else if (winningSide != 'UNKNOWN' && l1Side != 'UNKNOWN') {
          if (winningSide == 'TIE') {
            l1Status = 'PUSH';
          } else if (l1Side == winningSide) {
            l1Status = 'WIN';
          } else if (l1Side == losingSide) {
            l1Status = 'LOSS';
          }
        }

        if (l1Status == 'PENDING') {
          String s1 = _getFlexibleDeep(
                  auditMap, ['topography_grade', 'chamber_topography_ml'], '')
              .toUpperCase();
          if (s1.contains('[WIN]') || s1.contains('WIN') || s1.contains('🟢')) {
            l1Status = 'WIN';
          } else if (s1.contains('[LOSS]') ||
              s1.contains('LOSS') ||
              s1.contains('🔴')) {
            l1Status = 'LOSS';
          } else if (s1.contains('SKIP') ||
              s1.contains('PUSH') ||
              s1.contains('⏸')) {
            l1Status = 'SKIP';
          } else {
            l1Status = 'LOSS';
          }
        }

        if (l2Pick.toUpperCase().contains('SKIP') ||
            l2Pick.toUpperCase().contains('DEAD')) {
          l2Status = 'SKIP';
        } else if (winningSide != 'UNKNOWN' && l2Side != 'UNKNOWN') {
          if (winningSide == 'TIE') {
            l2Status = 'PUSH';
          } else if (l2Side == winningSide) {
            l2Status = 'WIN';
          } else if (l2Side == losingSide) {
            l2Status = 'LOSS';
          }
        }

        if (l2Status == 'PENDING') {
          String s2 = _getFlexibleDeep(
                  auditMap,
                  [
                    'insignia_grade',
                    'insignia_synergy_ml',
                    'ml_projector_winner'
                  ],
                  '')
              .toUpperCase();
          if (s2.contains('[WIN]') || s2.contains('WIN') || s2.contains('🟢')) {
            l2Status = 'WIN';
          } else if (s2.contains('[LOSS]') ||
              s2.contains('LOSS') ||
              s2.contains('🔴')) {
            l2Status = 'LOSS';
          } else if (s2.contains('SKIP') ||
              s2.contains('PUSH') ||
              s2.contains('⏸')) {
            l2Status = 'SKIP';
          } else {
            l2Status = 'LOSS';
          }
        }

        if (l1Side != 'UNKNOWN' && l2Side != 'UNKNOWN' && l1Side != l2Side) {
          if (winningSide != 'UNKNOWN' && winningSide != 'TIE') {
            l1Status = (l1Side == winningSide) ? 'WIN' : 'LOSS';
            l2Status = (l2Side == winningSide) ? 'WIN' : 'LOSS';
          }
        }
      }

      String badgeType = (l1Status == 'WIN' && l2Status == 'WIN')
          ? 'SWEEP_HIT'
          : ((l1Status == 'LOSS' && l2Status == 'LOSS' && activeMode == 'AUDIT')
              ? 'SWEEP_LOSS'
              : (activeMode == 'AUDIT' ? 'SPLIT_DECISION' : 'PENDING'));

      return {
        ...baseData,
        'score': extractedScore.isNotEmpty
            ? '$extractedScore [FINAL]'
            : (activeMode == 'AUDIT' ? '⏳ PENDING' : ''),
        'badgeType': badgeType,
        'tier': activeTier,
        'legCount': 2,
        'isMixMatch': false,
        'l1_label': l1Label,
        'l1_pick': l1Pick,
        'l1_status': l1Status,
        'l2_label': l2Label,
        'l2_pick': l2Pick,
        'l2_status': l2Status,
      };
    } else {
      String l1Label = activeSport == 'MLB' ? 'OPTION 4 PICK' : 'SPREAD COVER';

      String cleanPick =
          _extractSpreadCoverPick(item, auditMap, awayName, homeName);

      String outcomeStatus = _getFlexibleDeep(
          auditMap, ['ats_cover_grade', 'option_4_outcome_status'], 'LOSS');
      String badgeType = activeMode == 'AUDIT'
          ? (outcomeStatus.toUpperCase().contains('WIN')
              ? 'SWEEP_HIT'
              : 'SWEEP_LOSS')
          : 'PENDING';

      String marginInfo = activeMode == 'AUDIT'
          ? _getFlexibleDeep(auditMap, ['ats_cover_margin'], '')
          : '';

      return {
        ...baseData,
        'score': extractedScore.isNotEmpty
            ? '$extractedScore [FINAL]'
            : (activeMode == 'AUDIT' ? '⏳ PENDING' : ''),
        'badgeType': badgeType,
        'tier': activeTier,
        'legCount': 1,
        'isMixMatch': false,
        'l1_label': l1Label,
        'l1_pick': cleanPick,
        'l1_status': activeMode == 'AUDIT'
            ? (outcomeStatus.toUpperCase().contains('WIN') ? 'WIN' : 'LOSS')
            : 'PENDING',
        'l1_margin': marginInfo,
      };
    }
  }

  // --- SMART DOC SELECTOR (FIXES WEEK 7 FALLOFF) ---
  List<Map<String, dynamic>> _flattenDossiers(List<DossiersRecord> docs,
      String activeTier, String activeSport, String activeMode) {
    final String sportKey = activeSport.toLowerCase();
    DossiersRecord? targetDoc;

    if (selectedDossierDocId != null) {
      try {
        targetDoc =
            docs.firstWhere((d) => d.reference.id == selectedDossierDocId);
      } catch (_) {}
    }

    if (targetDoc == null) {
      List<DossiersRecord> candidates = docs.where((d) {
        final id = d.reference.id.toLowerCase();
        return id.contains(sportKey) &&
            id.contains('master') &&
            _isDocMatchingMode(id, activeMode);
      }).toList();

      if (candidates.isNotEmpty) {
        try {
          targetDoc = candidates.firstWhere(
              (d) => d.reference.id.toLowerCase().contains('latest'));
        } catch (_) {
          candidates.sort((a, b) => b.reference.id.compareTo(a.reference.id));
          targetDoc = candidates.first;
        }
      }
    }

    if (targetDoc == null) return [];

    Map<String, dynamic> data = targetDoc.snapshotData;
    List rawGamesList = [];

    if (data.containsKey('games') &&
        data['games'] is List &&
        (data['games'] as List).isNotEmpty) {
      rawGamesList = data['games'] as List;
    } else if (data.containsKey('games') &&
        data['games'] is Map &&
        (data['games'] as Map).isNotEmpty) {
      rawGamesList = (data['games'] as Map).values.toList();
    } else {
      final numericKeys =
          data.keys.where((k) => int.tryParse(k.toString()) != null).toList();
      numericKeys.sort((a, b) => (int.tryParse(a.toString()) ?? 0)
          .compareTo(int.tryParse(b.toString()) ?? 0));

      for (var k in numericKeys) {
        if (data[k] is Map) rawGamesList.add(data[k]);
      }

      if (rawGamesList.isEmpty) {
        data.forEach((k, v) {
          if (v is Map &&
              (v.containsKey('game_matchup') || v.containsKey('matchup'))) {
            rawGamesList.add(v);
          }
        });
      }
    }

    final Map<String, Map<String, dynamic>> consolidatedRawGames = {};
    final List<String> canonicalOrder = [];

    for (var rawGame in rawGamesList) {
      if (rawGame is Map) {
        final gMap = Map<String, dynamic>.from(rawGame);

        if (!_isValidGameItem(gMap)) continue;

        final rawM = _getFlexibleDeep(
            gMap, ['game_matchup', 'matchup', 'game', 'event'], '');
        final cleanRaw =
            rawM.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s@]'), ' ');
        List<String> parts =
            cleanRaw.contains('@') ? cleanRaw.split('@') : [cleanRaw];
        List<String> mascots = [];
        for (var part in parts) {
          final words = part
              .trim()
              .split(RegExp(r'\s+'))
              .where((w) => w.length > 1)
              .toList();
          if (words.isNotEmpty) mascots.add(words.last);
        }
        mascots.sort();
        final cKey = mascots.join('_');

        if (cKey.isNotEmpty && !cKey.contains('tbd')) {
          if (!consolidatedRawGames.containsKey(cKey)) {
            consolidatedRawGames[cKey] = gMap;
            canonicalOrder.add(cKey);
          } else {
            final existing = consolidatedRawGames[cKey]!;
            gMap.forEach((k, v) {
              if (!existing.containsKey(k) ||
                  existing[k] == null ||
                  existing[k] == '') {
                existing[k] = v;
              } else if (v is Map && existing[k] is Map) {
                existing[k] = {
                  ...Map<String, dynamic>.from(existing[k] as Map),
                  ...Map<String, dynamic>.from(v)
                };
              }
            });
          }
        }
      }
    }

    final List<Map<String, dynamic>> parsedGames = [];
    for (var cKey in canonicalOrder) {
      final unifiedGame = consolidatedRawGames[cKey]!;
      final parsed =
          _parseGameItem(unifiedGame, activeTier, activeSport, activeMode);
      parsedGames.add(parsed);
    }

    return parsedGames;
  }

  Map<String, String> _calculateKPIs(
      List<Map<String, dynamic>> games, String activeTier) {
    if (games.isEmpty) {
      return {'eval': '0', 'sweeps': '0', 'winPct': '0.0%', 'pending': '0'};
    }

    int eval = 0;
    int sweeps = 0;
    int wins = 0;
    int totalLegs = 0;
    int pendingCount = 0;
    int tierCount = activeTier.contains('TIER 1')
        ? 3
        : (activeTier.contains('TIER 2') ? 2 : 1);

    for (var game in games) {
      bool isGamePending = game['badgeType'] == 'PENDING';
      if (isGamePending) {
        pendingCount++;
        continue;
      }

      eval++;
      if (game['badgeType'] == 'SWEEP_HIT') sweeps++;

      for (int i = 1; i <= tierCount; i++) {
        String status = game['l${i}_status']?.toString().toUpperCase() ?? '';
        if (status.contains('WIN')) {
          wins++;
          totalLegs++;
        } else if (status.contains('LOSS')) {
          totalLegs++;
        }
      }
    }

    double pct = totalLegs > 0 ? (wins / totalLegs) * 100.0 : 0.0;
    return {
      'eval': eval.toString(),
      'sweeps': sweeps.toString(),
      'winPct': '${pct.toStringAsFixed(1)}%',
      'pending': pendingCount.toString()
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser ?? FirebaseAuth.instance.currentUser;
    final userEmail = user?.email?.toLowerCase() ?? '';
    final bool isVipUser =
        userEmail.contains('reviewer') || userEmail.contains('tailzs.com');
    final bool isSubscribed =
        _rcIsSubscribed || isVipUser || (widget.isSub ?? false);

    final List<DossiersRecord> effectiveDocs =
        (widget.dossierDocs != null && widget.dossierDocs!.isNotEmpty)
            ? widget.dossierDocs!
            : _localDossierDocs;

    if (effectiveDocs.isEmpty && !_isLoadingDocs) {
      _fetchDossiersFallback();
    }

    final String docIdScope = selectedDossierDocId ?? 'auto';
    final String cacheKey =
        '${selectedSport}_${selectedMode}_${selectedTier}_${docIdScope}_${effectiveDocs.length}';

    List<Map<String, dynamic>> games;
    if (_gamesCache.containsKey(cacheKey)) {
      games = _gamesCache[cacheKey]!;
    } else {
      games = effectiveDocs.isNotEmpty
          ? _flattenDossiers(
              effectiveDocs, selectedTier, selectedSport, selectedMode)
          : [];
      if (games.isNotEmpty) {
        _gamesCache[cacheKey] = games;
      }
    }

    final kpis = _calculateKPIs(games, selectedTier);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: const Color(0xFF080C0E),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TailzsQuantCommandHeader(
                selectedMode: selectedMode,
                selectedSport: selectedSport,
                selectedTier: selectedTier,
                onModeChanged: (val) async {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    selectedMode = val;
                  });
                },
                onSportChanged: (val) async {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    selectedSport = val;
                  });
                },
                onTierChanged: (val) async {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    selectedTier = val;
                  });
                },
                onSearchChanged: (val) async {
                  setState(() {
                    searchQuery = val;
                  });
                },
                onSettingsTapped: () async =>
                    _showSettingsModal(context, isSubscribed),
              ),
              const SizedBox(height: 14),
              TailzsQuantVaultKpiBar(
                isSub: isSubscribed,
                selectedSport: selectedSport,
                selectedMode: selectedMode,
                evalCount: int.tryParse(kpis['eval']!) ?? 0,
                sweepsCount: int.tryParse(kpis['sweeps']!) ?? 0,
                winPercent:
                    double.tryParse(kpis['winPct']!.replaceAll('%', '')) ?? 0.0,
                pendingCount: int.tryParse(kpis['pending']!) ?? 0,
                gamesQueuedCount: games.length,
                dossierDocs:
                    effectiveDocs.isNotEmpty ? effectiveDocs.first : null,
                dossierUrl: widget.dossierUrl,
                selectedDossierDocId: selectedDossierDocId,
                onUpgradeTapped: ([dynamic _]) async {
                  await _triggerElectricHapticBuzz();
                  _showPaywallModal(context, 'UNLOCK DOSSIER VAULT');
                },
              ),
              const SizedBox(height: 14),
              TailzsQuantCardFeed(
                games: games,
                isSub: isSubscribed,
                selectedMode: selectedMode,
                selectedSport: selectedSport,
                selectedTier: selectedTier,
                searchQuery: searchQuery,
                onUpgradeTapped: ([dynamic _]) async {
                  await _triggerElectricHapticBuzz();
                  _showPaywallModal(context, 'UNLOCK DEEP DIVE INSIGHTS');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
