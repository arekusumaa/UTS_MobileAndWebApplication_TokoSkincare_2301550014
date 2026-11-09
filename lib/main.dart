import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/skin_profile_provider.dart';
import 'screens/auth/cek_status_login.dart';

Future<void> main() async {
  // ensureInitialized wajib dipanggil sebelum await apa pun.
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase harus siap sebelum runApp, kalau tidak muncul
  // "No Firebase App '[DEFAULT]' has been created".
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkinCareStoreApp());
}

class SkinCareStoreApp extends StatelessWidget {
  const SkinCareStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SkinProfileProvider()),
      ],
      // Gerbang StreamBuilder menggantikan `home:` pada modul.
      child: const CekStatusLogin(),
    );
  }
}
