<?php

namespace App\Controllers\Api;

use CodeIgniter\RESTful\ResourceController;
use App\Models\M_Siswa;
use App\Models\M_Admin;
use App\Libraries\JWT;

class AuthController extends ResourceController
{
    protected $format = "json";

    /**
     * Unified Login: Supports both Siswa (NIS) and Admin/Owner (Username)
     */
    public function loginUnified()
    {
        $input = $this->request->getJSON(true) ?: $this->request->getPost();

        $username = trim($input["username"] ?? $input["nis"] ?? "");
        $password = trim($input["password"] ?? "");

        if (empty($username) || empty($password)) {
            return $this->fail([
                "status"  => false,
                "message" => "Username/NIS dan Password wajib diisi"
            ], 400);
        }

        $db = \Config\Database::connect();

        // 1. Cek Admin terlebih dahulu
        $admin = $db->table("admin")->where("username", $username)->get()->getRowArray();
        if ($admin) {
            if (!password_verify($password, $admin["password"])) {
                return $this->fail([
                    "status"  => false,
                    "message" => "Password admin yang Anda masukkan salah"
                ], 401);
            }

            $isOwner = (strtolower($admin["username"]) === 'owner');
            $role = $isOwner ? 'owner' : 'admin';

            $issuedAt = time();
            $expire = $issuedAt + (7 * 24 * 60 * 60);

            $payload = [
                "iss"  => "SPP_MOBILE_SERVER",
                "aud"  => "SPP_CLIENT",
                "sub"  => $admin["id_admin"],
                "role" => "admin",
                "iat"  => $issuedAt,
                "exp"  => $expire,
                "data" => [
                    "id_admin" => $admin["id_admin"],
                    "username" => $admin["username"],
                    "role"     => $role,
                ]
            ];

            $token = JWT::encode($payload);

            return $this->respond([
                "status"  => true,
                "message" => "Login berhasil sebagai " . ucfirst($role),
                "token"   => $token,
                "data"    => [
                    "role"       => $role,
                    "id_admin"   => $admin["id_admin"],
                    "username"   => $admin["username"],
                    "nama_murid" => "Admin " . ucfirst($admin["username"]),
                    "nis"        => $admin["username"],
                ]
            ], 200);
        }

        // 2. Cek Siswa berdasarkan NIS
        $siswa = $db->table("siswa s")
            ->select("s.*, p.nama_paket, p.nominal")
            ->join("paket_spp p", "p.id_paket = s.id_paket", "left")
            ->where("s.nis", $username)
            ->get()->getRowArray();

        if ($siswa) {
            if (!password_verify($password, $siswa["password"])) {
                return $this->fail([
                    "status"  => false,
                    "message" => "Password siswa yang Anda masukkan salah"
                ], 401);
            }

            $issuedAt = time();
            $expire = $issuedAt + (7 * 24 * 60 * 60);

            $payload = [
                "iss"  => "SPP_MOBILE_SERVER",
                "aud"  => "SPP_STUDENT_CLIENT",
                "sub"  => $siswa["nis"],
                "role" => "siswa",
                "iat"  => $issuedAt,
                "exp"  => $expire,
                "data" => [
                    "nis"        => $siswa["nis"],
                    "nama_murid" => $siswa["nama_murid"]
                ]
            ];

            $token = JWT::encode($payload);

            return $this->respond([
                "status"  => true,
                "message" => "Login berhasil sebagai Siswa",
                "token"   => $token,
                "data"    => [
                    "role"          => "siswa",
                    "nis"           => $siswa["nis"],
                    "nama_murid"    => $siswa["nama_murid"],
                    "jenis_kelamin" => $siswa["jenis_kelamin"],
                    "level"         => "Level " . $siswa["level"],
                    "nama_paket"    => $siswa["nama_paket"] ?? "-",
                    "nominal"       => (float)($siswa["nominal"] ?? 0),
                    "alamat"        => $siswa["alamat"] ?? "-",
                    "tanggal_lahir" => $siswa["tanggal_lahir"] ?? ""
                ]
            ], 200);
        }

        return $this->fail([
            "status"  => false,
            "message" => "Akun dengan Username/NIS '$username' tidak ditemukan"
        ], 404);
    }

    public function login()
    {
        return $this->loginUnified();
    }

    public function logout()
    {
        return $this->respond([
            "status"  => true,
            "message" => "Logout berhasil"
        ]);
    }
}
