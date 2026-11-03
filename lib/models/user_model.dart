class UserModel {
  final String nis;
  final String namaMurid;
  final String jenisKelamin;
  final String level;
  final String namaPaket;
  final double nominal;
  final String alamat;
  final String tanggalLahir;
  final String role; // 'siswa', 'admin', 'owner'
  final String idAdmin;
  final String idOwner;
  final String username;

  UserModel({
    required this.nis,
    required this.namaMurid,
    required this.jenisKelamin,
    required this.level,
    required this.namaPaket,
    required this.nominal,
    required this.alamat,
    required this.tanggalLahir,
    this.role = 'siswa',
    this.idAdmin = '',
    this.idOwner = '',
    this.username = '',
  });

  bool get isAdmin => role == 'admin';
  bool get isOwner => role == 'owner';
  bool get isSiswa => role == 'siswa';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nis: json['nis']?.toString() ?? '',
      namaMurid: json['nama_murid']?.toString() ?? '',
      jenisKelamin: json['jenis_kelamin']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      namaPaket: json['nama_paket']?.toString() ?? '-',
      nominal: double.tryParse(json['nominal']?.toString() ?? '0') ?? 0.0,
      alamat: json['alamat']?.toString() ?? '-',
      tanggalLahir: json['tanggal_lahir']?.toString() ?? '',
      role: json['role']?.toString() ?? 'siswa',
      idAdmin: json['id_admin']?.toString() ?? '',
      idOwner: json['id_owner']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nis': nis,
      'nama_murid': namaMurid,
      'jenis_kelamin': jenisKelamin,
      'level': level,
      'nama_paket': namaPaket,
      'nominal': nominal,
      'alamat': alamat,
      'tanggal_lahir': tanggalLahir,
      'role': role,
      'id_admin': idAdmin,
      'id_owner': idOwner,
      'username': username,
    };
  }
}
