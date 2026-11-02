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

  static String? positiveNumeric(String? value, {String fieldName = 'Kolom'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    final num = int.tryParse(value);
    if (num == null) {
      return '$fieldName harus berupa angka';
    }
    if (num <= 0) {
      return '$fieldName tidak boleh nol';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon wajib diisi';
    }
    if (int.tryParse(value) == null) {
      return 'Nomor telepon harus berupa angka';
    }
    if (value.length < 10) {
      return 'Nomor telepon minimal 10 digit';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi';
    }
    if (value != original) {
      return 'Konfirmasi kata sandi tidak cocok';
    }
    return null;
  }
}
