import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  // Ensures Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase for all platforms
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Start the app
  runApp(const NoMoreWasteApp());
}
