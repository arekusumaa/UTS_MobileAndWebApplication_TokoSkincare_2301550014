# Proposal UTS — SkinCare Store

**Mobile and Web Application Development — Kelas A1**
Semester Ganjil 2026/2027

---

## Identitas

| Item | Keterangan |
|------|-----------|
| Nama | Are Kusuma Pratiwi |
| NIM | 23.01.55.0014 |
| Kelas | A1 / A2DLC |
| Judul Aplikasi | SkinCare Store |
| Repository GitHub | _(diisi setelah push)_ |
| Tautan Figma | https://www.figma.com/design/qVTUEcTMfDeced9ggBp90d/-2301550014--%E2%80%93--SkinCareStore--%E2%80%93-Wireframe?node-id=0-1&t=fjQwAe677ezcqBnl-1 |
| Video Guideline Dosen | https://youtu.be/zX4AaqMxp5I |

---

## 1. Problem Statement

Banyak pengguna skincare, terutama pemula, kesulitan memilih produk yang sesuai dengan tipe kulit mereka. Masalah utama yang diselesaikan SkinCare Store:

1. **Kebingungan memilih produk**: Pengguna tidak tahu produk mana yang cocok untuk tipe kulit mereka (berminyak, kering, kombinasi, sensitif, normal). Banyak produk di pasaran dengan klaim yang membingungkan.

2. **Tidak ada personalisasi**: Toko skincare online umumnya hanya menampilkan katalog tanpa mempertimbangkan profil kulit pengguna. Pengguna harus riset sendiri untuk mencocokkan kandungan aktif dengan kebutuhan kulitnya.

3. **Tidak ada informasi PAO (Period After Opening)**: Pengguna sering menggunakan produk skincare yang sudah kedaluwarsa setelah dibuka karena tidak ada pengingat masa pakai. PAO penting karena produk aktif seperti Vitamin C dan Retinol kehilangan efektivitas setelah melewati masa pakai.

4. **Alergi dan iritasi**: Pengguna tidak memiliki cara sistematis untuk mencatat alergi terhadap bahan tertentu (misalnya fragrance, alcohol) dan memastikan produk yang dipilih tidak mengandung bahan tersebut.

**Mengapa penting**: Salah memilih skincare dapat menyebabkan iritasi, breakouts, dan pemborosan uang. Survei menunjukkan 70% pengguna skincare pemula membeli produk yang tidak sesuai dengan tipe kulitnya.

---

## 2. Persona

### Persona Utama: Rina, Mahasiswa Skincare Enthusiast

| Atribut | Detail |
|---------|--------|
| Nama | Rina Pratiwi |
| Usia | 21 tahun |
| Status | Mahasiswa S1 Semester 5 |
| Tipe Kulit | Berminyak, cenderung berjerawat |
| Concern | Jerawat, pori-pari besar, kulit kusam |
| Alergi | Fragrance |
| Budget | Rp 50.000 - Rp 100.000 per produk |
| Perangkat | Android (realme), laptop (Chrome) |
| Tujuan | Mencari produk skincare yang cocok untuk kulit berminyaknya tanpa memicu breakouts |
| Frustrasi | Bingung dengan banyaknya produk di e-commerce, tidak tahu kandungan apa yang aman untuk kulitnya |
| Tech literacy | Menengah - aktif menggunakan e-commerce dan media sosial |

### Persona Sekunder: Admin Toko

| Atribut | Detail |
|---------|--------|
| Nama | Admin Toko |
| Peran | Mengelola katalog produk dan pesanan |
| Tujuan | Menambah/mengedit produk, memantau stok, mengubah status pesanan |
| Perangkat | Laptop (Chrome) |

---

## 3. User Stories (Minimal 5)

| # | Sebagai | Saya ingin | Sehingga | Prioritas |
|---|---------|-----------|----------|-----------|
| US-01 | Pelanggan | mengisi profil kulit (tipe, concern, alergi) | sistem dapat merekomendasikan produk yang sesuai | Must |
| US-02 | Pelanggan | melihat daftar produk dengan filter kategori dan tipe kulit | saya bisa menemukan produk yang cocok dengan cepat | Must |
| US-03 | Pelanggan | melihat detail produk (kandungan aktif, manfaat, PAO, cara pakai) | saya bisa memutuskan apakah produk aman dan tepat untuk saya | Must |
| US-04 | Pelanggan | menambahkan produk ke keranjang dan checkout | saya bisa membeli produk yang dipilih | Must |
| US-05 | Pelanggan | melihat status dan riwayat pesanan | saya bisa memantau pengiriman pesanan saya | Must |
| US-06 | Pelanggan | mendaftar akun baru | saya bisa mulai berbelanja tanpa akun dari admin | Should |
| US-07 | Admin | menambah, mengedit, dan menghapus produk | katalog selalu up-to-date | Must |
| US-08 | Admin | mengubah status pesanan (menunggu -> diproses -> dikirim -> selesai) | pelanggan dapat memantau progres pesanan | Must |

