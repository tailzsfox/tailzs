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

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TailzsLoginScreen extends StatefulWidget {
  const TailzsLoginScreen({
    Key? key,
    this.width,
    this.height,
    this.targetPageName,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String? targetPageName;

  @override
  State<TailzsLoginScreen> createState() => _TailzsLoginScreenState();
}

class _TailzsLoginScreenState extends State<TailzsLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _loginSucceeded = false;

  void Function(CustomerInfo)? _customerInfoListener;

  bool get _isIOS =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _initAndCheckSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    if (_customerInfoListener != null && !kIsWeb) {
      Purchases.removeCustomerInfoUpdateListener(_customerInfoListener!);
    }
    super.dispose();
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool remember = prefs.getBool('tailzs_remember_me') ?? false;
      final String savedEmail = prefs.getString('tailzs_remember_email') ?? '';
      if (remember && savedEmail.isNotEmpty) {
        setState(() {
          _rememberMe = true;
          _emailController.text = savedEmail;
        });
      }
    } catch (e) {
      debugPrint('Remember Me load notice: $e');
    }
  }

  Future<void> _ensureRevenueCatConfigured() async {
    if (kIsWeb) return;
    try {
      final isConfigured = await Purchases.isConfigured;
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
    } catch (e) {
      debugPrint('RC Configuration guard notice: $e');
    }
  }

  // --- HARDWARE DEVICE REGISTRATION ENFORCING MAXIMUM 3 CONCURRENT DEVICES ---
  Future<void> _syncDeviceRegistration(
      String uid, SharedPreferences prefs) async {
    try {
      String? deviceId = prefs.getString('tailzs_device_id');
      if (deviceId == null) {
        deviceId =
            '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(999999)}';
        await prefs.setString('tailzs_device_id', deviceId);
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await userRef.get();

      List<String> activeDevices = [];
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('active_devices')) {
        activeDevices = List<String>.from(doc.data()!['active_devices']);
      }

      if (!activeDevices.contains(deviceId)) {
        // Enforce maximum 3 devices: evicts the oldest device if a 4th logs in
        if (activeDevices.length >= 3) {
          activeDevices.removeAt(0);
        }
        activeDevices.add(deviceId);
        await userRef.set({
          'active_devices': activeDevices,
          'last_login': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (dbError) {
      debugPrint('Device tracking notice: $dbError');
    }
  }

  Future<void> _initAndCheckSession() async {
    await _ensureRevenueCatConfigured();

    if (!kIsWeb) {
      _customerInfoListener = (info) {
        if (mounted) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && !currentUser.isAnonymous) {
            final entitlement = info.entitlements.all['tailzs'];
            final bool isSubbed =
                (entitlement != null && entitlement.isActive) ||
                    info.entitlements.active.isNotEmpty;

            if (isSubbed) {
              _dismissOverlayOrNavigate();
            }
          }
        }
      };
      Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !currentUser.isAnonymous) {
        if (!kIsWeb) {
          try {
            if (await Purchases.isConfigured) {
              await Purchases.logIn(currentUser.uid);
            }
          } catch (_) {}
        }

        final prefs = await SharedPreferences.getInstance();
        await _syncDeviceRegistration(currentUser.uid, prefs);

        if (mounted) {
          setState(() => _loginSucceeded = true);
          _dismissOverlayOrNavigate();
        }
      }
    } catch (e) {
      debugPrint('Session check notice: $e');
    }
  }

  void _dismissOverlayOrNavigate() {
    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
        return;
      }
    } catch (_) {}
    _navigateWithFallback();
  }

  void _navigateWithFallback() {
    if (widget.targetPageName != null &&
        widget.targetPageName!.trim().isNotEmpty) {
      try {
        context.goNamed(widget.targetPageName!.trim());
        return;
      } catch (_) {}
    }

    final List<String> pageNames = [
      'Tailzs',
      'TerminalPage',
      'TailzsQuantTerminal',
      'Terminal',
      'QuantTerminal',
      'HomePage',
    ];

    for (var pageName in pageNames) {
      try {
        context.goNamed(pageName);
        return;
      } catch (_) {}
    }

    final List<String> routePaths = [
      '/tailzs',
      '/terminalPage',
      '/terminal',
      '/quantTerminal',
      '/',
    ];

    for (var path in routePaths) {
      try {
        context.go(path);
        return;
      } catch (_) {}
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Email Address first.'),
          backgroundColor: Color(0xFFFF3366),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Reset link sent to $email (check spam/junk folder).'),
            backgroundColor: const Color(0xFF00F5D4),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset Failed: ${e.message ?? e.code}'),
            backgroundColor: const Color(0xFFFF3366),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Email and Password.'),
          backgroundColor: Color(0xFFFF3366),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('tailzs_remember_email', email);
        await prefs.setBool('tailzs_remember_me', true);
      } else {
        await prefs.remove('tailzs_remember_email');
        await prefs.setBool('tailzs_remember_me', false);
      }

      if (FirebaseAuth.instance.currentUser != null &&
          FirebaseAuth.instance.currentUser!.isAnonymous) {
        await FirebaseAuth.instance.signOut();
      }

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        await _ensureRevenueCatConfigured();
        if (!kIsWeb) {
          try {
            if (await Purchases.isConfigured) {
              await Purchases.logIn(user.uid);
            }
          } catch (rcError) {
            debugPrint('RevenueCat login sync notice: $rcError');
          }
        }

        await _syncDeviceRegistration(user.uid, prefs);
      }

      if (mounted) {
        setState(() {
          _loginSucceeded = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✓ Access Granted! Tap ‹ in the top-left corner to enter.'),
            backgroundColor: Color(0xFF00F5D4),
            duration: Duration(seconds: 4),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) {
          _dismissOverlayOrNavigate();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication Failed: ${e.message ?? e.code}'),
            backgroundColor: const Color(0xFFFF3366),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3366),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      await _ensureRevenueCatConfigured();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !currentUser.isAnonymous && !kIsWeb) {
        try {
          if (await Purchases.isConfigured) {
            await Purchases.logIn(currentUser.uid);
          }
        } catch (_) {}
      }

      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('In-App Purchases are managed on your device.'),
              backgroundColor: Color(0xFFFF5E00),
            ),
          );
        }
        return;
      }

      final CustomerInfo info = await Purchases.restorePurchases();
      final entitlement = info.entitlements.all['tailzs'];
      final bool isSubbed = (entitlement != null && entitlement.isActive) ||
          info.entitlements.active.isNotEmpty;

      if (isSubbed) {
        if (currentUser != null) {
          final prefs = await SharedPreferences.getInstance();
          await _syncDeviceRegistration(currentUser.uid, prefs);
        }
        if (mounted) {
          setState(() => _loginSucceeded = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Active subscription confirmed! Unlocking Terminal...'),
              backgroundColor: Color(0xFF00F5D4),
              duration: Duration(seconds: 3),
            ),
          );
          _dismissOverlayOrNavigate();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No active subscription found on this Store account.'),
              backgroundColor: Color(0xFFFF5E00),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore notice: $e'),
            backgroundColor: const Color(0xFFFF3366),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSkipToTerminal() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      await _ensureRevenueCatConfigured();
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Anonymous entry notice: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _dismissOverlayOrNavigate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C0E),
      body: SafeArea(
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF5E00).withOpacity(0.12),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 70,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Image.network(
                              'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/tailzs-9bbvkw/assets/i4jahngiofzu/appleicon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'TAIL',
                                  style: TextStyle(
                                    color: Color(0xFFFF5E00),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'ZS',
                                  style: TextStyle(
                                    color: Color(0xFF00F5D4),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'OUTFOX THE REST',
                            style: TextStyle(
                              color: Color(0xFFF5E5C9),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(22.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF182226),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF24343B), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'SPORTS DATA ANALYTICS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF00F5D4),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Access Granted Banner with Top-Left Arrow Instruction
                          if (_loginSucceeded) ...[
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _dismissOverlayOrNavigate();
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF00F5D4).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF00F5D4),
                                      width: 1.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x3300F5D4),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.arrow_back_ios_new,
                                        color: Color(0xFF00F5D4), size: 16),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'ACCESS GRANTED!\nTap here or the ‹ arrow in the top-left to enter.',
                                        style: TextStyle(
                                          color: Color(0xFF00F5D4),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.touch_app,
                                        color: Color(0xFF00F5D4), size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          const Text(
                            'EMAIL ADDRESS',
                            style: TextStyle(
                              color: Color(0xFF8A99A6),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'user@tailzs.com',
                              hintStyle: const TextStyle(
                                  color: Color(0xFF42545C), fontSize: 12),
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Color(0xFF8A99A6), size: 18),
                              filled: true,
                              fillColor: const Color(0xFF0B1114),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF24343B)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF00F5D4), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'PASSWORD',
                            style: TextStyle(
                              color: Color(0xFF8A99A6),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '••••••••••••',
                              hintStyle: const TextStyle(
                                  color: Color(0xFF42545C), fontSize: 12),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Color(0xFF8A99A6), size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF8A99A6),
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0B1114),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF24343B)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF00F5D4), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _rememberMe = !_rememberMe);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: const Color(0xFF00F5D4),
                                        checkColor: const Color(0xFF080C0E),
                                        side: const BorderSide(
                                            color: Color(0xFF8A99A6),
                                            width: 1.5),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        onChanged: (val) {
                                          HapticFeedback.selectionClick();
                                          setState(
                                              () => _rememberMe = val ?? false);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'REMEMBER ME',
                                      style: TextStyle(
                                        color: Color(0xFF8A99A6),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _handleForgotPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'FORGOT PASSWORD?',
                                  style: TextStyle(
                                    color: Color(0xFF8A99A6),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5E00),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 4,
                              shadowColor: const Color(0x66FF5E00),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                _isLoading ? null : _handleRestorePurchases,
                            icon: const Icon(Icons.restore,
                                color: Color(0xFF00F5D4), size: 14),
                            label: const Text(
                              'RESTORE PURCHASES',
                              style: TextStyle(
                                color: Color(0xFF00F5D4),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              side: const BorderSide(
                                  color: Color(0xFF24343B), width: 1.2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed:
                                _isLoading ? null : _handleSkipToTerminal,
                            child: const Text(
                              'SKIP TO FREE TERMINAL ➔',
                              style: TextStyle(
                                color: Color(0xFF8A99A6),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            _isIOS ? 'Terms of Use (EULA)' : 'Terms of Service',
                            style: const TextStyle(
                              color: Color(0xFF8A99A6),
                              fontSize: 9.5,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Text(
                          '  •  ',
                          style:
                              TextStyle(color: Color(0xFF42545C), fontSize: 10),
                        ),
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await launchURL('https://www.tailzs.com/#privacy');
                          },
                          child: const Text(
                            'Privacy Policy',
                            style: const TextStyle(
                              color: Color(0xFF8A99A6),
                              fontSize: 9.5,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Added v1.0.0+21 Footer Here
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'v1.0.0+21',
                        style: TextStyle(
                          color: Color(0xFF42545C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Functional Top-Left Teal Back Arrow
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF00F5D4),
                    size: 24,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _dismissOverlayOrNavigate();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
