class AppUser {
  final String id;
  final String nama;
  final String email;
  final String role;

  const AppUser({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  bool get isPelanggan => role == 'pelanggan';

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      nama: map['nama'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'role': role,
    };
  }
}
