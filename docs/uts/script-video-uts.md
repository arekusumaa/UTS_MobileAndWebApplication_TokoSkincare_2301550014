# Script Video Presentasi UTS — SkinCare Store

**Durasi maksimal: 10 menit**
**Format: Presentasi prototype + demo aplikasi berjalan**

---

## Bagian 1: Pembuka (0:00 - 0:30) | ~30 detik

> "Halo, perkenalkan nama saya Are Kusuma Pratiwi, NIM 23.01.55.0014, kelas A1, mata kuliah Mobile and Web Application Development. Aplikasi yang saya buat bernama SkinCare Store — toko skincare online dengan rekomendasi produk berdasarkan profil kulit dan pengingat PAO (Period After Opening)."

**On-screen**: Tampilkan slide/judul dengan identitas.

---

## Bagian 2: Masalah & Pengguna (0:30 - 2:00) | ~90 detik

> "Masalah yang diselesaikan: banyak pengguna skincare pemula kesulitan memilih produk yang cocok untuk tipe kulit mereka. Mereka tidak tahu kandungan apa yang aman, tidak ada personalisasi, dan tidak ada informasi masa pakai produk setelah dibuka (PAO).

> Pengguna utama saya adalah Rina, mahasiswa 21 tahun dengan kulit berminyak dan concern jerawat. Dia punya alergi fragrance dan budget Rp 50-100 ribu per produk. Dia aktif belanja online tapi bingung dengan banyaknya pilihan skincare.

> Persona sekunder adalah admin toko yang mengelola katalog produk dan pesanan."

**On-screen**: Tampilkan persona slide atau Figma wireframe persona.

---

## Bagian 3: Kebutuhan & Prioritas (2:00 - 3:00) | ~60 detik

> "Saya membuat 8 user story. Lima fitur Must yang diprioritaskan:
> 1. Profil kulit dengan tipe, concern, dan alergi
> 2. Daftar produk dengan filter kategori
> 3. Detail produk lengkap dengan PAO
> 4. Keranjang dan checkout
> 5. Status dan riwayat pesanan
>
> Prioritas ini dipilih karena tanpa profil kulit dan rekomendasi, aplikasi hanyalah katalog biasa. PAO tracker adalah fitur unik yang membedakan dari e-commerce lainnya."

**On-screen**: Tampilkan tabel user story / MoSCoW.

---

## Bagian 4: Rancangan (3:00 - 5:00) | ~120 detik

> "User flow: Login -> Beranda -> Profil Kulit -> Daftar Produk -> Detail Produk -> Keranjang -> Checkout -> Status Pesanan.
>
> Sitemap: 11 halaman pelanggan + 4 halaman admin = 15 halaman total.
>
> Wireframe Figma dibuat di Minggu 4 dengan 5 frame Must. Style guide: warna primer pink #D95778, ukuran teks 24/18/16/12px, tombol height 48px radius 12px.
>
> Sekarang saya tunjukkan kesesuaian wireframe dengan aplikasi yang dibangun."

**On-screen**: Tampilkan Figma wireframe berdampingan dengan aplikasi.

---

## Bagian 5: Demo Prototype (5:00 - 8:30) | ~210 detik

### Demo Navigasi (3 halaman terhubung)

> "Aplikasi berjalan di Chrome. Saya login dengan akun demo: admin@skincare.id / 123456."

1. **Login screen** → masuk email & password → klik Masuk
2. **Beranda** → tampil rekomendasi produk, banner profil kulit
3. **Bottom nav** → pindah ke Produk → pindah ke Keranjang → pindah ke Akun
4. **Push/pop** → klik produk → Detail Produk → tombol kembali

> "Tiga halaman Must terhubung dengan NavigationBar dan push/pop bekerja."

### Demo Form + Validasi

> "Saya tunjukkan form Checkout dengan validasi."

5. Tambah produk ke keranjang → buka Keranjang → Checkout
6. **Klik Buat Pesanan tanpa isi** → semua kolom menampilkan pesan error
7. **Isi telepon dengan huruf** → "Nomor telepon harus berupa angka"
8. **Isi alamat pendek** → "Alamat minimal 10 karakter"
9. **Isi semua dengan benar** → SnackBar: "Pesanan berhasil dibuat!" → Status Pesanan tampil

> "Form memiliki 3 kolom dari 2 jenis input: text (nama, alamat) dan numeric (telepon). Semua tervalidasi dengan pesan yang jelas. Data valid tampil di halaman Status Pesanan."

### Demo Keadaan Kosong

10. Hapus semua item keranjang → tampil empty state "Keranjang masih kosong"

> "Keadaan kosong sudah ditangani."

---

## Bagian 6: Rencana Teknis & Penutup (8:30 - 10:00) | ~90 detik

> "Tech stack: Flutter/Dart untuk frontend, Provider untuk state management, GoRouter untuk routing. Saat ini menggunakan mock data di memori.

> Rencana database Firestore dengan 5 collection:
> - users: data pengguna dan role
> - products: katalog produk lengkap
> - skin_profiles: profil kulit per pengguna
> - orders: pesanan dengan item dan status
> - carts: keranjang per pengguna

> Rencana Pertemuan 9-15: implementasi Firebase Auth + Firestore, search produk, upload foto produk, dan hosting.

> Kendala: GoRouter navigation issue (fixed), Material 3 breaking changes (fixed), Flutter web canvas input (fixed).

> Empat pertanyaan penguji:
> 1. Masalah: kesulitan memilih skincare yang sesuai tipe kulit
> 2. Pengguna: mahasiswa/young adult skincare pemula
> 3. Prioritas: profil kulit + rekomendasi karena tanpa itu aplikasi hanya katalog biasa
> 4. Data: saat ini mock data, rencana Firestore dengan 5 collection

> Sekian presentasi dari saya. Terima kasih."

---

## Checklist Sebelum Rekaman

- [ ] flutter run -d chrome berhasil
- [ ] Semua form validasi bekerja (test 5 kasus)
- [ ] SnackBar muncul untuk berhasil dan gagal
- [ ] Data tampil di halaman daftar setelah form
- [ ] Keadaan kosong tampil
- [ ] NavigationBar dan push/pop bekerja
- [ ] Suara narasi jelas
- [ ] Layar terbaca (perbesar saat demo kode/aplikasi)
- [ ] Sebutkan nama, NIM, kelas, judul di awal
- [ ] Durasi tidak lebih dari 10 menit
- [ ] Tautan video dapat diakses dosen (tidak privat)
