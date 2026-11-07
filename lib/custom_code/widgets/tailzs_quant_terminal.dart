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

import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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
  final dynamic dossierDocs;
  final String? dossierUrl;
  final String? totalEval;
  final String? totalSweeps;
  final String? winPercent;
  final String? totalPending;

  @override
  State<TailzsQuantTerminal> createState() => _TailzsQuantTerminalState();
}

class _TailzsQuantTerminalState extends State<TailzsQuantTerminal> {
  // --- PRIMARY (LEFT) TERMINAL STATE ---
  String _leftWorkspaceMode = 'LIVE_APP'; // LIVE_APP or DOSSIER
  String selectedMode = 'PROSPECTIVE';
  String selectedSport = 'NFL';
  String selectedTier = 'TIER 1 PARLAY';
  String? selectedDossierDocId;
  String searchQuery = '';

  // --- SECONDARY (RIGHT) DUAL APP & DOSSIER WORKSPACE STATE ---
  String _rightWorkspaceMode = 'DUAL_APP'; // DUAL_APP or DOSSIER
  String _rightMode = 'AUDIT';
  String _rightSport = 'NBA';
  String _rightTier = 'TIER 3 SIDE';
  String? _rightSelectedDossierDocId;
  String _rightSearch = '';

  // --- LEFT PANE PDF STATE ---
  String? _leftActivePdfDocId;
  String? _leftActivePdfUrl;
  File? _leftActivePdfFile;
  bool _leftIsPdfLoading = false;

  // --- RIGHT PANE PDF STATE ---
  String? _rightActivePdfDocId;
  String? _rightActivePdfUrl;
  File? _rightActivePdfFile;
  bool _rightIsPdfLoading = false;

  // Full-width viewport override for tablets/foldables
  bool _forceSinglePane = false;

  final TextEditingController _searchController = TextEditingController();

  User? _currentUser;
  bool _rcIsSubscribed = false;
  bool _isPurchasing = false;

  dynamic _authSubscription;
  dynamic _sessionSubscription;
  dynamic _rcCustomerInfoListener;

  final Map _gamesCache = {};
  final List activeSportsList = ['NFL', 'NBA', 'NHL', 'NCAAF'];
  List _localDossierDocs = [];
  bool _isLoadingDocs = false;

