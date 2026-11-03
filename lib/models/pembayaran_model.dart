class PembayaranModel {
  final String idPembayaran;
  final String idTagihan;
  final String periode;
  final String bulan;
  final String tahun;
  final double nominal;
  final String metode;
  final String va;
  final String status;
  final String tanggalBayar;
  final String? buktiBayar;
  final String? buktiUrl;

  PembayaranModel({
    required this.idPembayaran,
    required this.idTagihan,
    required this.periode,
    required this.bulan,
    required this.tahun,
    required this.nominal,
    required this.metode,
    required this.va,
    required this.status,
    required this.tanggalBayar,
    this.buktiBayar,
    this.buktiUrl,
  });

  bool get isSukses => status.toLowerCase() == 'sukses';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isGagal => status.toLowerCase() == 'gagal';

  factory PembayaranModel.fromJson(Map<String, dynamic> json) {
    return PembayaranModel(
      idPembayaran: json['id_pembayaran']?.toString() ?? '',
      idTagihan: json['id_tagihan']?.toString() ?? '',
      periode: json['periode']?.toString() ?? '',
      bulan: json['bulan']?.toString() ?? '',
      tahun: json['tahun']?.toString() ?? '',
      nominal: double.tryParse(json['nominal']?.toString() ?? '0') ?? 0.0,
      metode: json['metode']?.toString() ?? 'Transfer Bank',
      va: json['va']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'pending',
      tanggalBayar: json['tanggal_bayar']?.toString() ?? '',
      buktiBayar: json['bukti_bayar']?.toString(),
      buktiUrl: json['bukti_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pembayaran': idPembayaran,
      'id_tagihan': idTagihan,
      'periode': periode,
      'bulan': bulan,
      'tahun': tahun,
      'nominal': nominal,
      'metode': metode,
      'va': va,
      'status': status,
      'tanggal_bayar': tanggalBayar,
      'bukti_bayar': buktiBayar,
      'bukti_url': buktiUrl,
    };
  }
}
