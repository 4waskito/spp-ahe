class TagihanModel {
  final String idTagihan;
  final String periode;
  final String bulan;
  final String tahun;
  final double nominal;
  final String statusBayar;
  final String jatuhTempo;

  TagihanModel({
    required this.idTagihan,
    required this.periode,
    required this.bulan,
    required this.tahun,
    required this.nominal,
    required this.statusBayar,
    required this.jatuhTempo,
  });

  bool get isLunas => statusBayar.toLowerCase() == 'lunas';
  bool get isPending => statusBayar.toLowerCase() == 'pending';
  bool get isBelumLunas =>
      statusBayar.toLowerCase() == 'belum lunas' ||
      statusBayar.toLowerCase() == 'belum_lunas';

  factory TagihanModel.fromJson(Map<String, dynamic> json) {
    return TagihanModel(
      idTagihan: json['id_tagihan']?.toString() ?? '',
      periode: json['periode']?.toString() ?? '',
      bulan: json['bulan']?.toString() ?? '',
      tahun: json['tahun']?.toString() ?? '',
      nominal: double.tryParse(json['nominal']?.toString() ?? '0') ?? 0.0,
      statusBayar: json['status_bayar']?.toString() ?? 'belum lunas',
      jatuhTempo: json['jatuh_tempo']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tagihan': idTagihan,
      'periode': periode,
      'bulan': bulan,
      'tahun': tahun,
      'nominal': nominal,
      'status_bayar': statusBayar,
      'jatuh_tempo': jatuhTempo,
    };
  }
}