---

## 4. Kebutuhan Fungsional dan Prioritas (MoSCoW)

### Must Have (Inti - diimplementasi sebelum UTS)

| Kode | Fitur | Status |
|------|-------|--------|
| F-01 | Login dengan email & password (validasi form) | Selesai |
| F-02 | Register akun baru (validasi form, konfirmasi password) | Selesai |
| F-03 | Beranda dengan rekomendasi produk berdasarkan profil kulit | Selesai |
| F-04 | Profil kulit: pilih tipe kulit, concern, alergi | Selesai |
| F-05 | Daftar produk dengan filter kategori | Selesai |
| F-06 | Detail produk (kandungan, manfaat, PAO, cara pakai, stok) | Selesai |
| F-07 | Keranjang belanja (tambah, hapus, ubah jumlah) | Selesai |
| F-08 | Checkout dengan form alamat pengiriman + metode pembayaran simulasi | Selesai |
| F-09 | Status pesanan dengan tracker (menunggu -> selesai) | Selesai |
| F-10 | Riwayat pesanan | Selesai |
| F-11 | Dashboard admin (kelola produk & pesanan) | Selesai |

### Should Have (Peluengkap)

| Kode | Fitur | Status |
|------|-------|--------|
| F-12 | Akun page (profil, logout) | Selesai |
| F-13 | Form tambah/edit produk admin (validasi) | Selesai |
| F-14 | Kelola pesanan admin (ubah status) | Selesai |

### Could Have (Masa depan)

| Kode | Fitur |
|------|-------|
| F-15 | Search produk berdasarkan nama/kandungan |
| F-16 | Upload foto produk |
| F-17 | Notifikasi perubahan status pesanan |
| F-18 | Rating dan review produk |

### Won't Have (Untuk UTS)

| Kode | Fitur | Alasan |
|------|-------|--------|
| F-19 | Pembayaran nyata (payment gateway) | Di luar scope, simulasi saja |
| F-20 | Cloud Functions | Firebase Spark plan, tidak tersedia |

---

## 5. User Flow

```
Login --> Beranda --> [Profil Kulit] --> Daftar Produk --> Detail Produk
  |         |              |                  |                |
  |         |              |                  |                v
  |         |              |                  |          [Tambah ke Keranjang]
  |         |              |                  |                |
  |         v              v                  v                v
  Register  Akun      Profil Kulit      Keranjang <-------+
                                        |
                                        v
                                    Checkout (form alamat + pembayaran)
                                        |
                                        v
                                    Status Pesanan
                                        |
                                        v
                                    Riwayat Pesanan
```

**Alur inti**: Login -> Beranda -> Profil Kulit -> Daftar Produk -> Detail Produk -> Keranjang -> Checkout -> Status Pesanan

---

## 6. Sitemap / Daftar Halaman

### Halaman Pelanggan (Customer)

| # | Halaman | Route | Navigasi |
|---|---------|-------|----------|
| 1 | Login | /login | Entry point |
| 2 | Register | /register | Push dari Login |
| 3 | Beranda | /beranda | NavigationBar (tab 1) |
| 4 | Daftar Produk | /produk | NavigationBar (tab 2) |
| 5 | Detail Produk | /produk/:id | Push dari Daftar Produk |
| 6 | Keranjang | /keranjang | NavigationBar (tab 3) |
| 7 | Checkout | /checkout | Push dari Keranjang |
| 8 | Status Pesanan | /status-pesanan | Push dari Checkout |
| 9 | Riwayat Pesanan | /riwayat | Push dari Akun |
| 10 | Profil Kulit | /profil-kulit | Push dari Beranda/Akun |
| 11 | Akun | /akun | NavigationBar (tab 4) |

### Halaman Admin

