import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_repositories.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/skin_profile_provider.dart';
import 'screens/auth/cek_status_login.dart';

/// Mode data simulasi tetap tersedia untuk keperluan UTS / screenshot:
/// `flutter run -d chrome --dart-define=PAKAI_MOCK=true`
/// Default (false) memakai Cloud Firestore yang sebenarnya.
const bool pakaiMock = bool.fromEnvironment('PAKAI_MOCK');

Future<void> main() async {
  // ensureInitialized wajib dipanggil sebelum await apa pun.
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase harus siap sebelum runApp, kalau tidak muncul
  // "No Firebase App '[DEFAULT]' has been created".
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final repos = pakaiMock
      ? AppRepositories.mock()
      : AppRepositories.firestore();
  // Tidak di-await dengan sengaja: listener dipasang segera, tetapi aplikasi
  // jangan sampai macet bila jaringan / Firestore sedang bermasalah.
  repos.initialize();

  runApp(SkinCareStoreApp(repos: repos));
}

class SkinCareStoreApp extends StatelessWidget {
  const SkinCareStoreApp({super.key, required this.repos});

  final AppRepositories repos;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            userRepository: repos.users,
            sync: repos.sync,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(
            source: repos.products,
            sync: repos.sync,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(
            source: repos.carts,
            sync: repos.sync,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(
            source: repos.orders,
            sync: repos.sync,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SkinProfileProvider(
            source: repos.skinProfiles,
            sync: repos.sync,
          ),
        ),
      ],
      // Gerbang StreamBuilder menggantikan `home:` pada modul.
      child: const CekStatusLogin(),
    );
  }
}
