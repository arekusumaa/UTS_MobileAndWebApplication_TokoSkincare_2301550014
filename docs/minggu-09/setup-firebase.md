# Setup Firebase — SkinCare Store

Batas pertemuan Minggu 9: **target Chrome**, **hanya penyedia Email/Password**, **belum memakai Firestore**, **paket Spark tanpa billing account**.

## 1. Firebase Console

| Langkah | Yang dilakukan | Status |
|---|---|---|
| 1 | Masuk ke console.firebase.google.com dengan akun Google | ✅ |
| 2 | Buat project `toko-skincare-fec17`, paket tetap **Spark** | ✅ |
| 3 | Gemini in Firebase / Google Analytics tidak dipakai untuk autentikasi | ✅ |
| 4 | **Authentication → Get started → Sign-in method → aktifkan Email/Password** | ✅ |
| 5 | Project settings → daftarkan aplikasi Web (ikon `</>`), salin `firebaseConfig` | ✅ |

Project ID: `toko-skincare-fec17` · Auth domain: `toko-skincare-fec17.firebaseapp.com` · App ID: `1:310494488136:web:6da0010cec8bbfc0e79a7d`.

## 2. Memasang paket Flutter

Versi yang diuji modul, dipasang persis:

```bash
flutter pub add firebase_core:5.1.0 firebase_auth:7.0.1
```

Hasil di `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: 5.1.0
  firebase_auth: 7.0.1
```

`flutter pub get` berhasil; `pubspec.lock` ikut di-commit agar versi terkunci.

## 3. Menghubungkan project

Modul memberi dua jalur. Yang dipakai: **jalur cadangan / salin manual**, dengan bentuk file tetap mengikuti keluaran FlutterFire CLI (`DefaultFirebaseOptions.currentPlatform`). Alasannya praktis: hanya platform **web** yang menjadi target Minggu 9, sehingga tidak perlu menjalankan `firebase login` + `flutterfire configure` dan tidak perlu Node.js/firebase-tools.

`lib/firebase_options.dart` hanya mengembalikan `web` saat `kIsWeb`; platform lain melempar `UnsupportedError` dengan pesan "reconfigure this by running the FlutterFire CLI again". Ini disengaja, bukan bug: batas pertemuan ini memang Chrome saja.

Nilai yang disalin dari `firebaseConfig`:

| Field | Sumber |
|---|---|
| `apiKey` | `AIzaSyAHexumbwDleZqnW_ooK7rxbnGAMyFqNgc` |
| `appId` | `1:310494488136:web:6da0010cec8bbfc0e79a7d` |
| `messagingSenderId` | `310494488136` |
| `projectId` | `toko-skincare-fec17` |
| `authDomain` | `toko-skincare-fec17.firebaseapp.com` |
| `storageBucket` | `toko-skincare-fec17.firebasestorage.app` |
| `measurementId` | `G-CLJH0BRHHY` |

> Kalau nanti mau menambah Android/iOS, jalankan `dart pub global activate flutterfire_cli` lalu `flutterfire configure --platforms=web,android,ios` dan biarkan file ini ditimpa CLI.

## 4. Inisialisasi saat aplikasi dibuka

`lib/main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkinCareStoreApp());
}
```

Dua hal yang wajib dan sudah dipenuhi:

- `ensureInitialized()` **sebelum** `await` apa pun.
- `await Firebase.initializeApp(...)` **sebelum** `runApp`. Tanpa ini muncul `No Firebase App '[DEFAULT]' has been created`.

`SkinCareStoreApp` membungkus `MultiProvider` dan menjadikan `CekStatusLogin()` sebagai gerbang (padanan `home: CekStatusLogin()` pada modul).

## 5. Keamanan

- `firebase_options.dart` berisi **pengenal project, bukan password**. Aman dan memang disarankan untuk di-commit.
- `apiKey` Firebase untuk web memang didesain publik (nilainya ikut ter-bundle di frontend). GitHub mungkin tetap menampilkan peringatan "API key terdeteksi" — itu bukan kebocoran kredensial. Yang menjaga data adalah Authentication + Security Rules.
- **Password akun tidak pernah ditulis di kode, README, maupun dokumen.** Semua akun uji memakai password simulasi `123456`, bukan password asli.
- Yang benar-benar harus dirahasiakan: **service account private key** (file JSON Admin SDK). Tidak ada dan tidak boleh masuk repo.
- `storageBucket` dan `measurementId` ikut disalin agar konfigurasi lengkap, tetapi **Cloud Storage dan Analytics tidak dipakai** pada Minggu 9.

## 6. Masalah umum dan penanganan

| Gejala | Penyebab | Solusi (dan status di project ini) |
|---|---|---|
| `No Firebase App '[DEFAULT]' has been created` | `initializeApp` belum dipanggil/ditunggu | ✅ Sudah `await` sebelum `runApp` |
| `api-key-not-valid` | `apiKey` salah salin | ✅ Disalin ulang dari Project settings; probe Chrome berhasil |
| `operation-not-allowed` | Email/Password belum aktif | ✅ Penyedia sudah diaktifkan; kasus ini juga sudah diterjemahkan di `pesanKesalahanAuth` |
| `flutterfire` tidak dikenali | Pub cache belum di PATH | ✅ Tidak terpakai: memakai jalur cadangan |
| Selalu muncul pesan umum | Kode error belum diterjemahkan | ✅ 10 kode + `default` ada di `validasi_auth.dart`, diuji 13 unit test |
| Widget test gagal karena Firebase | Test membuka widget yang memanggil Firebase | ✅ Widget test hanya menguji fungsi murni; `CekStatusLogin` juga menerima `halamanAwal` untuk melewati Firebase |
| Halaman tidak berganti setelah masuk | `home` belum memakai gerbang | ✅ `CekStatusLogin` + `GoRouterRefreshStream` memicu redirect |
| ERROR 400 di console browser saat uji | Request memang ditolak Firebase (password salah / email duplikat) | ✅ Expected, bukan bug aplikasi — pesan sudah ditampilkan ke pengguna |

## 7. Verifikasi

```bash
flutter analyze          # 0 error, 0 warning (53 info gaya)
flutter test             # 13 lulus
flutter build web --release   # √ Built build\web
```

Probe Chrome (`video/scripts/probe-firebase.js`) memastikan Firebase terinisialisasi dan auth gate langsung mengarah ke `/login`. Uji 9 kasus ada di [tabel-uji-login.md](tabel-uji-login.md).
