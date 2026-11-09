# Setup Cloud Firestore — Langkah demi Langkah

Dokumen ini mencatat **apa yang benar-benar dilakukan** pada project
`toko-skincare-fec17`, termasuk kendala yang muncul dan cara mengatasinya.
Bisa dipakai ulang bila project Firebase dibuat ulang.

---

## 1. Dependensi

```bash
flutter pub add cloud_firestore
```

Hasil resolusi (tercatat di `pubspec.lock`):

| Paket | Versi |
| --- | --- |
| `firebase_core` | 5.1.0 |
| `firebase_auth` | 7.0.1 |
| `cloud_firestore` | 7.1.0 |
| `cloud_firestore_platform_interface` | 8.1.0 |
| `cloud_firestore_web` | 5.8.0 |

`firebase_core` dan `firebase_auth` sudah dipasang pada Minggu 9, jadi tinggal
menambah `cloud_firestore`.

---

## 2. FlutterFire CLI

CLI tidak tersedia langsung sebagai `flutterfire` di PATH, sehingga dipanggil
lewat `dart pub global run`:

```bash
dart pub global activate flutterfire_cli          # 1.4.1 -> 1.5.0
dart pub global run flutterfire_cli:flutterfire configure \
  --project=toko-skincare-fec17 \
  --account=arekusuma0@gmail.com \
  --platforms=web \
  --out=lib/firebase_options.dart \
  --yes
```

Output:

```
Firebase configuration file lib/firebase_options.dart generated successfully
web 1:310494488136:web:6da0010cec8bbfc0e79a7d
```

`git diff -- lib/firebase_options.dart` **kosong** — konfigurasi hasil CLI
identik dengan berkas manual yang dibuat Minggu 9 dari `firebaseConfig` JavaScript.
Ini membuktikan konfigurasi sebelumnya sudah benar. Hanya platform `web` yang
didaftarkan (target modul = Chrome).

`firebase.json` kemudian ditambahi referensi rules/index:

```json
"firestore": {
  "rules": "firestore.rules",
  "indexes": "firestore.indexes.json"
}
```

---

## 3. Mengaktifkan Cloud Firestore API (kendala utama)

Perintah berikut **gagal** dengan HTTP 403:

```bash
firebase firestore:databases:list --project toko-skincare-fec17
firebase firestore:databases:create "(default)" --location asia-southeast2 \
  --project toko-skincare-fec17
```

```
Cloud Firestore API has not been used in project toko-skincare-fec17 before
or it is disabled.
```

Ini **bukan bug kode aplikasi**, melainkan layanan Google Cloud yang belum
diaktifkan untuk project. `gcloud` tidak terpasang, jadi API diaktifkan lewat
**Service Usage REST API** memakai token OAuth yang sudah disimpan
`firebase-tools` di `~/.config/configstore/firebase-tools.json`:

```bash
POST https://serviceusage.googleapis.com/v1/projects/toko-skincare-fec17/services/firestore.googleapis.com:enable
Authorization: Bearer <access_token>
```

Balasan `HTTP 200` berisi nama operasi; operasi dipantau sampai `done: true`.
Setelah itu database berhasil dibuat:

```bash
firebase firestore:databases:create "(default)" --location asia-southeast2 \
  --project toko-skincare-fec17
# Successfully created projects/toko-skincare-fec17/databases/(default)
```

Lokasi dipilih `asia-southeast2` (Jakarta) karena pengguna berada di Indonesia.
Database baru memiliki **rules tertutup** secara default — aman, tetapi harus
segera di-deploy aturan aplikasi.

> Alternatif bila REST di atas tidak tersedia: buka
> `https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=toko-skincare-fec17`
> lalu klik **Enable**, kemudian buat database di Firebase Console.

---

## 4. Deploy Security Rules

```bash
firebase deploy --only firestore:rules,firestore:indexes \
  --project toko-skincare-fec17
```

```
cloud.firestore: rules file firestore.rules compiled successfully
firestore: deployed indexes in firestore.indexes.json successfully
firestore: released rules firestore.rules to cloud.firestore
Deploy complete!
```

`firestore.indexes.json` sengaja **kosong**: seluruh query cukup satu field
(`orders.where('uid', isEqualTo: ...)`) dan pengurutan tanggal dilakukan di sisi
klien, sehingga tidak dibutuhkan composite index (penting untuk paket Spark).

---

## 5. Menjadikan akun sebagai admin

Rules memaksa `role == 'pelanggan'` saat dokumen `users/{uid}` dibuat. Klien
karena itu **tidak bisa** mengangkat dirinya sendiri. Promosi dilakukan dengan
kredensial pemilik project:

```bash
python scripts/promote_admin.py                       # admin@skincare.id
python scripts/promote_admin.py rina@mail.com        # akun lain
python scripts/promote_admin.py admin@skincare.id --pelanggan   # demote
```

Skrip melakukan:

1. `accounts:lookup` → mencari `localId` (UID) dari email.
2. `PATCH /documents/users/{uid}` → menulis `role: "admin"` lewat REST API
   dengan token OAuth (melewati Security Rules, setara Admin SDK).

Hasil pada pengerjaan ini:

```
users/JRYpdzItPOcyCYHNI2plizDAyHg1 -> role='admin' (admin@skincare.id)
```

Akun `rina@mail.com` dibiarkan sebagai `pelanggan` untuk menguji pembatasan akses.

---

## 6. Data awal

Tidak ada skrip seed terpisah. Saat admin login pertama kali:

- `users/{uid}` sudah ada dengan `role: admin`.
- Listener `products` menerima snapshot kosong.
- `FirestoreDataSource._cobaSeedOtomatis()` memanggil
  `seedProductsIfEmpty()` → `WriteBatch` berisi 10 dokumen dari `MockData`.

Seed hanya dijalankan **sekali per sesi login** (flag `_seedPernahDijalankan`)
agar kegagalan aturan tidak memicu percobaan berulang.

---

## 7. Verifikasi cepat

```bash
firebase firestore:databases:list --project toko-skincare-fec17
firebase deploy --only firestore:rules --project toko-skincare-fec17
flutter analyze
flutter test
flutter build web --release
```

Console: <https://console.firebase.google.com/project/toko-skincare-fec17/firestore/databases/-default-/data>
