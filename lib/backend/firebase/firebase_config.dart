import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDLTCCCBq3dImPvL45z45NY1aBKI7nVRNg",
            authDomain: "tailzs-production.firebaseapp.com",
            projectId: "tailzs-production",
            storageBucket: "tailzs-production.firebasestorage.app",
            messagingSenderId: "56267457175",
            appId: "1:56267457175:web:04eeca480694a0af7ddfd2",
            measurementId: "G-K925FX06TJ"));
  } else {
    await Firebase.initializeApp();
  }
}
