import 'package:flutter/material.dart';
import '../data/models/product.dart';
import '../data/data_sources/mock_product_source.dart';
import '../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  /// [source] dan [sync] opsional supaya widget test lama tetap bisa memakai
  /// `ProductProvider()` tanpa Firebase. Di `main.dart` keduanya diisi dari
  /// `AppRepositories.firestore()`.
  ProductProvider({ProductRepository? source, Listenable? sync})
      : _productSource = source ?? MockProductSource(),
        _sync = sync {
    _allProducts = _productSource.getAllProducts();
    _filteredProducts = List.from(_allProducts);
    _sync?.addListener(_onDataBerubah);
  }

  final ProductRepository _productSource;
  final Listenable? _sync;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedKategori = 'Semua';
  String _selectedTipeKulit = 'Semua';

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _allProducts;
  String get searchQuery => _searchQuery;
  String get selectedKategori => _selectedKategori;
  String get selectedTipeKulit => _selectedTipeKulit;

  /// Dipanggil setiap ada snapshot Firestore baru (dari perangkat mana pun).
  void _onDataBerubah() {
    _allProducts = _productSource.getAllProducts();
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setKategori(String kategori) {
    _selectedKategori = kategori;
    _applyFilters();
  }

  void setTipeKulit(String tipeKulit) {
    _selectedTipeKulit = tipeKulit;
    _applyFilters();
  }

  void _applyFilters() {
    var result = List<Product>.from(_allProducts);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.nama.toLowerCase().contains(q) ||
            p.kategori.toLowerCase().contains(q) ||
            p.kandunganAktif.any((k) => k.toLowerCase().contains(q));
      }).toList();
    }

    if (_selectedKategori != 'Semua' && _selectedKategori.isNotEmpty) {
      result = result.where((p) => p.kategori == _selectedKategori).toList();
    }

    if (_selectedTipeKulit != 'Semua' && _selectedTipeKulit.isNotEmpty) {
      result = result.where((p) => p.tipeKulitCocok.contains(_selectedTipeKulit)).toList();
    }

    _filteredProducts = result;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedKategori = 'Semua';
    _selectedTipeKulit = 'Semua';
    _filteredProducts = List.from(_allProducts);
    notifyListeners();
  }

  Product? getProductById(String id) {
    return _productSource.getProductById(id);
  }

  List<Product> getRekomendasi(String tipeKulit) {
    return _productSource.getRekomendasi(tipeKulit);
  }

  List<Product> getStokMenipis() {
    return _productSource.getStokMenipis();
  }

  // Admin operations
  void addProduct(Product product) {
    _productSource.addProduct(product);
    _onDataBerubah();
  }

  void updateProduct(Product product) {
    _productSource.updateProduct(product);
    _onDataBerubah();
  }

  void deleteProduct(String id) {
    _productSource.deleteProduct(id);
    _onDataBerubah();
  }

  void reduceStok(String id, int amount) {
    _productSource.reduceStok(id, amount);
    _onDataBerubah();
  }

  @override
  void dispose() {
    _sync?.removeListener(_onDataBerubah);
    super.dispose();
  }
}
