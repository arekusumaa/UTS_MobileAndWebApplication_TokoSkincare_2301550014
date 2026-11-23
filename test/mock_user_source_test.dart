import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_store/data/data_sources/mock_user_source.dart';

/// UID Firebase tidak sama dengan ID statis di MockData (`U01`/`U02`).
/// Test ini mengunci perbaikan agar akun admin dikenali di mode simulasi.
void main() {
  group('MockUserSource — pencocokan admin mode simulasi', () {
    const uidFirebaseAdmin = 'JRYpdzItPOcyCYHNI2plizDAyHg1';
    const uidFirebasePelanggan = 'stjEG021jVXudJIN0uY57wdhoDq1';

    test('admin dikenali lewat email meski UID tidak ada di MockData', () {
      final source = MockUserSource(emailSaatIni: () => 'admin@skincare.id');
      expect(source.isAdmin(uidFirebaseAdmin), isTrue);
      expect(source.getUserById(uidFirebaseAdmin)?.role, 'admin');
    });

    test('pelanggan tetap terbaca pelanggan', () {
      final source = MockUserSource(emailSaatIni: () => 'rina@mail.com');
      expect(source.isAdmin(uidFirebasePelanggan), isFalse);
      expect(source.getUserById(uidFirebasePelanggan)?.role, 'pelanggan');
    });

    test('ID statis U01 masih dikenali (kompatibilitas widget test)', () {
      final source = MockUserSource();
      expect(source.isAdmin('U01'), isTrue);
      expect(source.isAdmin('U02'), isFalse);
    });

    test('tanpa closure email, UID asing tetap pelanggan', () {
      final source = MockUserSource();
      expect(source.isAdmin(uidFirebaseAdmin), isFalse);
    });

    test('perbandingan email memakai huruf kecil', () {
      final source = MockUserSource(emailSaatIni: () => ' ADMIN@SKINCARE.ID ');
      expect(source.isAdmin(uidFirebaseAdmin), isTrue);
    });
  });
}
