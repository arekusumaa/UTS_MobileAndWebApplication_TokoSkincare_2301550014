class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'Kolom'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? requiredMinLength(
    String? value, {
    required int minLength,
    String fieldName = 'Kolom',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    if (value.length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    return null;
  }

  static String? numeric(String? value, {String fieldName = 'Kolom'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    if (int.tryParse(value) == null) {
      return '$fieldName harus berupa angka';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) {
      return 'Konfirmasi kata sandi tidak cocok';
    }
    return null;
  }
}
