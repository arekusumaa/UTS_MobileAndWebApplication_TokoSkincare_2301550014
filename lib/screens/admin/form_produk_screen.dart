import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/product_provider.dart';
import '../../data/models/product.dart';

class FormProdukScreen extends StatefulWidget {
  final Product? product;

  const FormProdukScreen({super.key, this.product});

  @override
  State<FormProdukScreen> createState() => _FormProdukScreenState();
}

class _FormProdukScreenState extends State<FormProdukScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _manfaatController = TextEditingController();
  final _caraPakaiController = TextEditingController();
  String _kategori = 'Cleanser';
  final Set<String> _kandunganAktif = {};
  final Set<String> _tipeKulitCocok = {};
  int _paoBulan = 12;

  final _kandunganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _namaController.text = p.nama;
      _hargaController.text = p.harga.toString();
      _stokController.text = p.stok.toString();
      _manfaatController.text = p.manfaat;
      _caraPakaiController.text = p.caraPakai;
      _kategori = p.kategori;
      _kandunganAktif.addAll(p.kandunganAktif);
      _tipeKulitCocok.addAll(p.tipeKulitCocok);
      _paoBulan = p.paoBulan;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _manfaatController.dispose();
    _caraPakaiController.dispose();
    _kandunganController.dispose();
    super.dispose();
  }

  void _addKandungan() {
    final val = _kandunganController.text.trim();
    if (val.isNotEmpty && !_kandunganAktif.contains(val)) {
      setState(() {
        _kandunganAktif.add(val);
        _kandunganController.clear();
      });
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<ProductProvider>();
      final id = widget.product?.id ??
          'P${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
      final product = Product(
        id: id,
        nama: _namaController.text.trim(),
        kategori: _kategori,
        harga: int.parse(_hargaController.text),
        stok: int.parse(_stokController.text),
        kandunganAktif: _kandunganAktif.toList(),
        tipeKulitCocok: _tipeKulitCocok.toList(),
        paoBulan: _paoBulan,
        tanggalBuka: widget.product?.tanggalBuka,
        manfaat: _manfaatController.text.trim(),
        caraPakai: _caraPakaiController.text.trim(),
        imageUrl: null,
      );

      if (widget.product != null) {
        provider.updateProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil diperbarui')),
        );
      } else {
        provider.addProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil ditambahkan')),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Produk' : 'Tambah Produk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (v) => Validators.required(v, fieldName: 'Nama Produk'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _kategori,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: kategoriProduk.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) => setState(() => _kategori = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                      validator: (v) => Validators.numeric(v, fieldName: 'Harga'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stokController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      validator: (v) => Validators.numeric(v, fieldName: 'Stok'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kandungan aktif
              Text('Kandungan Aktif', style: AppTextStyles.subjudul),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kandunganController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Niacinamide',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addKandungan(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addKandungan,
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _kandunganAktif.map((k) {
                  return Chip(
                    label: Text(k, style: const TextStyle(fontSize: 13)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _kandunganAktif.remove(k)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Tipe kulit cocok
              Text('Tipe Kulit yang Cocok', style: AppTextStyles.subjudul),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tipeKulitList.map((tk) {
                  final selected = _tipeKulitCocok.contains(tk);
                  return FilterChip(
                    label: Text(tk),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _tipeKulitCocok.add(tk);
                        } else {
                          _tipeKulitCocok.remove(tk);
                        }
                      });
                    },
                    selectedColor: AppColors.primaryLight,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // PAO
              DropdownButtonFormField<int>(
                value: _paoBulan,
                decoration: const InputDecoration(labelText: 'PAO (Masa Pakai Setelah Dibuka)'),
                items: const [
                  DropdownMenuItem(value: 6, child: Text('6 Bulan')),
                  DropdownMenuItem(value: 12, child: Text('12 Bulan')),
                ],
                onChanged: (v) => setState(() => _paoBulan = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _manfaatController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Manfaat'),
                validator: (v) => Validators.required(v, fieldName: 'Manfaat'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caraPakaiController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Cara Pakai'),
                validator: (v) => Validators.required(v, fieldName: 'Cara Pakai'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.product != null ? 'Simpan Perubahan' : 'Tambah Produk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
