import '../models/cart_item.dart';
import '../repositories/cart_repository.dart';

/// Keranjang in-memory untuk widget test / mode offline.
class MockCartSource implements CartRepository {
  List<CartItem> _items = [];

  @override
  List<CartItem> getCart() => List.unmodifiable(_items);

  @override
  void saveCart(List<CartItem> items) {
    _items = List.from(items);
  }
}
