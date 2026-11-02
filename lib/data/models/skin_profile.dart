class SkinProfile {
  final String tipeKulit;
  final List<String> concern;
  final List<String> alergi;

  const SkinProfile({
    required this.tipeKulit,
    required this.concern,
    required this.alergi,
  });

  bool get isEmpty => tipeKulit.isEmpty && concern.isEmpty;

  SkinProfile copyWith({
    String? tipeKulit,
    List<String>? concern,
    List<String>? alergi,
  }) {
    return SkinProfile(
      tipeKulit: tipeKulit ?? this.tipeKulit,
      concern: concern ?? this.concern,
      alergi: alergi ?? this.alergi,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipeKulit': tipeKulit,
      'concern': concern,
      'alergi': alergi,
    };
  }

  factory SkinProfile.empty() {
    return const SkinProfile(tipeKulit: '', concern: [], alergi: []);
  }
}
