<?php

namespace App\Controllers\Api;

use CodeIgniter\RESTful\ResourceController;
use App\Models\M_Admin;
use App\Models\M_Pembayaran;
use App\Models\M_Tagihan;
use App\Models\M_Siswa;
use App\Libraries\JWT;

class AdminController extends ResourceController
{
    protected $format = "json";
    protected $siswaModel;
    protected $tagihanModel;
    protected $pembayaranModel;

    public function __construct()
    {
        $this->siswaModel = new M_Siswa();
        $this->tagihanModel = new M_Tagihan();
        $this->pembayaranModel = new M_Pembayaran();
    }

    public function login()
    {
        $input = $this->request->getJSON(true);
        if (!$input) {
            $input = $this->request->getPost();
        }

        $username = $input["username"] ?? "";
        $password = $input["password"] ?? "";

        if (empty($username) || empty($password)) {
            return $this->fail([
                "status"  => false,
                "message" => "Username dan Password wajib diisi"
            ], 400);
        }

        $model = new M_Admin();
        $admin = $model->where('username', $username)->first();

        if (!$admin) {
            return $this->fail([
                "status"  => false,
                "message" => "Username tidak ditemukan"
            ], 404);
        }

        if (!password_verify($password, $admin["password"])) {
            return $this->fail([
                "status"  => false,
                "message" => "Password salah"
            ], 401);
        }

        $issuedAt = time();
        $expire = $issuedAt + (7 * 24 * 60 * 60);

        $payload = [
            "iss"  => "SPP_MOBILE_SERVER",
            "aud"  => "SPP_ADMIN_CLIENT",
            "sub"  => $admin["id_admin"],
            "iat"  => $issuedAt,
            "exp"  => $expire,
            "role" => "admin",
            "data" => [
                "id_admin" => $admin["id_admin"],
                "username" => $admin["username"]
            ]
        ];

        $token = JWT::encode($payload);

        return $this->respond([
            "status"  => true,
            "message" => "Login admin berhasil",
            "token"   => $token,
            "data"    => [
                "id_admin" => $admin["id_admin"],
                "username" => $admin["username"],
                "role"     => "admin"
            ]
        ], 200);
    }

    public function dashboard()
    {
        $siswaModel = new M_Siswa();
        $pembayaranModel = new M_Pembayaran();
        $tagihanModel = new M_Tagihan();

        $data = [
            'total_siswa'        => $siswaModel->countAllResults(),
            'total_pendapatan'   => $pembayaranModel->totalPendapatan(),
            'pending_verifikasi' => $pembayaranModel->countPending(),
            'tagihan_belum_lunas'=> $tagihanModel->countByStatus('belum lunas'),
        ];

        return $this->respond([
            "status" => true,
            "data"   => $data
        ]);
    }

    public function pembayaran()
    {
        $pembayaranModel = new M_Pembayaran();
        $payments = $pembayaranModel->getFilteredPayments(null, null, null);
        
        return $this->respond([
            "status" => true,
            "data"   => $payments
        ]);
    }

    public function approve($id)
    {
        $pembayaranModel = new M_Pembayaran();
        $tagihanModel = new M_Tagihan();

        $pembayaran = $pembayaranModel->find($id);
        if (!$pembayaran) {
            return $this->failNotFound('Data pembayaran tidak ditemukan!');
        }

        $pembayaranModel->update($id, ['status_transaksi' => 'sukses']);
        $tagihanModel->update($pembayaran['id_tagihan'], ['status_bayar' => 'lunas']);

        return $this->respond([
            "status" => true,
            "message" => "Pembayaran berhasil diapprove!"
        ]);
    }

    public function reject($id)
    {
        $pembayaranModel = new M_Pembayaran();
        $pembayaran = $pembayaranModel->find($id);
        if (!$pembayaran) {
            return $this->failNotFound('Data pembayaran tidak ditemukan!');
        }

        $pembayaranModel->update($id, ['status_transaksi' => 'gagal']);

        return $this->respond([
            "status" => true,
            "message" => "Pembayaran telah ditolak."
        ]);
    }

    // ── Tagihan ────────────────────────────────────────────────

