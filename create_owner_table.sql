-- =====================================================
-- Migrasi Database: Tabel Owner untuk SPP Les Ahe
-- =====================================================

-- 1. Buat tabel owner
CREATE TABLE IF NOT EXISTS `owner` (
  `id_owner`   INT(11)      NOT NULL AUTO_INCREMENT,
  `username`   VARCHAR(50)  NOT NULL,
  `password`   VARCHAR(255) NOT NULL,
  `nama`       VARCHAR(100) NOT NULL DEFAULT 'Owner',
  `created_at` DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_owner`),
  UNIQUE KEY `uk_owner_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Insert default owner account (password: owner123, bcrypt hash)
--    Ganti hash ini dengan hasil password_hash('owner123', PASSWORD_BCRYPT) di PHP jika perlu.
INSERT INTO `owner` (`username`, `password`, `nama`)
VALUES ('owner', '$2y$10$ATplt05AjYOGKAaCF9CkJOXiQX1gBYR7oqZZgXsu7JCaznhT2RG1i', 'Owner Les Ahe');

-- =====================================================
-- CATATAN BACKEND (CodeIgniter 4):
-- =====================================================
-- Endpoint baru: POST /api/auth/login_unified
--
-- Controller harus:
-- 1. Menerima { "username": "...", "password": "..." }
-- 2. Cari di tabel `siswa` (WHERE nis = username OR username = username)
-- 3. Kalau tidak ketemu, cari di tabel `admin` (WHERE username = username)
-- 4. Kalau tidak ketemu, cari di tabel `owner` (WHERE username = username)
-- 5. Verifikasi password dengan password_verify()
-- 6. Return response dengan role:
--    - Siswa:  { "status": true, "token": "...", "data": { "role": "siswa", ... } }
--    - Admin:  { "status": true, "token": "...", "data": { "role": "admin", ... } }
--    - Owner:  { "status": true, "token": "...", "data": { "role": "owner", ... } }
-- =====================================================