| # | Halaman | Route | Navigasi |
|---|---------|-------|----------|
| 12 | Dashboard Admin | /admin | Push dari Akun |
| 13 | Kelola Produk | /admin/produk | Push dari Dashboard |
| 14 | Form Produk | /admin/produk/form | Push dari Kelola Produk |
| 15 | Kelola Pesanan | /admin/pesanan | Push dari Dashboard |

### Navigasi

- **Mobile (<600px)**: Bottom NavigationBar dengan 4 tab (Beranda, Produk, Keranjang, Akun)
- **Web (>=600px)**: NavigationRail sidebar di sisi kiri (responsive)

---

## 7. Wireframe / Figma

**Tautan Figma**: https://www.figma.com/design/qVTUEcTMfDeced9ggBp90d/

**Frame yang dibuat (Minggu 4)**:
1. Login
2. Beranda
3. Daftar Produk
4. Keranjang & Checkout
5. Status Pesanan

**Style Guide**:
- Warna primer: #D95778 (pink)
- Ukuran teks: judul 24px, subjudul 18px, isi 16px, caption 12px
- Tombol: height 48px, border radius 12px
- Margin: 16px, spacing: kelipatan 8px

---

## 8. Tech Stack

| Komponen | Teknologi | Status |
|----------|-----------|--------|
| Framework | Flutter 3.27+ / Dart | Aktif |
| State Management | Provider 6.1.2 | Aktif |
| Routing | GoRouter 14.6 | Aktif |
| Database (saat ini) | Mock data (List di memori) | Aktif |
| Database (rencana) | Cloud Firestore (Firebase Spark) | Rencana Fase 5 |
| Authentication | Firebase Auth | Rencana Fase 5 |
| Hosting | Firebase Hosting | Rencana Fase 5 |
| Version Control | Git + GitHub | Aktif |
| Design | Figma | Selesai |

**Arsitektur**: Repository Pattern
```
UI (Screens) --> Provider (State) --> Repository (Abstract) --> DataSource
                                                                |
                                                    MockDataSource (now)
                                                    FirestoreDataSource (future)
```

---

## 9. Rancangan Database Firestore

### Collection: users

```json
{
  "uid": "string (Firebase Auth UID)",
  "nama": "string",
  "email": "string",
  "role": "string (admin | pelanggan)",
  "createdAt": "timestamp"
}
```

### Collection: products