    public function tagihanList()
    {
        $db = \Config\Database::connect();
        $builder = $db->table('tagihan t');
        $builder->select('t.*, s.nama_murid')
                ->join('siswa s', 's.nis = t.nis')
                ->orderBy('t.jatuh_tempo', 'DESC');
        $tagihans = $builder->get()->getResultArray();

        return $this->respond([
            "status" => true,
            "data"   => $tagihans
        ]);
    }

    public function tagihanGenerate()
    {
        $input = $this->request->getJSON(true);
        if (!$input) {
            $input = $this->request->getPost();
        }

        $periode    = $input['periode']    ?? '';
        $jatuhTempo = $input['jatuh_tempo'] ?? '';

        if (empty($periode) || empty($jatuhTempo)) {
            return $this->fail(["status" => false, "message" => "Periode dan jatuh tempo wajib diisi."], 400);
        }

        $db = \Config\Database::connect();
        $siswas = $db->table('siswa s')
                     ->select('s.nis, p.nominal')
                     ->join('paket_spp p', 'p.id_paket = s.id_paket')
                     ->get()->getResultArray();

        if (empty($siswas)) {
            return $this->fail(["status" => false, "message" => "Tidak ada data siswa."], 404);
        }

        $tagihanModel = new M_Tagihan();
        $prefix = 'TGH-' . date('ym');
        $lastRow = $db->table('tagihan')
                      ->select('id_tagihan')
                      ->like('id_tagihan', $prefix, 'after')
                      ->orderBy('id_tagihan', 'DESC')
                      ->limit(1)->get()->getRowArray();
        $counter = $lastRow ? (int) substr($lastRow['id_tagihan'], -3) : 0;

        $inserted = 0;
        $skipped  = 0;

        foreach ($siswas as $s) {
            $exists = $tagihanModel->where('nis', $s['nis'])->where('periode', $periode)->first();
            if ($exists) { $skipped++; continue; }
            $counter++;
            $tagihanModel->insert([
                'id_tagihan'   => $prefix . str_pad($counter, 3, '0', STR_PAD_LEFT),
                'nis'          => $s['nis'],
                'status_bayar' => 'belum lunas',
                'nominal'      => $s['nominal'],
                'periode'      => $periode,
                'jatuh_tempo'  => $jatuhTempo,
            ]);
            $inserted++;
        }

        return $this->respond([
            "status"   => true,
            "message"  => "Berhasil generate $inserted tagihan untuk periode $periode." . ($skipped > 0 ? " ($skipped dilewati)" : ''),
            "inserted" => $inserted,
            "skipped"  => $skipped,
        ]);
    }

    public function tagihanDelete($id)
    {
        $tagihanModel = new M_Tagihan();
        $tagihan = $tagihanModel->find($id);
        if (!$tagihan) {
            return $this->failNotFound('Data tagihan tidak ditemukan!');
        }
        $tagihanModel->delete($id);
        return $this->respond(["status" => true, "message" => "Tagihan berhasil dihapus."]);
    }

    // ── Siswa & Paket SPP ──────────────────────────────────────

    public function paketList()
    {
        $db = \Config\Database::connect();
        $pakets = $db->table('paket_spp')->orderBy('id_paket', 'ASC')->get()->getResultArray();
        return $this->respond([
            "status" => true,
            "data"   => $pakets
        ]);
    }

    public function siswaList()
    {
        $db = \Config\Database::connect();
        $siswas = $db->table('siswa s')
                     ->select('s.nis, s.nama_murid, s.jenis_kelamin, s.level, s.alamat, s.tanggal_lahir, s.id_paket, p.nama_paket, p.nominal')
                     ->join('paket_spp p', 'p.id_paket = s.id_paket', 'left')
                     ->orderBy('s.nama_murid', 'ASC')
                     ->get()->getResultArray();

        return $this->respond([
            "status" => true,
            "data"   => $siswas
        ]);
    }

