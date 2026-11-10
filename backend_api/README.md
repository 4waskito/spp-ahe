# Standalone CI4 REST API Server - SPP Mobile (Les Ahe)

Backend REST API terpisah berbasis **CodeIgniter 4** yang dirancang khusus melayani klien mobile Flutter (`flutter_mobile_1`), terhubung langsung ke database MySQL yang sama (`pembayaran_spp_revisi`).

---

## 1. Arsitektur & Konfigurasi

* **Framework:** CodeIgniter 4 (PHP ^8.2)
* **Format Respon:** JSON (RESTful API)
* **Autentikasi:** JSON Web Token (JWT Bearer Token HS256)
* **Database MySQL:** `pembayaran_spp_revisi` (Port 3306)
* **CORS:** Diaktifkan untuk akses Flutter Web & Mobile

---

## 2. Cara Menjalankan Server

### Opsi A: Melalui XAMPP Apache (Rekomendasi)
Backend ini sudah terhubung via directory junction ke `C:\xampp\htdocs\spp_api`.
Cukup aktifkan **Apache** dan **MySQL** di XAMPP Control Panel.

* **Base URL Localhost:** `http://localhost/spp_api/public/index.php/api`
* **Base URL Android Emulator:** `http://10.0.2.2/spp_api/public/index.php/api`
* **Base URL HP Fisik (LAN/Wi-Fi):** `http://<IP_KOMPUTER>/spp_api/public/index.php/api`

### Opsi B: Melalui CodeIgniter Spark CLI
Buka terminal di folder `backend_api` lalu jalankan:
```bash
php spark serve --port 8081
```
* **Base URL:** `http://localhost:8081/api`

---

## 3. Akun Pengujian (Testing Credentials)

| Role | Username / NIS | Password | Akses Fitur |
|---|---|---|---|
| **Admin** | `admin` | `admin123` | Dashboard Admin, Verifikasi Pembayaran, Kelola Siswa, Generate Tagihan |
| **Siswa** | `NIS001` | `12345` | Dashboard Siswa, Tagihan SPP, Bayar (Transfer/Midtrans), Riwayat |
| **Siswa 2** | `NIS002` | `12345` | Cek status tagihan pending & riwayat |

---

## 4. Daftar Endpoint REST API

### Autentikasi
* `POST /api/auth/login_unified` - Login multi-peran (Admin & Siswa otomatis terdeteksi)
* `POST /api/auth/login` - Login Siswa (NIS + Password)
* `POST /api/auth/login_admin` - Login Admin (Username + Password)
* `POST /api/auth/logout` - Logout sesi JWT

### Siswa (Header: `Authorization: Bearer <token>`)
* `GET  /api/siswa/profile` - Data profil & statistik tagihan siswa
* `GET  /api/siswa/tagihan` - Daftar seluruh tagihan bulanan
* `POST /api/siswa/bayar` - Submit pembayaran manual (upload bukti transfer)
* `GET  /api/siswa/riwayat` - Riwayat transaksi pembayaran
* `POST /api/siswa/midtrans/snap-token` - Request Snap Token Midtrans QRIS/VA
* `GET  /api/siswa/midtrans/status/(:any)` - Pengecekan status transaksi Midtrans

### Admin (Header: `Authorization: Bearer <token>`)
* `GET    /api/admin/dashboard` - Statistik metrik keuangan & jumlah siswa
* `GET    /api/admin/pembayaran` - Daftar seluruh pembayaran masuk
* `POST   /api/admin/pembayaran/approve/(:id)` - Validasi & verifikasi lunas pembayaran
* `POST   /api/admin/pembayaran/reject/(:id)` - Tolak pembayaran yang tidak valid
* `GET    /api/admin/tagihan` - Daftar tagihan siswa
* `POST   /api/admin/tagihan/generate` - Generate tagihan massal bulanan
* `DELETE /api/admin/tagihan/(:id)` - Batalkan/hapus tagihan
* `GET    /api/admin/siswa` - Master data siswa
* `POST   /api/admin/siswa` - Pendaftaran siswa baru
* `PUT    /api/admin/siswa/(:nis)` - Edit biodata siswa
* `DELETE /api/admin/siswa/(:nis)` - Hapus akun siswa beserta relasinya
* `GET    /api/admin/paket` - Data referensi paket bimbingan belajar