  bool get _isIOS =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadDisplayPreferences();
    _initRevenueCat();
    _listenForAuthAndRevenueCatSync();
    _listenForSessionRevocation();
    if (widget.dossierDocs == null || widget.dossierDocs.isEmpty) {
      _fetchDossiersFallback();
    }
  }

  void _loadDisplayPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSinglePane =
          prefs.getBool('tailzs_force_single_pane') ?? false;
      if (mounted && savedSinglePane != _forceSinglePane) {
        setState(() => _forceSinglePane = savedSinglePane);
      }
    } catch (_) {}
  }

  void _toggleSinglePaneMode(bool value) async {
    setState(() => _forceSinglePane = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tailzs_force_single_pane', value);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant TailzsQuantTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.dossierDocs == null || widget.dossierDocs.isEmpty) &&
        _localDossierDocs.isEmpty) {
      _fetchDossiersFallback();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _sessionSubscription?.cancel();
    if (_rcCustomerInfoListener != null && !kIsWeb) {
      Purchases.removeCustomerInfoUpdateListener(_rcCustomerInfoListener);
    }
    _searchController.dispose();
    super.dispose();
  }

  // --- HAPTIC FEEDBACK ---
  dynamic _triggerElectricHapticBuzz() async {
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

  dynamic _triggerDeepDiveOceanHaptic() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.vibrate();
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  // --- EDGE HYDRATION: DISK CACHE FIRST ---
  dynamic _fetchDossiersFallback() async {
    if (_isLoadingDocs) return;
    _isLoadingDocs = true;
    try {
      final collectionRef = FirebaseFirestore.instance.collection('dossiers');

      dynamic snapshot;
      try {
        snapshot =
            await collectionRef.get(const GetOptions(source: Source.cache));
      } catch (_) {}

      if (snapshot == null || snapshot.docs.isEmpty) {
        snapshot =
            await collectionRef.get(const GetOptions(source: Source.server));
      }

      if (snapshot != null && snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _localDossierDocs = snapshot.docs.toList();
          _gamesCache.clear();
        });
      }
    } catch (e) {
      debugPrint('Hydration Notice: $e');
    } finally {
      if (mounted) _isLoadingDocs = false;
    }
  }

  dynamic _initRevenueCat() async {
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
      Purchases.addCustomerInfoUpdateListener(_rcCustomerInfoListener);
    } catch (e) {}
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
    if (userEmail.contains('reviewer') || userEmail.contains('tailzs.com'))
      active = true;
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
        final activeDevices = List.from(data['active_devices'] ?? []);
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

  dynamic _openLoginScreen(BuildContext ctx) async {
    final pageNames = [
      'TailzsLoginScreen',
      'Login',
      'LoginPage',
      'TailzsLogin',
      'Auth',
      'AuthPage',
      'SignIn'
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
      barrierDismissible: true,
      barrierLabel: 'TailzsLogin',
      barrierColor: const Color(0xFF080C0E),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const Material(
          color: Color(0xFF080C0E),
          child: SafeArea(
            child: TailzsLoginScreen(targetPageName: 'Tailzs'),
          ),
        );
      },
    );
  }

  dynamic _makePurchase(BuildContext context, String packageType,
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
      if (modalContext != null && modalContext.mounted)
        Navigator.pop(modalContext);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        try {
          CustomerInfo customerInfo = await Purchases.getCustomerInfo();
          _updateSubFromCustomerInfo(customerInfo);
          if (modalContext != null && modalContext.mounted)
            Navigator.pop(modalContext);
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  dynamic _restorePurchases() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('In-App Purchases are managed on your mobile device.'),
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
    } catch (e) {}
  }

  dynamic _deleteUserAccount(BuildContext ctx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (!kIsWeb) {
        try {
          if (await Purchases.isConfigured) await Purchases.logOut();
        } catch (_) {}
      }
      await user.delete();
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Account permanently deleted.'),
          backgroundColor: Color(0xFFFF3366),
          duration: Duration(seconds: 4),
        ));
        _openLoginScreen(ctx);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(
              'Account deletion notice: $e. Please re-login and try again.'),
          backgroundColor: const Color(0xFFFF5E00),
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }

  dynamic _launchExternalUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchURL(urlString);
    }
  }

  // --- IN-PANE EDGE-CACHED PDF LOADER ---
  Future<void> _openDossierPdfInPane(String docId, String url,
      {required bool isLeftPane}) async {
    if (url.isEmpty) return;
    _triggerElectricHapticBuzz();

    if (kIsWeb) {
      setState(() {
        if (isLeftPane) {
          _leftActivePdfDocId = docId;
          _leftActivePdfUrl = url;
          _leftActivePdfFile = null;
          _leftIsPdfLoading = false;
        } else {
          _rightActivePdfDocId = docId;
          _rightActivePdfUrl = url;
          _rightActivePdfFile = null;
          _rightIsPdfLoading = false;
        }
      });
      return;
    }

    setState(() {
      if (isLeftPane) {
        _leftActivePdfDocId = docId;
        _leftActivePdfUrl = url;
        _leftIsPdfLoading = true;
      } else {
        _rightActivePdfDocId = docId;
        _rightActivePdfUrl = url;
        _rightIsPdfLoading = true;
      }
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeId = docId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final localFile = File('${dir.path}/dossier_$safeId.pdf');

      if (await localFile.exists()) {
        if (mounted) {
          setState(() {
            if (isLeftPane) {
              _leftActivePdfFile = localFile;
              _leftIsPdfLoading = false;
            } else {
              _rightActivePdfFile = localFile;
              _rightIsPdfLoading = false;
            }
          });
        }
        return;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
        if (mounted) {
          setState(() {
            if (isLeftPane) {
              _leftActivePdfFile = localFile;
              _leftIsPdfLoading = false;
            } else {
              _rightActivePdfFile = localFile;
              _rightIsPdfLoading = false;
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            if (isLeftPane)
              _leftIsPdfLoading = false;
            else
              _rightIsPdfLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Dossier Edge-Cache Notice: $e');
      if (mounted) {
        setState(() {
          if (isLeftPane)
            _leftIsPdfLoading = false;
          else
            _rightIsPdfLoading = false;
        });
      }
    }
  }

  void _showPaywallModal(BuildContext context, String featureTitle) {
    _triggerDeepDiveOceanHaptic();
    final String eulaUrl = _isIOS
        ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
        : 'https://www.tailzs.com/#terms';
    final String privacyUrl = 'https://www.tailzs.com/#privacy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 580,
                  maxHeight: MediaQuery.of(context).size.height * 0.92,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF182226),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 24),
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1114),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFFF5E00), width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x33FF5E00),
                                      blurRadius: 12,
                                      offset: Offset(0, 2))
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.lock_outline_rounded,
                                    color: Color(0xFFFF5E00), size: 28),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Color(0xFF8A99A6), size: 20),
                              onPressed: () => Navigator.pop(modalContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 6),
                        const Text(
                          'Unlock Tailzs All-Access Quantitative Sports Intelligence',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF00F5D4),
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1114),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF24343B), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'ALL ACCESS SUBSCRIPTION INCLUDES:',
                                style: TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5),
                              ),
                              SizedBox(height: 8),
                              Text(
                                  '⚡ All 3 Quant Tiers: T1 Parlays, T2 Topography/Synergy ML, and T3 Spread/Side Directives',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      height: 1.4)),
                              SizedBox(height: 4),
                              Text(
                                  '📄 Master Dossier Vault: Full analyst PDF slate downloads for current and past game weeks',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      height: 1.4)),
                              SizedBox(height: 4),
                              Text(
                                  '🔍 Deep Dive Insights: Matchup sector breakdowns, QB containment, and model edges',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      height: 1.4)),
                              SizedBox(height: 4),
                              Text(
                                  '🏈 🏀 🏒 ⚾ Multi-Sport Coverage: Complete coverage across NFL, NBA, NHL, and NCAAF',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isPurchasing)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                    color: Color(0xFF00F5D4)),
                                SizedBox(height: 10),
                                Text('Connecting to Store...',
                                    style: TextStyle(
                                        color: Color(0xFF8A99A6),
                                        fontSize: 11)),
                              ],
                            ),
                          )
                        else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                _triggerDeepDiveOceanHaptic();
                                setModalState(() {});
                                await _makePurchase(context, 'annual',
                                    modalContext: modalContext);
                                if (mounted) setModalState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5E00),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                              ),
                              child: const Column(
                                children: [
                                  Text('ANNUAL ALL ACCESS (\$89.99/YR)',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.4)),
                                  SizedBox(height: 2),
                                  Text(
                                      'SAVE 25% • BEST VALUE FOR SERIOUS ANALYSTS',
                                      style: TextStyle(
                                          color: Color(0xFFFFF0E5),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                _triggerDeepDiveOceanHaptic();
                                setModalState(() {});
                                await _makePurchase(context, 'monthly',
                                    modalContext: modalContext);
                                if (mounted) setModalState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                side: const BorderSide(
                                    color: Color(0xFF00F5D4), width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text(
                                  'MONTHLY ALL ACCESS (\$9.99/MO)',
                                  style: TextStyle(
                                      color: Color(0xFF00F5D4),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(modalContext);
                                  await _restorePurchases();
                                },
                                icon: const Icon(Icons.restore,
                                    color: Color(0xFF8A99A6), size: 14),
                                label: const Text('RESTORE PURCHASES',
                                    style: TextStyle(
                                        color: Color(0xFF8A99A6),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                  width: 1,
                                  height: 16,
                                  color: const Color(0xFF24343B)),
                              TextButton.icon(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(modalContext);
                                  _openLoginScreen(context);
                                },
                                icon: const Icon(Icons.login,
                                    color: Color(0xFF00F5D4), size: 14),
                                label: const Text('ALREADY A MEMBER? SIGN IN',
                                    style: TextStyle(
                                        color: Color(0xFF00F5D4),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1114),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF24343B), width: 1.2),
                          ),
                          child: Text(
                            _isIOS
                                ? 'Subscription Terms: Payment will be charged to your Apple ID account upon confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours prior to the end of the current billing cycle. Your account will be charged for renewal within 24 hours prior to the end of the current period. Manage or cancel your subscription anytime in your Apple ID Account Settings after purchase.'
                                : 'Subscription Terms: Payment will be charged upon confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours prior to the end of the current billing cycle. You can manage and cancel your subscriptions anytime in your Google Play Account Settings.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFA5B4C2),
                              fontSize: 10.0,
                              fontWeight: FontWeight.w500,
                              height: 1.42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _launchExternalUrl(eulaUrl),
                              child: Text(
                                _isIOS
                                    ? 'Terms of Use (EULA)'
                                    : 'Terms of Service',
                                style: const TextStyle(
                                    color: Color(0xFF8A99A6),
                                    fontSize: 9.5,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('•',
                                  style: TextStyle(
                                      color: Color(0xFF5A6976), fontSize: 9.5)),
                            ),
                            GestureDetector(
                              onTap: () => _launchExternalUrl(privacyUrl),
                              child: const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                    color: Color(0xFF8A99A6),
                                    fontSize: 9.5,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- SETTINGS MODAL: DEVICE-NEUTRAL TERMINOLOGY ---
  void _showSettingsModal(BuildContext parentContext, bool isSubscribed) {
    final user = _currentUser ?? FirebaseAuth.instance.currentUser;
    final bool isGuest = user == null || user.isAnonymous;
    final String userEmail = user?.email ?? 'Unauthenticated';

    final String eulaUrl = _isIOS
        ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
        : 'https://www.tailzs.com/#terms';
    final String privacyUrl = 'https://www.tailzs.com/#privacy';

    const String viewToggleTitle = 'SINGLE FEED (FULL SCREEN)';
    const String viewToggleSubtitle =
        'Expand single terminal across full display';

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double currentWidth = MediaQuery.of(parentContext).size.width;

            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 580,
                  maxHeight: MediaQuery.of(parentContext).size.height * 0.90,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF182226),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
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
                                    color: Color(0xFF00F5D4), size: 18),
                                SizedBox(width: 8),
                                Text('TAILZS SETTINGS',
                                    style: TextStyle(
                                        color: Color(0xFF00F5D4),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8)),
                              ],
                            ),
                            InkWell(
                                onTap: () => Navigator.of(modalContext).pop(),
                                child: const Icon(Icons.close,
                                    color: Color(0xFF8A99A6), size: 18)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1114),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSubscribed
                                    ? const Color(0xFFD4AF37)
                                    : const Color(0xFF24343B),
                                width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                      isSubscribed
                                          ? Icons.workspace_premium
                                          : Icons.lock_outline,
                                      color: isSubscribed
                                          ? const Color(0xFFD4AF37)
                                          : const Color(0xFF00F5D4),
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                      isSubscribed
                                          ? 'TAILZS PREMIUM ACTIVE'
                                          : 'TAILZS FREEMIUM ACCESS',
                                      style: TextStyle(
                                          color: isSubscribed
                                              ? const Color(0xFFD4AF37)
                                              : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('ACCOUNT: $userEmail',
                                  style: const TextStyle(
                                      color: Color(0xFF8A99A6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (currentWidth >= 720) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1114),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF24343B), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _forceSinglePane
                                      ? Icons.fullscreen_exit
                                      : Icons.splitscreen,
                                  color: const Color(0xFF00F5D4),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        viewToggleTitle,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _forceSinglePane
                                            ? 'Full single feed mode enabled'
                                            : viewToggleSubtitle,
                                        style: const TextStyle(
                                            color: Color(0xFF8A99A6),
                                            fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _forceSinglePane,
                                  activeColor: const Color(0xFF00F5D4),
                                  activeTrackColor:
                                      const Color(0xFF00F5D4).withOpacity(0.3),
                                  inactiveThumbColor: const Color(0xFF8A99A6),
                                  inactiveTrackColor: const Color(0xFF24343B),
                                  onChanged: (val) {
                                    HapticFeedback.selectionClick();
                                    setModalState(() {});
                                    _toggleSinglePaneMode(val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(modalContext);
                            await _restorePurchases();
                          },
                          icon: const Icon(Icons.restore,
                              color: Color(0xFF00F5D4), size: 16),
                          label: const Text('RESTORE PURCHASES',
                              style: TextStyle(
                                  color: Color(0xFF00F5D4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(
                                color: Color(0xFF24343B), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _launchExternalUrl(eulaUrl),
                          icon: const Icon(Icons.description_outlined,
                              color: Colors.white, size: 16),
                          label: Text(
                              _isIOS
                                  ? 'TERMS OF USE (EULA)'
                                  : 'TERMS OF SERVICE',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(
                                color: Color(0xFF24343B), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _launchExternalUrl(privacyUrl),
                          icon: const Icon(Icons.privacy_tip_outlined,
                              color: Colors.white, size: 16),
                          label: const Text('PRIVACY POLICY',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(
                                color: Color(0xFF24343B), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!isGuest)
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(modalContext);
                              await FirebaseAuth.instance.signOut();
                              if (mounted) _openLoginScreen(parentContext);
                            },
                            icon: const Icon(Icons.logout,
                                color: Colors.white, size: 16),
                            label: const Text('LOG OUT',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF24343B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (!isGuest)
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: parentContext,
                                builder: (dialogCtx) => AlertDialog(
                                  backgroundColor: const Color(0xFF182226),
                                  title: const Text('DELETE ACCOUNT',
                                      style: TextStyle(
                                          color: Color(0xFFFF3366),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14)),
                                  content: const Text(
                                      'Are you sure you want to permanently delete your account and remove all data? This cannot be undone.',
                                      style: TextStyle(
                                          color: Color(0xFF8A99A6),
                                          fontSize: 12)),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx),
                                        child: const Text('CANCEL',
                                            style: TextStyle(
                                                color: Colors.white))),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(dialogCtx);
                                        Navigator.pop(modalContext);
                                        await _deleteUserAccount(parentContext);
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFFF3366)),
                                      child: const Text('PERMANENTLY DELETE',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_forever,
                                color: Color(0xFFFF3366), size: 16),
                            label: const Text('DELETE ACCOUNT',
                                style: TextStyle(
                                    color: Color(0xFFFF3366),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              side: const BorderSide(
                                  color: Color(0xFFFF3366), width: 1.2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        const SizedBox(height: 18),
                        const Center(
                          child: Text(
                            'v2.0.0+1',
                            style: TextStyle(
                              color: Color(0xFF5A6976),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getFlexibleDeep(
      dynamic rootObj, List<String> candidates, String fallback) {
    if (rootObj == null || rootObj is! Map) return fallback;
    Map rootMap = rootObj;
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
          if (val != null && val.isNotEmpty && val != 'null' && val != 'TBD')
            return val;
        }
      }
    }
    for (var entry in rootMap.entries) {
      if (entry.value is Map) {
        final res = _getFlexibleDeep(entry.value, candidates, '');
        if (res.isNotEmpty) return res;
      }
    }
    return fallback;
  }

  bool _isValidGameItem(dynamic itemObj) {
    if (itemObj == null || itemObj is! Map) return false;
    Map item = itemObj;
    final String rawMatchup =
        _getFlexibleDeep(item, ['game_matchup', 'matchup', 'game', 'event'], '')
            .trim();
    if (!rawMatchup.contains('@') && !rawMatchup.toLowerCase().contains(' vs '))
      return false;
    return true;
  }

  // Strictly maps documents to Prospective or Audit while excluding daily EOD docs from weekly sports
  bool _isDocMatchingMode(String docId, String mode, {String? sport}) {
    final lower = docId.toLowerCase();
    final s = sport?.toLowerCase() ?? '';
    final bool isWeekly = (s == 'nfl' || s == 'ncaaf') ||
        lower.contains('nfl') ||
        lower.contains('ncaaf');

    // Reject EOD artifacts immediately for football
    if (isWeekly && lower.contains('eod')) return false;

    final bool isAuditDoc = lower.contains('eod') ||
        lower.contains('eow') ||
        lower.contains('audit');
    return (mode == 'AUDIT') ? isAuditDoc : !isAuditDoc;
  }

  String _extractLegStatus(
      String rawPick, String explicitGrade, String activeMode) {
    if (activeMode != 'AUDIT') return 'PENDING';
    final combined = '${explicitGrade.toUpperCase()} ${rawPick.toUpperCase()}';
    if (combined.contains('PUSH') || combined.contains('TIE')) return 'PUSH';
    if (combined.contains('WIN') ||
        combined.contains('HIT') ||
        combined.contains('✅') ||
        combined.contains('SWEEP')) return 'WIN';
    if (combined.contains('LOSS') ||
        combined.contains('MISS') ||
        combined.contains('❌')) return 'LOSS';
    return 'LOSS';
  }

  String _cleanLegPick(String val, String fallback) {
    if (val.trim().isEmpty || val == 'TBD') return fallback;
    String clean = val.trim();

    if (clean.toUpperCase().contains('SKIP') ||
        clean.toUpperCase().contains('DEAD EVEN') ||
        clean.toUpperCase().contains('DEAD HEAT') ||
        clean.toUpperCase().contains('PASS ML') ||
        clean.toUpperCase().contains('NEUTRAL EQUILIBRIUM')) {
      clean = clean.replaceAll(RegExp(r'^[^a-zA-Z0-9]+'), '').trim();
      if (clean.toUpperCase().startsWith('SKIP'))
        return '⏩ $clean';
      else
        return '⏩ SKIP ($clean)';
    }

    clean = clean.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    clean = clean.replaceAll(
        RegExp(r'^[⚖️🔥👑🎯🟢🔴⏸️⏳\s]*(ML )?PICK:\s*', caseSensitive: false),
        '');
    clean = clean.replaceAll(RegExp(r'^[⚖️🔥👑🎯🟢🔴⏸️⏳\s]+'), '').trim();
    if (clean.contains('(') && !clean.contains('+') && !clean.contains('-'))
      clean = clean.split('(')[0].trim();
    if (clean.contains('@')) return fallback;
    return clean.trim().isEmpty ? fallback : clean.trim();
  }

  bool _isValidSpreadPick(String val, String awayName, String homeName) {
    if (val.trim().isEmpty) return false;
    final s = val.trim();

    if (RegExp(r'^[+-]?\d+(\.\d+)?\s*(pts)?(\s*\(.*?\))?$',
            caseSensitive: false)
        .hasMatch(s)) {
      return false;
    }

    if (RegExp(r'\b(pass|fair|equilibrium)\b', caseSensitive: false)
        .hasMatch(s)) {
      return true;
    }

    final aWords =
        awayName.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2);
    final hWords =
        homeName.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2);
    final sLower = s.toLowerCase();
    for (var w in [...aWords, ...hWords]) {
      if (sLower.contains(w)) return true;
    }
    return false;
  }

  String _cleanSpreadPickCandidate(String raw, String awayName, String homeName,
      String activeSport, String spreadLine) {
    if (!_isValidSpreadPick(raw, awayName, homeName)) return '';
    String s = raw.trim();

    if (RegExp(r'\b(fair market line|pass|no edge|equilibrium)\b',
            caseSensitive: false)
        .hasMatch(s)) {
      return '⏩ PASS';
    }

    s = s.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    s = s.replaceAll(RegExp(r'[🔴🟢💰🚀⚖️🔥👑🎯🏆🛑⏩]'), '').trim();
    s = s
        .replaceAll(
            RegExp(
                r'\s*\((?:Edge|ML|Opponent|Hold|True|Model|Col|Covered|Failed)[^)]*\)',
                caseSensitive: false),
            '')
        .trim();
    s = s
        .replaceAll(
            RegExp(
                r'^\s*(?:ATS Pick|Pick|Directive|Verdict|Option 4|ATS|Model)\s*:\s*',
                caseSensitive: false),
            '')
        .trim();
    s = s
        .replaceAll(
            RegExp(
                r'^\s*(?:SPREAD DEFICIT|HIGH EV COVER|LEAN COVER|FAIR MARKET LINE|OPTION 4 PICK|COVER PICK|ATS PICK)\s*:\s*',
                caseSensitive: false),
            '')
        .trim();
    s = s
        .replaceAll(
            RegExp(
                r'^\s*(?:SPREAD DEFICIT|HIGH EV COVER|LEAN COVER|FAIR MARKET LINE|OPTION 4 PICK|COVER PICK|ATS PICK)\s+',
                caseSensitive: false),
            '')
        .trim();

    s = s
        .replaceAll(RegExp(r'\bFULL GAME ML\b', caseSensitive: false), '')
        .trim();

    final mDup =
        RegExp(r'\(\+?([A-Za-z\s]+?)\s*([+-]\s*\d+(?:\.\d+)?)\)').firstMatch(s);
    if (mDup != null) {
      final teamInside = mDup.group(1)!.trim();
      final numInside = mDup.group(2)!.trim().replaceAll(' ', '');
      s = '$teamInside $numInside';
    }

    if (activeSport == 'NHL') {
      if (s.contains('(')) s = s.split('(')[0].trim();
      s = s
          .replaceAll(
              RegExp(r'[+-]?\d+(\.\d+)?\s*(pts)?', caseSensitive: false), '')
          .trim();
      return s;
    }

    if (!RegExp(r'[+-]\s*\d').hasMatch(s) && spreadLine.isNotEmpty) {
      final mSp = RegExp(r'([+-]\s*\d+(?:\.\d+)?)')
          .firstMatch(spreadLine.replaceAll('pts', ''));
      if (mSp != null) {
        s = '$s ${mSp.group(1)!.replaceAll(' ', '')}';
      }
    }

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  String _extractSpreadCoverPick(Map item, Map auditMap, String awayName,
      String homeName, String activeSport) {
    String spreadLine = _getFlexibleDeep(
        auditMap,
        [
          'point_spread_line',
          'draftkings_market_line',
          'spread_line',
          'line',
          'spread',
          'point_spread'
        ],
        '');
    if (spreadLine.isEmpty) {
      spreadLine = _getFlexibleDeep(
          item,
          [
            'point_spread_line',
            'draftkings_market_line',
            'spread_line',
            'line',
            'spread',
            'point_spread'
          ],
          '');
    }

    if (spreadLine.isNotEmpty) {
      final cleanLine = spreadLine
          .replaceAll(RegExp(r'\(ML:.*?\)', caseSensitive: false), '')
          .trim();
      final m = RegExp(r'([+-]\s*\d+(?:\.\d+)?)').firstMatch(cleanLine);
      if (m != null) spreadLine = m.group(1)!.replaceAll(' ', '');
    }

    final pickCandidates = [
      'ats_pick',
      'spread_cover_ats_pick',
      'master_matrix_spread_cover_pick',
      'spread_cover_pick',
      'model_spread_cover_verdict_side_edge',
      'model_spread_cover_verdict',
      'ats_cover_pick',
      'ats_directive',
      'spread_pick',
      'option_4_projected_winner',
      'on_4_projected_winner',
      'option4_projected_winner',
      'projected_winner',
      'option_4_pick',
      'option_4_winner',
      'pick',
      'market_line',
      'draftkings_market_line',
    ];

    String foundPick = '';
    for (var cand in pickCandidates) {
      String val = _getFlexibleDeep(auditMap, [cand], '');
      if (val.isEmpty) val = _getFlexibleDeep(item, [cand], '');
      if (val.isNotEmpty) {
        String cleaned = _cleanSpreadPickCandidate(
            val, awayName, homeName, activeSport, spreadLine);
        if (cleaned.isNotEmpty) {
          foundPick = cleaned;
          break;
        }
      }
    }

    if (foundPick.isEmpty) {
      for (var source in [auditMap, item]) {
        if (source is Map) {
          for (var entry in source.entries) {
            final k = entry.key.toString().toLowerCase();
            final v = entry.value?.toString().trim() ?? '';
            if (k.contains('pick') ||
                k.contains('verdict') ||
                k.contains('directive') ||
                k.contains('winner') ||
                k.contains('option') ||
                k.contains('ats') ||
                k.contains('line')) {
              if (!k.contains('margin') &&
                  !k.contains('edge') &&
                  !k.contains('score') &&
                  !k.contains('date')) {
                String cleaned = _cleanSpreadPickCandidate(
                    v, awayName, homeName, activeSport, spreadLine);
                if (cleaned.isNotEmpty) {
                  foundPick = cleaned;
                  break;
                }
              }
            }
          }
          if (foundPick.isNotEmpty) break;
        }
      }
    }

    if (foundPick.isEmpty) {
      if (activeSport == 'NHL') {
        foundPick = homeName;
      } else if (spreadLine.isNotEmpty) {
        foundPick = '$homeName ($spreadLine)';
      } else {
        foundPick = homeName;
      }
    }

    return foundPick;
  }

  String _resolvePickSide(String pick, String awayTeam, String homeTeam) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final p = norm(pick);
    final a = norm(awayTeam);
    final h = norm(homeTeam);

    if (p.isEmpty) return 'UNKNOWN';
    if (p == a || (a.length >= 3 && p.contains(a))) return 'AWAY';
    if (p == h || (h.length >= 3 && p.contains(h))) return 'HOME';
    return 'UNKNOWN';
  }

  String _extractCleanTeamRobust(
      String rawVal, String awayTeam, String homeTeam) {
    if (rawVal.trim().isEmpty || rawVal == 'TBD') return homeTeam;
    String s = rawVal.trim();
    if (s.toUpperCase().contains('SKIP') ||
        s.toUpperCase().contains('DEAD') ||
        s.toUpperCase().contains('PASS')) {
      s = s.replaceAll(RegExp(r'^[^a-zA-Z0-9]+'), '').trim();
      if (s.toUpperCase().startsWith('SKIP'))
        return '⏩ $s';
      else
        return '⏩ SKIP ($s)';
    }
    String clean = s.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    clean = clean.replaceAll(RegExp(r'^[👑🏆🔥⚖️🎯🟢🔴⏸️⏳\s]+'), '').trim();
    if (clean.contains(':')) clean = clean.split(':').last.trim();
    return clean.isEmpty ? homeTeam : clean;
  }

  Map _parseGameItem(
      Map item, String activeTier, String activeSport, String activeMode) {
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

    final baseData = {
      '_raw': item,
      'matchup': rawMatchup,
      'game_date':
          _getFlexibleDeep(item, ['game_date', 'slate_date', 'date'], ''),
      'away_name': awayName,
      'home_name': homeName,
    };

    Map auditMap = {};
    if (activeMode == 'AUDIT') {
      if (activeTier.contains('TIER 1') && item['tier1_audit'] is Map)
        auditMap = item['tier1_audit'];
      else if (activeTier.contains('TIER 2') && item['tier2_audit'] is Map)
        auditMap = item['tier2_audit'];
      else if (activeTier.contains('TIER 3')) {
        if (item['tier3_audit'] is Map)
          auditMap = item['tier3_audit'];
        else if (item['tier3'] is Map)
          auditMap = item['tier3'];
        else if (item['option_4'] is Map)
          auditMap = item['option_4'];
        else
          auditMap = item;
      } else
        auditMap = item;
    } else {
      if (activeTier.contains('TIER 1') && item['tier1_parlay'] is Map)
        auditMap = item['tier1_parlay'];
      else if (activeTier.contains('TIER 2') && item['tier2'] is Map)
        auditMap = item['tier2'];
      else if (activeTier.contains('TIER 3')) {
        if (item['tier3'] is Map)
          auditMap = item['tier3'];
        else if (item['tier3_prospective'] is Map)
          auditMap = item['tier3_prospective'];
        else if (item['option_4'] is Map)
          auditMap = item['option_4'];
        else
          auditMap = item;
      } else
        auditMap = item;
    }

    String extractedScore =
        _getFlexibleDeep(auditMap, ['fg_score', 'final_score', 'score'], '');
    if (extractedScore.isEmpty)
      extractedScore =
          _getFlexibleDeep(item, ['fg_score', 'final_score', 'score'], '');

    if (activeTier.contains('TIER 1')) {
      String l1Label = 'FIRST 7';
      if (activeSport == 'MLB')
        l1Label = 'NRFI';
      else if (activeSport == 'NBA')
        l1Label = 'FIRST TO 20';
      else if (activeSport == 'NHL') l1Label = 'FIRST TO SCORE';

      String l2Label = '1H ML';
      if (activeSport == 'MLB')
        l2Label = 'F5 ML';
      else if (activeSport == 'NHL') l2Label = '2P ML';

      String l3Label = 'FULL ML';

      String defaultL1Pick = 'TARGET';
      if (activeSport == 'MLB')
        defaultL1Pick = 'NRFI TARGET';
      else if (activeSport == 'NBA')
        defaultL1Pick = 'FIRST TO 20 TARGET';
      else if (activeSport == 'NHL')
        defaultL1Pick = 'FIRST TO SCORE TARGET';
      else
        defaultL1Pick = homeName;

      final leg1Candidates = [
        'leg_1_race_to_20',
        'leg_1_race_to_20_pick',
        'race_to_20_pick',
        'race_to_20',
        'first_to_20_pick',
        'first_to_20',
        'leg_1_first_to_20',
        'leg_1_first_to_score',
        'first_to_score_pick',
        'first_to_score',
        'leg_1_first_7_pick',
        'first_7_pick',
        'first_7',
        'leg_1_nrfi_pick',
        'nrfi_pick',
        'leg_1_pick',
        'leg_1',
        'leg1'
      ];
      final leg1GradeCandidates = [
        'l1_status',
        'leg_1_status',
        'l1_grade',
        'leg_1_grade',
        'leg_1_outcome',
        'race_to_20_grade',
        'first_to_20_grade',
        'first_to_score_grade',
        'first_7_grade',
        'leg_1_race_to_20_grade',
        'leg_1_first_7_grade'
      ];

      final leg2Candidates = [
        'leg_2_1h_winner',
        'leg_2_1h_winner_pick',
        '1h_winner',
        '1h_winner_pick',
        'leg_2_1st_half_pick',
        '1st_half_pick',
        '1h_pick',
        '1h_ml_pick',
        'f5_ml_pick',
        '2p_ml_pick',
        'leg_2_2p_pick',
        'leg_2_f5_pick',
        'leg_2_pick',
        'leg_2',
        'leg2'
      ];
      final leg2GradeCandidates = [
        'l2_status',
        'leg_2_status',
        'l2_grade',
        'leg_2_grade',
        'leg_2_outcome',
        '1h_grade',
        '1h_winner_grade',
        'first_half_grade',
        '2p_grade',
        'f5_grade',
        'leg_2_1h_grade'
      ];

      final leg3Candidates = [
        'leg_3_full_game_ml',
        'leg_3_full_game_ml_pick',
        'full_game_ml',
        'full_game_ml_pick',
        'leg_3_moneyline_pick',
        'fg_ml_pick',
        'full_ml_pick',
        'ml_pick',
        'leg_3_pick',
        'leg_3',
        'leg3'
      ];
      final leg3GradeCandidates = [
        'l3_status',
        'leg_3_status',
        'l3_grade',
        'leg_3_grade',
        'leg_3_outcome',
        'fg_ml_grade',
        'full_game_ml_grade',
        'full_ml_grade',
        'fg_grade',
        'ml_grade',
        'leg_3_fg_ml_grade'
      ];

      String rawL1 = _getFlexibleDeep(auditMap, leg1Candidates, '');
      if (rawL1.isEmpty)
        rawL1 = _getFlexibleDeep(item, leg1Candidates, defaultL1Pick);
      String l1ExplicitGrade =
          _getFlexibleDeep(auditMap, leg1GradeCandidates, '');
      if (l1ExplicitGrade.isEmpty)
        l1ExplicitGrade = _getFlexibleDeep(item, leg1GradeCandidates, '');
      String l1Status = _extractLegStatus(rawL1, l1ExplicitGrade, activeMode);
      String l1Pick = _cleanLegPick(rawL1, defaultL1Pick);

      String defaultL2Pick = activeSport == 'NCAAF' ? homeName : '$homeName ML';
      String rawL2 = _getFlexibleDeep(auditMap, leg2Candidates, '');
      if (rawL2.isEmpty)
        rawL2 = _getFlexibleDeep(item, leg2Candidates, defaultL2Pick);
      String l2ExplicitGrade =
          _getFlexibleDeep(auditMap, leg2GradeCandidates, '');
      if (l2ExplicitGrade.isEmpty)
        l2ExplicitGrade = _getFlexibleDeep(item, leg2GradeCandidates, '');
      String l2Status = _extractLegStatus(rawL2, l2ExplicitGrade, activeMode);
      String l2Pick = _cleanLegPick(rawL2, defaultL2Pick);

      String defaultL3Pick = activeSport == 'NCAAF' ? homeName : '$homeName ML';
      String rawL3 = _getFlexibleDeep(auditMap, leg3Candidates, '');
      if (rawL3.isEmpty)
        rawL3 = _getFlexibleDeep(item, leg3Candidates, defaultL3Pick);
      String l3ExplicitGrade =
          _getFlexibleDeep(auditMap, leg3GradeCandidates, '');
      if (l3ExplicitGrade.isEmpty)
        l3ExplicitGrade = _getFlexibleDeep(item, leg3GradeCandidates, '');
      String l3Status = _extractLegStatus(rawL3, l3ExplicitGrade, activeMode);
      String l3Pick = _cleanLegPick(rawL3, defaultL3Pick);

      bool isMixMatch = false;
      String c1 = l1Pick.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      String c2 = l2Pick.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      String c3 = l3Pick.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (!c1.contains('nrfi') &&
          !c1.contains('yrfi') &&
          !c1.contains('target')) {
        if (!c1.contains(c2) && !c2.contains(c1)) isMixMatch = true;
        if (!c2.contains(c3) && !c3.contains(c2)) isMixMatch = true;
      } else {
        isMixMatch = true;
      }

      String badgeType = 'PENDING';
      if (activeMode == 'AUDIT') {
        int winCount = 0;
        int lossCount = 0;
        for (var st in [l1Status, l2Status, l3Status]) {
          if (st == 'WIN')
            winCount++;
          else if (st == 'LOSS') lossCount++;
        }

        if (winCount == 3) {
          badgeType = 'SWEEP_HIT';
        } else if (lossCount == 3) {
          badgeType = 'SWEEP_LOSS';
        } else if (l1Status == 'PENDING' ||
            l2Status == 'PENDING' ||
            l3Status == 'PENDING') {
          badgeType = 'PENDING';
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

      String rawL1 = _getFlexibleDeep(
          auditMap,
          [
            'chamber_topography_ml',
            'topography_ml_pick',
            'moneyline_winner',
            'topography_pick'
          ],
          '');
      if (rawL1.isEmpty)
        rawL1 = _getFlexibleDeep(
            item,
            [
              'chamber_topography_ml',
              'topography_ml_pick',
              'moneyline_winner',
              'topography_pick'
            ],
            homeName);
      String l1Pick = _extractCleanTeamRobust(rawL1, awayName, homeName);

      String rawL2 = _getFlexibleDeep(
          auditMap,
          [
            'insignia_synergy_ml',
            'insignia_ml_pick',
            'ml_projector_winner',
            'insignia_pick'
          ],
          '');
      if (rawL2.isEmpty)
        rawL2 = _getFlexibleDeep(
            item,
            [
              'insignia_synergy_ml',
              'ml_projector_winner',
              'insignia_ml_pick',
              'insignia_pick'
            ],
            awayName);
      String l2Pick = _extractCleanTeamRobust(rawL2, awayName, homeName);

      String l1Status = 'PENDING';
      String l2Status = 'PENDING';

      if (activeMode == 'AUDIT') {
        if (l1Pick.toUpperCase().contains('SKIP') ||
            l1Pick.toUpperCase().contains('DEAD') ||
            l1Pick.toUpperCase().contains('PASS') ||
            rawL1.toUpperCase().contains('SKIP')) {
          l1Status = 'SKIP';
        }
        if (l2Pick.toUpperCase().contains('SKIP') ||
            l2Pick.toUpperCase().contains('DEAD') ||
            l2Pick.toUpperCase().contains('PASS') ||
            rawL2.toUpperCase().contains('SKIP')) {
          l2Status = 'SKIP';
        }

        final l1GradeCandidates = [
          'l1_status',
          'leg_1_status',
          'l1_grade',
          'leg_1_grade',
          'topography_ml_grade',
          'topography_grade',
          'chamber_topography_grade',
          'chamber_grade',
          'leg_1_outcome'
        ];
        String l1Explicit = _getFlexibleDeep(auditMap, l1GradeCandidates, '');
        if (l1Explicit.isEmpty)
          l1Explicit = _getFlexibleDeep(item, l1GradeCandidates, '');
        if (l1Status == 'PENDING') {
          l1Status = _extractLegStatus(rawL1, l1Explicit, activeMode);
        }

        final l2GradeCandidates = [
          'l2_status',
          'leg_2_status',
          'l2_grade',
          'leg_2_grade',
          'insignia_synergy_grade',
          'insignia_ml_grade',
          'insignia_grade',
          'synergy_grade',
          'leg_2_outcome'
        ];
        String l2Explicit = _getFlexibleDeep(auditMap, l2GradeCandidates, '');
        if (l2Explicit.isEmpty)
          l2Explicit = _getFlexibleDeep(item, l2GradeCandidates, '');
        if (l2Status == 'PENDING') {
          l2Status = _extractLegStatus(rawL2, l2Explicit, activeMode);
        }
      }

      String badgeType = 'PENDING';
      if (activeMode == 'AUDIT') {
        if (l1Status == 'WIN' && l2Status == 'WIN') {
          badgeType = 'SWEEP_HIT';
        } else if (l1Status == 'LOSS' && l2Status == 'LOSS') {
          badgeType = 'SWEEP_LOSS';
        } else if (l1Status == 'PENDING' || l2Status == 'PENDING') {
          badgeType = 'PENDING';
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
      // --- TIER 3 (SPREAD / SPREAD DEFICIT / OPTION 4) ---
      String l1Label = 'SPREAD COVER';
      if (activeSport == 'MLB') {
        l1Label = 'OPTION 4 PICK';
      } else if (activeSport == 'NHL') {
        l1Label = (activeMode == 'AUDIT') ? 'ML RESULT' : 'ML PICK';
      }

      String cleanPick = _extractSpreadCoverPick(
          item, auditMap, awayName, homeName, activeSport);

      final t3GradeCandidates = [
        'spread_cover_outcome_status',
        'option_4_outcome_status',
        'on_4_outcome_status',
        'option_4_outcome',
        'option_4_grade',
        'option_4_status',
        'option4_outcome_status',
        'option4_outcome',
        'option4_grade',
        'opt_4_outcome_status',
        'opt_4_grade',
        'outcome_status',
        'model_spread_cover_grade',
        'ats_cover_grade',
        'spread_cover_grade',
        'spread_grade',
        'grade',
        'outcome',
        'status',
        'l1_status',
      ];

      String rawGradeText = _getFlexibleDeep(auditMap, t3GradeCandidates, '');
      if (rawGradeText.isEmpty) {
        rawGradeText = _getFlexibleDeep(item, t3GradeCandidates, '');
      }

      String rawPickField = _getFlexibleDeep(
          auditMap,
          [
            'master_matrix_spread_cover_pick',
            'option_4_projected_winner',
            'on_4_projected_winner',
            'projected_winner',
            'option_4',
            'model_spread_cover_verdict',
            'ats_cover_pick',
          ],
          '');
      if (rawPickField.isEmpty) {
        rawPickField = _getFlexibleDeep(
            item,
            [
              'master_matrix_spread_cover_pick',
              'option_4_projected_winner',
              'on_4_projected_winner',
              'projected_winner',
              'option_4',
              'model_spread_cover_verdict',
              'ats_cover_pick',
            ],
            '');
      }

      String outcomeStatus =
          _extractLegStatus(rawPickField, rawGradeText, activeMode);

      if (activeMode == 'AUDIT' &&
          outcomeStatus == 'LOSS' &&
          !rawGradeText.toUpperCase().contains('LOSS') &&
          !rawPickField.toUpperCase().contains('LOSS') &&
          extractedScore.isNotEmpty) {
        final pts = RegExp(r'\d+')
            .allMatches(extractedScore.replaceAll('[FINAL]', ''))
            .map((m) => int.tryParse(m.group(0)!) ?? 0)
            .toList();
        if (pts.length >= 2) {
          String winningSide = 'UNKNOWN';
          if (pts[0] > pts[1])
            winningSide = 'AWAY';
          else if (pts[1] > pts[0]) winningSide = 'HOME';
          final pickSide = _resolvePickSide(cleanPick, awayName, homeName);
          if (pickSide != 'UNKNOWN' && winningSide != 'UNKNOWN') {
            outcomeStatus = (pickSide == winningSide) ? 'WIN' : 'LOSS';
          }
        }
      }

      String badgeType = activeMode == 'AUDIT'
          ? (outcomeStatus.toUpperCase().contains('WIN')
              ? 'SWEEP_HIT'
              : 'SWEEP_LOSS')
          : 'PENDING';

      final marginCandidates = [
        'ats_cover_margin',
        'option_4_cover_margin',
        'cover_margin',
        'spread_cover_margin',
        'margin'
      ];
      String marginInfo = activeMode == 'AUDIT'
          ? _getFlexibleDeep(auditMap, marginCandidates, '')
          : '';
      if (marginInfo.isEmpty && activeMode == 'AUDIT') {
        marginInfo = _getFlexibleDeep(item, marginCandidates, '');
      }
      if (marginInfo.isNotEmpty) {
        marginInfo = 'Margin: $marginInfo';
      }

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
        'l1_status': outcomeStatus,
        'l1_margin': marginInfo,
      };
    }
  }

  // --- STRICT SPORT-AWARE FLATTENER (PREVENTS PINNED SLATE BUG & EXCLUDES EOD FOR WEEKLY SPORTS) ---
  List _flattenDossiers(
      List docs, String activeTier, String activeSport, String activeMode,
      {String? pinnedDocId}) {
    final String sportKey = activeSport.toLowerCase();
    final bool isWeeklySport = (sportKey == 'nfl' || sportKey == 'ncaaf');
    dynamic targetDoc;

    if (pinnedDocId != null) {
      try {
        targetDoc = docs.firstWhere((d) {
          final id = d.reference.id.toLowerCase();
          if (isWeeklySport && id.contains('eod')) return false;
          return d.reference.id == pinnedDocId &&
              id.contains(sportKey) &&
              _isDocMatchingMode(id, activeMode, sport: activeSport);
        });
      } catch (_) {
        targetDoc = null;
      }
    }

    if (targetDoc == null) {
      List candidates = docs.where((d) {
        final id = d.reference.id.toLowerCase();
        if (isWeeklySport && id.contains('eod')) return false;
        return id.contains(sportKey) &&
            id.contains('master') &&
            _isDocMatchingMode(id, activeMode, sport: activeSport);
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

    Map data = targetDoc.snapshotData;
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
      for (var k in numericKeys) if (data[k] is Map) rawGamesList.add(data[k]);
      if (rawGamesList.isEmpty) {
        data.forEach((k, v) {
          if (v is Map &&
              (v.containsKey('game_matchup') || v.containsKey('matchup')))
            rawGamesList.add(v);
        });
      }
    }

    final Map consolidatedRawGames = {};
    final List canonicalOrder = [];
    for (var rawGame in rawGamesList) {
      if (rawGame is Map) {
        final gMap = Map.from(rawGame);
        if (!_isValidGameItem(gMap)) continue;
        final rawM = _getFlexibleDeep(
            gMap, ['game_matchup', 'matchup', 'game', 'event'], '');
        final cleanRaw =
            rawM.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s@]'), ' ');
        List parts = cleanRaw.contains('@') ? cleanRaw.split('@') : [cleanRaw];
        List mascots = [];
        for (var part in parts) {
          final words = part
              .toString()
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
                  existing[k] == '')
                existing[k] = v;
              else if (v is Map && existing[k] is Map) {
                existing[k] = {...Map.from(existing[k] as Map), ...Map.from(v)};
              }
            });
          }
        }
      }
    }

    final List parsedGames = [];
    for (var cKey in canonicalOrder) {
      final unifiedGame = consolidatedRawGames[cKey]!;
      final parsed =
          _parseGameItem(unifiedGame, activeTier, activeSport, activeMode);
      parsedGames.add(parsed);
    }
    return parsedGames;
  }

  Map _calculateKPIs(List games, String activeTier) {
    if (games.isEmpty)
      return {'eval': '0', 'sweeps': '0', 'winPct': '0.0%', 'pending': '0'};
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

  // --- REUSABLE IN-PANE DOSSIER WORKSPACE ---
  Widget _buildDossierWorkspaceViewer(List effectiveDocs, bool isSubscribed,
      {required bool isLeftPane}) {
    if (!isSubscribed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  color: Color(0xFFD4AF37), size: 48),
              const SizedBox(height: 16),
              const Text('MASTER DOSSIER VAULT LOCKED',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              const Text(
                'Subscribe to Tailzs All-Access to inspect and compare unredacted analyst Master Dossier slates side-by-side.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF8A99A6), fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _triggerDeepDiveOceanHaptic();
                  _showPaywallModal(context, 'UNLOCK DOSSIER WORKSPACE');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E00),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('UNLOCK DOSSIER VAULT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              )
            ],
          ),
        ),
      );
    }

    final activeDocId = isLeftPane ? _leftActivePdfDocId : _rightActivePdfDocId;
    final activeFile = isLeftPane ? _leftActivePdfFile : _rightActivePdfFile;
    final activeUrl = isLeftPane ? _leftActivePdfUrl : _rightActivePdfUrl;
    final isLoading = isLeftPane ? _leftIsPdfLoading : _rightIsPdfLoading;

    if (activeDocId != null) {
      return Container(
        color: const Color(0xFF080C0E),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0B1114),
                border: Border(bottom: BorderSide(color: Color(0xFF24343B))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Color(0xFF00F5D4), size: 18),
                    onPressed: () {
                      _triggerElectricHapticBuzz();
                      setState(() {
                        if (isLeftPane) {
                          _leftActivePdfDocId = null;
                          _leftActivePdfFile = null;
                          _leftActivePdfUrl = null;
                          _leftIsPdfLoading = false;
                        } else {
                          _rightActivePdfDocId = null;
                          _rightActivePdfFile = null;
                          _rightActivePdfUrl = null;
                          _rightIsPdfLoading = false;
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeDocId.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          activeFile != null
                              ? 'Edge-Cached Locally (\$0 Data Bandwidth)'
                              : 'Live PDF Stream',
                          style: const TextStyle(
                              color: Color(0xFF8A99A6), fontSize: 8.5),
                        ),
                      ],
                    ),
                  ),
                  if (activeUrl != null && activeUrl.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.open_in_new,
                          color: Color(0xFF8A99A6), size: 16),
                      onPressed: () => _launchExternalUrl(activeUrl),
                    ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFD4AF37)),
                          SizedBox(height: 14),
                          Text('Caching Master Dossier to Local Disk...',
                              style: TextStyle(
                                  color: Color(0xFF8A99A6), fontSize: 11)),
                        ],
                      ),
                    )
                  : (activeFile != null && !kIsWeb)
                      ? SfPdfViewer.file(
                          activeFile,
                          canShowScrollHead: false,
                          canShowScrollStatus: false,
                          enableDoubleTapZooming: true,
                        )
                      : (activeUrl != null && activeUrl.isNotEmpty)
                          ? SfPdfViewer.network(
                              activeUrl,
                              canShowScrollHead: false,
                              canShowScrollStatus: false,
                              enableDoubleTapZooming: true,
                            )
                          : const Center(
                              child: Text('Unable to load document.',
                                  style: TextStyle(color: Color(0xFFFF5E00))),
                            ),
            ),
          ],
        ),
      );
    }

    final activeSportScope = isLeftPane ? selectedSport : _rightSport;
    final String sportKey = activeSportScope.toLowerCase();
    final bool isWeeklySport = (sportKey == 'nfl' || sportKey == 'ncaaf');

    // Filter documents strictly: for NFL and NCAAF, purge all daily EOD documents
    final matchingDocs = effectiveDocs.where((d) {
      final id = d.reference.id.toLowerCase();
      if (!id.contains(sportKey) || !id.contains('master')) return false;
      if (isWeeklySport && id.contains('eod')) return false;
      return true;
    }).toList();

    final currentPinnedId =
        isLeftPane ? selectedDossierDocId : _rightSelectedDossierDocId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1114),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF24343B), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Color(0xFFD4AF37), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$activeSportScope MASTER DOSSIER VAULT',
                          style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6)),
                      const SizedBox(height: 2),
                      Text(
                          '${matchingDocs.length} slate documents archived for $activeSportScope',
                          style: const TextStyle(
                              color: Color(0xFF8A99A6), fontSize: 9.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (matchingDocs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text('No Master Dossiers found for $activeSportScope.',
                  style:
                      const TextStyle(color: Color(0xFF8A99A6), fontSize: 11)),
            )
          else
            ...matchingDocs.map((doc) {
              final docId = doc.reference.id;
              final lowerDocId = docId.toLowerCase();
              final isSelected = (currentPinnedId == docId) ||
                  (currentPinnedId == null && lowerDocId.contains('latest'));

              // Correctly recognize EOW, EOD, and AUDIT as completed audit slates
              final isAudit = lowerDocId.contains('eod') ||
                  lowerDocId.contains('eow') ||
                  lowerDocId.contains('audit');

              final data = doc.snapshotData;
              final pdfUrl = (data != null && data.containsKey('pdf_url'))
                  ? data['pdf_url'].toString()
                  : widget.dossierUrl ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD4AF37).withOpacity(0.08)
                      : const Color(0xFF0E1619),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF24343B),
                      width: isSelected ? 1.5 : 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Icon(
                    isAudit ? Icons.fact_check : Icons.picture_as_pdf,
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF8A99A6),
                    size: 22,
                  ),
                  title: Text(
                    docId.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFFC4D1D9),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    isAudit
                        ? (isWeeklySport
                            ? 'Verified End-of-Week Audit Slate'
                            : 'Verified End-of-Day Audit Slate')
                        : 'Pre-Game Prospective Slate',
                    style:
                        const TextStyle(color: Color(0xFF8A99A6), fontSize: 9),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _openDossierPdfInPane(docId, pdfUrl,
                              isLeftPane: isLeftPane);
                        },
                        icon: const Icon(Icons.visibility,
                            size: 12, color: Color(0xFF080C0E)),
                        label: const Text('VIEW',
                            style: TextStyle(
                                color: Color(0xFF080C0E),
                                fontSize: 9,
                                fontWeight: FontWeight.w900)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: () {
                          _triggerElectricHapticBuzz();
                          setState(() {
                            if (isLeftPane) {
                              selectedDossierDocId = docId;
                            } else {
                              _rightSelectedDossierDocId = docId;
                            }
                            _gamesCache.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          side: const BorderSide(color: Color(0xFF24343B)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(isSelected ? 'ACTIVE' : 'LOAD',
                            style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF00F5D4)
                                    : const Color(0xFF8A99A6),
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // --- SECONDARY LIVE TERMINAL FEED ---
  Widget _buildSecondaryLiveTerminal(List effectiveDocs, bool isSubscribed) {
    final String docIdScope = _rightSelectedDossierDocId ?? 'auto';
    final String rightCacheKey =
        '${_rightSport}_${_rightMode}_${_rightTier}_${docIdScope}_${effectiveDocs.length}';
    List rightGames;
    if (_gamesCache.containsKey(rightCacheKey)) {
      rightGames = _gamesCache[rightCacheKey]!;
    } else {
      rightGames = effectiveDocs.isNotEmpty
          ? _flattenDossiers(effectiveDocs, _rightTier, _rightSport, _rightMode,
              pinnedDocId: _rightSelectedDossierDocId)
          : [];
      if (rightGames.isNotEmpty) _gamesCache[rightCacheKey] = rightGames;
    }
    final rightKpis = _calculateKPIs(rightGames, _rightTier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TailzsQuantCommandHeader(
            selectedMode: _rightMode,
            selectedSport: _rightSport,
            selectedTier: _rightTier,
            onModeChanged: (val) async {
              HapticFeedback.mediumImpact();
              setState(() {
                _rightMode = val;
                _rightSelectedDossierDocId = null;
                _gamesCache.clear();
              });
            },
            onSportChanged: (val) async {
              HapticFeedback.mediumImpact();
              setState(() {
                _rightSport = val;
                _rightSelectedDossierDocId = null;
                _gamesCache.clear();
              });
            },
            onTierChanged: (val) async {
              HapticFeedback.mediumImpact();
              setState(() => _rightTier = val);
            },
            onSearchChanged: (val) async {
              setState(() => _rightSearch = val);
            },
            onSettingsTapped: () async =>
                _showSettingsModal(context, isSubscribed),
          ),
          const SizedBox(height: 14),
          TailzsQuantVaultKpiBar(
            isSub: isSubscribed,
            selectedSport: _rightSport,
            selectedMode: _rightMode,
            evalCount: int.tryParse(rightKpis['eval']!) ?? 0,
            sweepsCount: int.tryParse(rightKpis['sweeps']!) ?? 0,
            winPercent:
                double.tryParse(rightKpis['winPct']!.replaceAll('%', '')) ??
                    0.0,
            pendingCount: int.tryParse(rightKpis['pending']!) ?? 0,
            gamesQueuedCount: rightGames.length,
            dossierDocs: effectiveDocs.isNotEmpty ? effectiveDocs.first : null,
            dossierUrl: widget.dossierUrl,
            selectedDossierDocId: _rightSelectedDossierDocId,
            onUpgradeTapped: () async {
              _triggerElectricHapticBuzz();
              setState(() => _rightWorkspaceMode = 'DOSSIER');
            },
          ),
          const SizedBox(height: 14),
          TailzsQuantCardFeed(
            games: rightGames,
            isSub: isSubscribed,
            selectedMode: _rightMode,
            selectedSport: _rightSport,
            selectedTier: _rightTier,
            searchQuery: _rightSearch,
            onUpgradeTapped: () async {
              _triggerDeepDiveOceanHaptic();
              _showPaywallModal(context, 'UNLOCK DEEP DIVE INSIGHTS');
            },
          ),
        ],
      ),
    );
  }

  // --- SYMMETRIC WORKSPACE SWITCHER BAR ---
  Widget _buildPaneHeaderBar({
    required String activeMode,
    required String liveLabel,
    required Function() onLiveTap,
    required Function() onDossierTap,
  }) {
    final bool isLive = activeMode == 'LIVE_APP' || activeMode == 'DUAL_APP';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFF24343B), width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLiveTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFF00F5D4).withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isLive
                          ? const Color(0xFF00F5D4)
                          : const Color(0xFF24343B)),
                ),
                alignment: Alignment.center,
                child: Text(liveLabel,
                    style: TextStyle(
                        color: isLive
                            ? const Color(0xFF00F5D4)
                            : const Color(0xFF8A99A6),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onDossierTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !isLive
                      ? const Color(0xFFD4AF37).withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: !isLive
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF24343B)),
                ),
                alignment: Alignment.center,
                child: Text('📄 DOSSIER WORKSPACE',
                    style: TextStyle(
                        color: !isLive
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF8A99A6),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser ?? FirebaseAuth.instance.currentUser;
    final userEmail = user?.email?.toLowerCase() ?? '';
    final bool isVipUser =
        userEmail.contains('reviewer') || userEmail.contains('tailzs.com');
    final bool isSubscribed =
        _rcIsSubscribed || isVipUser || (widget.isSub ?? false);

    final List effectiveDocs =
        (widget.dossierDocs != null && widget.dossierDocs!.isNotEmpty)
            ? widget.dossierDocs!
            : _localDossierDocs;
    if (effectiveDocs.isEmpty && !_isLoadingDocs) _fetchDossiersFallback();

    final String docIdScope = selectedDossierDocId ?? 'auto';
    final String cacheKey =
        '${selectedSport}_${selectedMode}_${selectedTier}_${docIdScope}_${effectiveDocs.length}';
    List games;
    if (_gamesCache.containsKey(cacheKey)) {
      games = _gamesCache[cacheKey]!;
    } else {
      games = effectiveDocs.isNotEmpty
          ? _flattenDossiers(
              effectiveDocs, selectedTier, selectedSport, selectedMode,
              pinnedDocId: selectedDossierDocId)
          : [];
      if (games.isNotEmpty) _gamesCache[cacheKey] = games;
    }
    final kpis = _calculateKPIs(games, selectedTier);

    Widget leftFeedContent = Column(
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
              selectedDossierDocId = null;
              _gamesCache.clear();
            });
          },
          onSportChanged: (val) async {
            HapticFeedback.mediumImpact();
            setState(() {
              selectedSport = val;
              selectedDossierDocId = null;
              _gamesCache.clear();
            });
          },
          onTierChanged: (val) async {
            HapticFeedback.mediumImpact();
            setState(() => selectedTier = val);
          },
          onSearchChanged: (val) async {
            setState(() => searchQuery = val);
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
          dossierDocs: effectiveDocs.isNotEmpty ? effectiveDocs.first : null,
          dossierUrl: widget.dossierUrl,
          selectedDossierDocId: selectedDossierDocId,
          onUpgradeTapped: () async {
            _triggerElectricHapticBuzz();
            setState(() => _rightWorkspaceMode = 'DOSSIER');
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
          onUpgradeTapped: () async {
            _triggerDeepDiveOceanHaptic();
            _showPaywallModal(context, 'UNLOCK DEEP DIVE INSIGHTS');
          },
        ),
      ],
    );

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: const Color(0xFF080C0E),
      child: SafeArea(
        maintainBottomViewPadding: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 720 && !_forceSinglePane) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 48,
                    child: Container(
                      color: const Color(0xFF080C0E),
                      child: Column(
                        children: [
                          _buildPaneHeaderBar(
                            activeMode: _leftWorkspaceMode,
                            liveLabel: '📊 PRIMARY FEED',
                            onLiveTap: () {
                              _triggerElectricHapticBuzz();
                              setState(() => _leftWorkspaceMode = 'LIVE_APP');
                            },
                            onDossierTap: () {
                              _triggerElectricHapticBuzz();
                              setState(() => _leftWorkspaceMode = 'DOSSIER');
                            },
                          ),
                          Expanded(
                            child: _leftWorkspaceMode == 'LIVE_APP'
                                ? SingleChildScrollView(
                                    padding: const EdgeInsets.all(16.0),
                                    child: leftFeedContent)
                                : _buildDossierWorkspaceViewer(
                                    effectiveDocs, isSubscribed,
                                    isLeftPane: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 3,
                    color: const Color(0xFF050809),
                    child: Center(
                      child: Container(
                        width: 1.5,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF24343B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 52,
                    child: Container(
                      color: const Color(0xFF050809),
                      child: Column(
                        children: [
                          _buildPaneHeaderBar(
                            activeMode: _rightWorkspaceMode,
                            liveLabel: '📊 DUAL LIVE APP',
                            onLiveTap: () {
                              _triggerElectricHapticBuzz();
                              setState(() => _rightWorkspaceMode = 'DUAL_APP');
                            },
                            onDossierTap: () {
                              _triggerElectricHapticBuzz();
                              setState(() => _rightWorkspaceMode = 'DOSSIER');
                            },
                          ),
                          Expanded(
                            child: _rightWorkspaceMode == 'DUAL_APP'
                                ? _buildSecondaryLiveTerminal(
                                    effectiveDocs, isSubscribed)
                                : _buildDossierWorkspaceViewer(
                                    effectiveDocs, isSubscribed,
                                    isLeftPane: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: leftFeedContent,
            );
          },
        ),
      ),
    );
  }
}
