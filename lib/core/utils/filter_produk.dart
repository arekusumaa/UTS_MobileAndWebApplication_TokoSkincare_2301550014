import '../../data/models/product.dart';

/// Filter daftar produk secara murni (tanpa state, tanpa Firebase).
///
/// Dipakai halaman yang sumber datanya langsung dari `StreamBuilder` hasil
/// `.snapshots()` (Beranda dan Daftar Produk). Pencarian, kategori, dan tipe
/// kulit tetap disimpan di `ProductProvider`, tetapi penerapannya dilakukan
/// di sisi Dart agar query Firestore cukup satu `collection().snapshots()`
/// tanpa composite index.
List<Product> terapkanFilterProduk(
  List<Product> sumber, {
  String cari = '',
  String kategori = 'Semua',
  String tipeKulit = 'Semua',
}) {
  var hasil = List<Product>.from(sumber);

  if (cari.isNotEmpty) {
    final q = cari.toLowerCase();
    hasil = hasil
        .where((p) =>
            p.nama.toLowerCase().contains(q) ||
            p.kategori.toLowerCase().contains(q) ||
            p.kandunganAktif.any((k) => k.toLowerCase().contains(q)))
        .toList();
  }

  if (kategori != 'Semua' && kategori.isNotEmpty) {
    hasil = hasil.where((p) => p.kategori == kategori).toList();
  }

  if (tipeKulit != 'Semua' && tipeKulit.isNotEmpty) {
    hasil = hasil.where((p) => p.tipeKulitCocok.contains(tipeKulit)).toList();
  }

  return hasil;
}

/// Rekomendasi produk berdasarkan tipe kulit, dihitung dari data stream.
/// Bila profil kulit belum diisi, kembalikan beberapa produk teratas.
List<Product> rekomendasiDariStream(List<Product> sumber, String tipeKulit,
    {int maksimal = 4}) {
  if (tipeKulit.isEmpty || tipeKulit == 'Semua') {
    return sumber.take(maksimal).toList();
  }
  final cocok = sumber
      .where((p) => p.tipeKulitCocok.contains(tipeKulit))
      .take(maksimal)
      .toList();
  if (cocok.isNotEmpty) return cocok;
  return sumber.take(maksimal).toList();
}
