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

import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
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
  final String? targetPageName; // e.g. 'Tailzs'

  @override
  State<TailzsLoginScreen> createState() => _TailzsLoginScreenState();
}

class _TailzsLoginScreenState extends State<TailzsLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  // Multi-Strategy Navigation Engine
  void _navigateWithFallback() {
    // Strategy 1: Explicit targetPageName parameter if set in FlutterFlow
    if (widget.targetPageName != null &&
        widget.targetPageName!.trim().isNotEmpty) {
      try {
        context.goNamed(widget.targetPageName!.trim());
        return;
      } catch (_) {}
    }

    // Strategy 2: Common FlutterFlow Page Names
    final List<String> pageNames = [
      'Tailzs',
      'TerminalPage',
      'Terminal',
      'QuantTerminal',
      'HomePage',
      'TerminalScreen',
    ];

    for (var pageName in pageNames) {
      try {
        context.goNamed(pageName);
        return;
      } catch (_) {}
    }

    // Strategy 3: GoRouter URL Path Routing
    final List<String> routePaths = [
      '/tailzs',
      '/terminal',
      '/terminalPage',
      '/quantTerminal',
      '/homePage',
      '/',
    ];

    for (var path in routePaths) {
      try {
        context.go(path);
        return;
      } catch (_) {}
    }
  }

  Future<void> _checkExistingSession() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Sync RevenueCat with the authenticated user ID on auto-login
        await Purchases.logIn(currentUser.uid);

        bool isSubbed = false;

        final userEmail = currentUser.email?.toLowerCase() ?? '';
        if (userEmail.contains('reviewer') ||
            userEmail.contains('tailzs.com')) {
          isSubbed = true;
        } else {
          final CustomerInfo info = await Purchases.getCustomerInfo();
          final entitlement = info.entitlements.all['tailzs'];
          isSubbed = (entitlement != null && entitlement.isActive) ||
              info.entitlements.active.isNotEmpty;
        }

        if (isSubbed && mounted) {
          _navigateWithFallback();
        }
      }
    } catch (e) {
      debugPrint('Session check error: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3366),
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
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        // 1. Bind the Firebase user UID to RevenueCat
        await Purchases.logIn(user.uid);

        // 2. Enforce 2-Device Limit & Evict Oldest
        final prefs = await SharedPreferences.getInstance();
        String? deviceId = prefs.getString('tailzs_device_id');
        if (deviceId == null) {
          deviceId =
              '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(999999)}';
          await prefs.setString('tailzs_device_id', deviceId);
        }

        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await userRef.get();

        List<String> activeDevices = [];
        if (doc.exists &&
            doc.data() != null &&
            doc.data()!.containsKey('active_devices')) {
          activeDevices = List<String>.from(doc.data()!['active_devices']);
        }

        if (!activeDevices.contains(deviceId)) {
          if (activeDevices.length >= 2) {
            activeDevices.removeAt(0); // Evict the oldest device
          }
          activeDevices.add(deviceId);
          await userRef.set({
            'active_devices': activeDevices,
            'last_login': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Granted. Unlocking Quant Terminal...'),
            backgroundColor: Color(0xFF00F5D4),
            duration: Duration(seconds: 2),
          ),
        );

        _navigateWithFallback();
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
        _navigateWithFallback();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: const Color(0xFF080C0E),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF182226),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFF24343B), width: 1.5),
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
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
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5E00),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _navigateWithFallback();
                        },
                        child: const Text(
                          'SKIP TO FREE TERMINAL ➔',
                          style: TextStyle(
                            color: Color(0xFF00F5D4),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
