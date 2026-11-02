class Product {
  final String id;
  final String nama;
  final String kategori;
  final int harga;
  final int stok;
  final List<String> kandunganAktif;
  final List<String> tipeKulitCocok;
  final int paoBulan;
  final DateTime? tanggalBuka;
  final String manfaat;
  final String caraPakai;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.stok,
    required this.kandunganAktif,
    required this.tipeKulitCocok,
    required this.paoBulan,
    this.tanggalBuka,
    required this.manfaat,
    required this.caraPakai,
    this.imageUrl,
  });

  bool get isStokHabis => stok == 0;
  bool get isStokMenipis => stok > 0 && stok <= 5;

  DateTime? get tanggalKadaluarsa {
    if (tanggalBuka == null) return null;
    return DateTime(
      tanggalBuka!.year,
      tanggalBuka!.month + paoBulan,
      tanggalBuka!.day,
    );
  }

  int get sisaHariPao {
    final exp = tanggalKadaluarsa;
    if (exp == null) return -1;
    return exp.difference(DateTime.now()).inDays;
  }

  bool get isPaoExpired {
    final sisa = sisaHariPao;
    return sisa >= 0 && sisa <= 30;
  }

  String get hargaFormatted => 'Rp ${harga.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'harga': harga,
      'stok': stok,
      'kandunganAktif': kandunganAktif,
      'tipeKulitCocok': tipeKulitCocok,
      'paoBulan': paoBulan,
      'tanggalBuka': tanggalBuka?.toIso8601String(),
      'manfaat': manfaat,
      'caraPakai': caraPakai,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      nama: map['nama'] as String,
      kategori: map['kategori'] as String,
      harga: map['harga'] as int,
      stok: map['stok'] as int,
      kandunganAktif: List<String>.from(map['kandunganAktif'] as List),
      tipeKulitCocok: List<String>.from(map['tipeKulitCocok'] as List),
      paoBulan: map['paoBulan'] as int,
      tanggalBuka: map['tanggalBuka'] != null
          ? DateTime.parse(map['tanggalBuka'] as String)
          : null,
      manfaat: map['manfaat'] as String,
      caraPakai: map['caraPakai'] as String,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Product copyWith({
    String? id,
    String? nama,
    String? kategori,
    int? harga,
    int? stok,
    List<String>? kandunganAktif,
    List<String>? tipeKulitCocok,
    int? paoBulan,
    DateTime? tanggalBuka,
    String? manfaat,
    String? caraPakai,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kategori: kategori ?? this.kategori,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      kandunganAktif: kandunganAktif ?? this.kandunganAktif,
      tipeKulitCocok: tipeKulitCocok ?? this.tipeKulitCocok,
      paoBulan: paoBulan ?? this.paoBulan,
      tanggalBuka: tanggalBuka ?? this.tanggalBuka,
      manfaat: manfaat ?? this.manfaat,
      caraPakai: caraPakai ?? this.caraPakai,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

const List<String> kategoriProduk = [
  'Cleanser',
  'Toner',
  'Serum',
  'Moisturizer',
  'Sunscreen',
  'Mask',
];

const List<String> tipeKulitList = [
  'Berminyak',
  'Kering',
  'Kombinasi',
  'Sensitif',
  'Normal',
];

const List<String> concernList = [
  'Jerawat',
  'Kulit Kusam',
  'Pori Besar',
  'Keriput',
  'Hiperpigmentasi',
  'Kulit Kasar',
];