    public function siswaCreate()
    {
        $input = $this->request->getJSON(true) ?: $this->request->getPost();

        $nis          = trim($input['nis'] ?? '');
        $namaMurid    = trim($input['nama_murid'] ?? '');
        $jenisKelamin = trim($input['jenis_kelamin'] ?? 'laki-laki');
        $idPaket      = trim($input['id_paket'] ?? '');
        $level        = trim($input['level'] ?? '1');
        $alamat       = trim($input['alamat'] ?? '-');
        $tanggalLahir = trim($input['tanggal_lahir'] ?? date('Y-m-d'));
        $password     = trim($input['password'] ?? 'password');

        if (empty($nis) || empty($namaMurid) || empty($idPaket)) {
            return $this->fail(["status" => false, "message" => "NIS, Nama Murid, dan Paket SPP wajib diisi."], 400);
        }

        $existing = $this->siswaModel->find($nis);
        if ($existing) {
            return $this->fail(["status" => false, "message" => "Siswa dengan NIS $nis sudah terdaftar."], 400);
        }

        $this->siswaModel->insert([
            'nis'           => $nis,
            'nama_murid'    => $namaMurid,
            'jenis_kelamin' => $jenisKelamin,
            'id_paket'      => $idPaket,
            'level'         => $level,
            'alamat'        => $alamat,
            'tanggal_lahir' => $tanggalLahir,
            'password'      => password_hash($password, PASSWORD_DEFAULT),
        ]);

        return $this->respondCreated([
            "status"  => true,
            "message" => "Data siswa $namaMurid ($nis) berhasil ditambahkan.",
            "data"    => [
                "nis"        => $nis,
                "nama_murid" => $namaMurid,
            ]
        ]);
    }

    public function siswaUpdate($nis = null)
    {
        if (empty($nis)) {
            return $this->fail(["status" => false, "message" => "NIS tidak valid."], 400);
        }

        $siswa = $this->siswaModel->find($nis);
        if (!$siswa) {
            return $this->failNotFound("Data siswa dengan NIS $nis tidak ditemukan.");
        }

        $input = $this->request->getJSON(true) ?: $this->request->getRawInput();

        $updateData = [];
        if (isset($input['nama_murid']))    $updateData['nama_murid']    = trim($input['nama_murid']);
        if (isset($input['jenis_kelamin'])) $updateData['jenis_kelamin'] = trim($input['jenis_kelamin']);
        if (isset($input['id_paket']))      $updateData['id_paket']      = trim($input['id_paket']);
        if (isset($input['level']))         $updateData['level']         = trim($input['level']);
        if (isset($input['alamat']))        $updateData['alamat']        = trim($input['alamat']);
        if (isset($input['tanggal_lahir'])) $updateData['tanggal_lahir'] = trim($input['tanggal_lahir']);
        
        $password = trim($input['password'] ?? '');
        if (!empty($password)) {
            $updateData['password'] = password_hash($password, PASSWORD_DEFAULT);
        }

        if (empty($updateData)) {
            return $this->fail(["status" => false, "message" => "Tidak ada data yang diperbarui."], 400);
        }

        $this->siswaModel->update($nis, $updateData);

        return $this->respond([
            "status"  => true,
            "message" => "Data siswa $nis berhasil diperbarui.",
        ]);
    }

    public function siswaDelete($nis = null)
    {
        if (empty($nis)) {
            return $this->fail(["status" => false, "message" => "NIS tidak valid."], 400);
        }

        $siswa = $this->siswaModel->find($nis);
        if (!$siswa) {
            return $this->failNotFound("Data siswa dengan NIS $nis tidak ditemukan.");
        }

        $db = \Config\Database::connect();
        $db->transStart();

        // Cari semua id_tagihan milik siswa ini
        $tagihans = $db->table('tagihan')->select('id_tagihan')->where('nis', $nis)->get()->getResultArray();
        $tagihanIds = array_column($tagihans, 'id_tagihan');

        if (!empty($tagihanIds)) {
            // Hapus pembayaran terkait
            $db->table('pembayaran')->whereIn('id_tagihan', $tagihanIds)->delete();
            // Hapus tagihan terkait
            $db->table('tagihan')->where('nis', $nis)->delete();
        }

        // Hapus siswa
        $db->table('siswa')->where('nis', $nis)->delete();

        $db->transComplete();

        if ($db->transStatus() === false) {
            return $this->failServerError("Gagal menghapus data siswa.");
        }

        return $this->respond([
            "status"  => true,
            "message" => "Data siswa {$siswa['nama_murid']} ($nis) berhasil dihapus.",
        ]);
    }
}
