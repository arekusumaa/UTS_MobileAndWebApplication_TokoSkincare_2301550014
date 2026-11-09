import 'dart:async';

import 'package:flutter/foundation.dart';

/// Menjembatani stream status login Firebase ke `refreshListenable` GoRouter.
///
/// Tanpa ini, GoRouter hanya mengevaluasi `redirect` saat ada navigasi.
/// Padahal Firebase memulihkan sesi secara asynchronous setelah browser
/// di-refresh, sehingga redirect perlu dipicu ulang ketika status berubah.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (_) => notifyListeners(),
      onError: (Object? _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
