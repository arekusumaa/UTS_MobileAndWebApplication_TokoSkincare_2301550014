import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_store/core/utils/validasi_auth.dart';

/// Unit test murni (tidak memanggil Firebase), aman dijalankan di CI.
/// Mengunci pesan yang dipakai pada tabel uji login Minggu 9.
void main() {
  group('validasiEmail', () {
    test('email kosong ditolak', () {
      expect(validasiEmail(''), 'Email wajib diisi');
      expect(validasiEmail(null), 'Email wajib diisi');
    });

    test('format email salah ditolak', () {
      expect(validasiEmail('rina'), 'Format email belum benar');
      expect(validasiEmail('rina@'), 'Format email belum benar');
    });

    test('email benar diterima', () {
      expect(validasiEmail('rina@mail.com'), isNull);
      expect(validasiEmail('  rina@mail.com  '), isNull);
    });
  });

  group('validasiPassword', () {
    test('password kosong ditolak', () {
      expect(validasiPassword(''), 'Password wajib diisi');
    });

    test('password kurang dari 6 karakter ditolak', () {
      expect(validasiPassword('12345'), 'Password minimal 6 karakter');
    });

    test('password 6 karakter diterima', () {
      expect(validasiPassword('123456'), isNull);
    });
  });

  group('validasiUlangiPassword', () {
    test('kolom ulangi kosong ditolak', () {
      expect(validasiUlangiPassword('', '123456'),
          'Ulangi password wajib diisi');
    });

    test('password tidak sama ditolak', () {
      expect(validasiUlangiPassword('654321', '123456'), 'Password tidak sama');
    });

    test('password sama diterima', () {
      expect(validasiUlangiPassword('123456', '123456'), isNull);
    });
  });

  group('pesanKesalahanAuth', () {
    test('kode kredensial disamarkan', () {
      for (final kode in [
        'invalid-credential',
        'wrong-password',
        'user-not-found',
      ]) {
        expect(pesanKesalahanAuth(kode), 'Email atau password salah');
      }
    });

    test('kode umum diterjemahkan', () {
      expect(pesanKesalahanAuth('email-already-in-use'),
          'Email sudah terdaftar. Silakan masuk.');
      expect(pesanKesalahanAuth('weak-password'),
          'Password terlalu lemah, minimal 6 karakter');
      expect(pesanKesalahanAuth('invalid-email'), 'Format email belum benar');
      expect(pesanKesalahanAuth('network-request-failed'),
          'Tidak dapat terhubung. Periksa koneksi internet.');
      expect(pesanKesalahanAuth('too-many-requests'),
          'Terlalu banyak percobaan. Coba lagi nanti.');
      expect(pesanKesalahanAuth('operation-not-allowed'),
          'Login email/password belum diaktifkan di Firebase Console');
    });

    test('kode tak dikenal jatuh ke pesan umum', () {
      expect(pesanKesalahanAuth('kode-asing'),
          'Terjadi kesalahan. Silakan coba lagi.');
    });
  });
}
