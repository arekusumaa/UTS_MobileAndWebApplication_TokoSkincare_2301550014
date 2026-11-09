import 'package:flutter/foundation.dart';

/// Jembatan antara snapshot realtime Firestore dan `ChangeNotifier` Provider.
///
/// `FirestoreDataSource` tidak mewarisi `ChangeNotifier` supaya lapisan data
/// tetap bisa dipakai tanpa Flutter (misalnya dari skrip Dart murni).
/// Sebaliknya ia menerima callback `onChanged` yang diteruskan ke sini.
/// Setiap Provider mendaftarkan diri lewat `addListener` dan menyegarkan
/// cache-nya ketika ada dokumen yang berubah — UI tidak perlu dirombak.
class DataSync extends ChangeNotifier {
  void berubah() => notifyListeners();
}
