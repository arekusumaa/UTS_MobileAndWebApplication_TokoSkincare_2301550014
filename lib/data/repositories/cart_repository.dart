import '../models/cart_item.dart';

/// Keranjang tersimpan di sub-collection `carts/{uid}/items/{productId}`.
///
/// UID diambil dari `FirebaseAuth.instance.currentUser` di dalam implementasi,
/// sehingga kontrak ini tetap sederhana dan tidak membocorkan identitas ke UI.
abstract class CartRepository {
  List<CartItem> getCart();

  /// Menimpa seluruh isi keranjang. Implementasi Firestore melakukan
  /// optimistic update pada cache lalu menulis ke Firestore secara async.
  void saveCart(List<CartItem> items);
}