```json
{
  "id": "string (auto-generated)",
  "nama": "string",
  "kategori": "string (Cleanser | Toner | Serum | Moisturizer | Sunscreen | Mask)",
  "harga": "number",
  "stok": "number",
  "kandunganAktif": "array<string>",
  "tipeKulitCocok": "array<string>",
  "paoBulan": "number (6 | 12)",
  "tanggalBuka": "timestamp | null",
  "manfaat": "string",
  "caraPakai": "string",
  "imageUrl": "string | null",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Collection: skin_profiles

```json
{
  "userId": "string (ref: users.uid)",
  "tipeKulit": "string (Berminyak | Kering | Kombinasi | Sensitif | Normal)",
  "concern": "array<string> (Jerawat | Kulit Kusam | Pori Besar | ...)",
  "alergi": "array<string>",
  "updatedAt": "timestamp"
}
```

### Collection: orders

```json
{
  "id": "string (auto-generated)",
  "userId": "string (ref: users.uid)",
  "items": [
    {
      "productId": "string (ref: products.id)",
      "nama": "string",
      "harga": "number",
      "quantity": "number",
      "subtotal": "number"
    }
  ],
  "total": "number",
  "status": "string (menunggu | diproses | dikirim | selesai)",
  "alamat": "string",
  "namaPenerima": "string",
  "telepon": "string",
  "tanggal": "timestamp",
  "createdAt": "timestamp"
}
```

### Collection: carts

```json
{
  "userId": "string (ref: users.uid)",
  "items": [
    {
      "productId": "string (ref: products.id)",
      "quantity": "number"
    }
  ],
  "updatedAt": "timestamp"
}
```

### Relasi Antar Collection

```
users (1) ---- (1) skin_profiles   [uid = userId]
users (1) ---- (N) orders           [uid = userId]
users (1) ---- (1) carts            [uid = userId]
orders (N) ---- (N) products        [via items[].productId]
```

### Catatan Keamanan (Firestore Rules)

- `users`: read/write own document only (uid == auth.uid)
- `products`: read all (public catalog), write admin only
- `skin_profiles`: read/write own document only
- `orders`: read own orders, write own orders (create), admin can update status
- `carts`: read/write own cart only

---

## 10. Form Validation Test Table (Modul Minggu 7)

### Form: Checkout (Alamat Pengiriman)

| # | Kasus Uji | Input | Hasil yang Diharapkan | Hasil Nyata |
|---|-----------|-------|----------------------|-------------|
| 1 | Semua kosong | Nama: kosong, Telepon: kosong, Alamat: kosong | Semua kolom menampilkan pesan wajib diisi | Sesuai harapan |
| 2 | Telepon bukan angka | Telepon: "abc" | "Nomor telepon harus berupa angka" | Sesuai harapan |
| 3 | Telepon terlalu pendek | Telepon: "123" | "Nomor telepon minimal 10 digit" | Sesuai harapan |
| 4 | Alamat kurang dari 10 karakter | Alamat: "Jl. A" | "Alamat minimal 10 karakter" | Sesuai harapan |
| 5 | Semua valid | Nama: "Rina", Telepon: "081234567890", Alamat: "Jl. Merdeka No. 45, Bandung" | Pesan berhasil: "Pesanan berhasil dibuat!", data tampil di Status Pesanan | Sesuai harapan |

### Form: Login

| # | Kasus Uji | Input | Hasil yang Diharapkan |
|---|-----------|-------|----------------------|
| 1 | Email kosong | Email: kosong | "Email wajib diisi" |
| 2 | Email format salah | Email: "rina@" | "Format email tidak valid" |
| 3 | Password kurang dari 6 | Password: "123" | "Kata sandi minimal 6 karakter" |
| 4 | Login berhasil | admin@skincare.id / 123456 | Navigasi ke Dashboard Admin |
| 5 | Login gagal | salah@mail.com / 123456 | "Email atau kata sandi salah" |

---

## 11. Refleksi

### Bagian wireframe yang paling sulit dibangun
Detail Produk karena harus menampilkan banyak informasi (kandungan aktif, manfaat, cara pakai, PAO, stok indicator) dalam satu layar tanpa membuatnya terasa berantakan. Solusi: menggunakan Section widget untuk memisahkan informasi secara visual.

### Perbedaan dengan prototipe Figma
- Bottom navigation: Figma hanya 3 tab, aplikasi menjadi 4 tab (tambah Akun)
- Layout web: Figma belum punya layout sidebar, aplikasi sudah implementasi NavigationRail responsive

### Halaman form yang dilengkapi
Checkout (alamat pengiriman + metode pembayaran), Login, Register, Profil Kulit, dan Form Produk Admin. Semua sudah memiliki validasi dan pesan status.

### Kendala
- GoRouter + Navigator.pushNamed tidak kompatibel (silent failure) - fixed dengan context.go()
- Material 3 menghapus selectedItemColor - fixed dengan WidgetStateProperty
- Flutter web canvas tidak menerima execCommand untuk input - fixed dengan keyboard simulation

### Rencana setelah UTS
- Fase 5: Firebase (Auth + Firestore) menggantikan mock data
- Search produk berdasarkan nama/kandungan
- Upload foto produk (Firebase Storage)

---

## 12. Jawaban Pertanyaan Penguji

**1. Masalah apa yang diselesaikan aplikasi Anda?**
Pengguna skincare kesulitan memilih produk yang sesuai dengan tipe kulit mereka. SkinCare Store menyelesaikan ini dengan profil kulit yang dipersonalisasi, rekomendasi produk berdasarkan tipe kulit, dan informasi PAO untuk keamanan penggunaan produk.

**2. Siapa pengguna utamanya?**
Mahasiswa dan young adult (18-25 tahun) yang baru memulai rutinitas skincare dan bingung memilih produk. Persona utama: Rina, 21 tahun, kulit berminyak dengan concern jerawat.

**3. Mengapa fitur ini yang diprioritaskan?**
Profil kulit dan rekomendasi produk adalah fitur Must karena tanpa personalisasi, aplikasi hanyalah katalog biasa. PAO tracker juga Must karena masalah kesadaran masa pakai produk adalah unik value proposition yang membedakan dari e-commerce biasa.

**4. Bagaimana data akan disimpan?**
Saat ini menggunakan mock data (List di memori). Rencana: Firebase Auth untuk autentikasi, Cloud Firestore untuk database dengan 5 collection (users, products, skin_profiles, orders, carts). Firestore dipilih karena real-time sync, offline support, dan terintegrasi dengan ekosistem Firebase. Data akan hilang saat restart sampai Firebase diimplementasi di Fase 5.
