<?php

namespace App\Controllers\Api;

use CodeIgniter\RESTful\ResourceController;
use App\Models\M_Tagihan;
use App\Models\M_Pembayaran;
use App\Models\M_Siswa;

class SiswaController extends ResourceController
{
    protected $format = "json";
    protected $tagihanModel;
    protected $pembayaranModel;
    protected $siswaModel;

    public function __construct()
    {
        $this->tagihanModel = new M_Tagihan();
        $this->pembayaranModel = new M_Pembayaran();
        $this->siswaModel = new M_Siswa();
    }

    private function getAuthNis(): ?string
    {
        return $_SERVER["AUTH_SISWA_NIS"] ?? null;
    }

    public function profile()
    {
        $nis = $this->getAuthNis();
        if (!$nis) {
            return $this->failUnauthorized("Autentikasi diperlukan");
        }

        $db = \Config\Database::connect();
        $siswa = $db->table("siswa s")
            ->select("s.*, p.nama_paket, p.nominal")
            ->join("paket_spp p", "p.id_paket = s.id_paket", "left")
            ->where("s.nis", $nis)
            ->get()->getRowArray();

        if (!$siswa) {
            return $this->failNotFound("Data siswa tidak ditemukan");
        }

        $tagihans = $this->tagihanModel->where("nis", $nis)->findAll();
        $totalTagihan = count($tagihans);
        $totalLunas = 0;
        $totalPending = 0;
        $totalBelumLunas = 0;
        $totalNominalTunggakan = 0;

        foreach ($tagihans as $t) {
            if ($t["status_bayar"] === "lunas") {
                $totalLunas++;
            } elseif ($t["status_bayar"] === "pending") {
                $totalPending++;
            } else {
                $totalBelumLunas++;
                $totalNominalTunggakan += (float)$t["nominal"];
            }
        }

        return $this->respond([
            "status" => true,
            "data"   => [
                "nis"                   => $siswa["nis"],
                "nama_murid"            => $siswa["nama_murid"],
                "jenis_kelamin"         => $siswa["jenis_kelamin"],
                "level"                 => "Level " . $siswa["level"],
                "nama_paket"            => $siswa["nama_paket"] ?? "-",
                "nominal_paket"         => (float)($siswa["nominal"] ?? 0),
                "alamat"                => $siswa["alamat"] ?? "-",
                "tanggal_lahir"         => $siswa["tanggal_lahir"] ?? "",
                "total_tagihan"         => $totalTagihan,
                "total_lunas"           => $totalLunas,
                "total_pending"         => $totalPending,
                "total_belum_lunas"     => $totalBelumLunas,
                "total_nominal_tunggak" => $totalNominalTunggakan,
            ]
        ]);
    }

    public function tagihan()
    {
        $nis = $this->getAuthNis();
        if (!$nis) {
            return $this->failUnauthorized("Autentikasi diperlukan");
        }

        $tagihans = $this->tagihanModel
            ->where("nis", $nis)
            ->orderBy("id_tagihan", "DESC")
            ->findAll();

        $result = [];
        foreach ($tagihans as $t) {
            $parts = explode(" ", $t["periode"]);
            $bulan = $parts[0] ?? $t["periode"];
            $tahun = $parts[1] ?? "";

            $result[] = [
                "id_tagihan"   => $t["id_tagihan"],
                "periode"      => $t["periode"],
                "bulan"        => $bulan,
                "tahun"        => $tahun,
                "nominal"      => (float)$t["nominal"],
                "status_bayar" => $t["status_bayar"],
                "jatuh_tempo"  => $t["jatuh_tempo"],
            ];
        }

        return $this->respond([
            "status" => true,
            "data"   => $result
        ]);
    }

    public function bayar()
    {
        $nis = $this->getAuthNis();
        if (!$nis) {
            return $this->failUnauthorized("Autentikasi diperlukan");
        }

        $idTagihan = $this->request->getPost("id_tagihan");
        $metodeBayar = $this->request->getPost("metode_pembayaran") ?? $this->request->getPost("metode_bayar");
        $namaPengirim = $this->request->getPost("nama_pengirim") ?? "";

        if (empty($idTagihan)) {
            return $this->fail([
                "status"  => false,
                "message" => "id_tagihan wajib diisi"
            ], 400);
        }

        if (empty($metodeBayar)) {
            $metodeBayar = "Transfer Bank";
        }

        $tagihan = $this->tagihanModel->where("nis", $nis)->find($idTagihan);
        if (!$tagihan) {
            return $this->failNotFound("Tagihan tidak ditemukan atau bukan milik akun Anda");
        }

        if ($tagihan["status_bayar"] === "lunas") {
            return $this->fail([
                "status"  => false,
                "message" => "Tagihan ini sudah lunas"
            ], 400);
        }

        // Handle file upload
        $buktiBayar = $this->request->getFile("bukti") ?? $this->request->getFile("bukti_bayar");
        $buktiName = null;

        if ($buktiBayar && $buktiBayar->isValid() && !$buktiBayar->hasMoved()) {
            $mime = $buktiBayar->getMimeType();
            $allowedMimes = ["image/jpeg", "image/png", "image/jpg", "image/webp"];
            if (!in_array($mime, $allowedMimes)) {
                return $this->fail([
                    "status"  => false,
                    "message" => "Format berkas tidak didukung. Harap unggah gambar JPG/PNG."
                ], 400);
            }

            $buktiName = $buktiBayar->getRandomName();
            $uploadPath = WRITEPATH . "uploads/bukti/";
            if (!is_dir($uploadPath)) {
                mkdir($uploadPath, 0777, true);
            }
            $buktiBayar->move($uploadPath, $buktiName);
        } else {
            return $this->fail([
                "status"  => false,
                "message" => "Bukti pembayaran (gambar struk transfer) wajib diunggah"
            ], 400);
        }

        $idPembayaran = "PAY-" . date("Ymd") . rand(100, 999);
        $va = !empty($namaPengirim) ? "Pengirim: " . $namaPengirim : "Manual Transfer";

        $this->pembayaranModel->insert([
            "id_pembayaran"    => $idPembayaran,
            "id_tagihan"       => $idTagihan,
            "metode_bayar"     => $metodeBayar,
            "va"               => $va,
            "status_transaksi" => "pending",
            "bukti_bayar"      => $buktiName,
            "waktu_bayar"      => date("Y-m-d H:i:s"),
        ]);

        $this->tagihanModel->update($idTagihan, ["status_bayar" => "pending"]);

        return $this->respondCreated([
            "status"        => true,
            "message"       => "Bukti pembayaran berhasil diunggah dan sedang diverifikasi.",
            "id_pembayaran" => $idPembayaran,
            "bukti_file"    => $buktiName
        ]);
    }

    public function riwayat()
    {
        $nis = $this->getAuthNis();
        if (!$nis) {
            return $this->failUnauthorized("Autentikasi diperlukan");
        }

        $db = \Config\Database::connect();
        $payments = $db->table("pembayaran p")
            ->select("p.*, t.periode, t.nominal, t.status_bayar")
            ->join("tagihan t", "t.id_tagihan = p.id_tagihan")
            ->where("t.nis", $nis)
            ->orderBy("p.waktu_bayar", "DESC")
            ->get()->getResultArray();

        $protocol = (!empty($_SERVER["HTTPS"]) && $_SERVER["HTTPS"] !== "off") ? "https://" : "http://";
        $host = $_SERVER["HTTP_HOST"] ?? "localhost";
        $scriptDir = str_replace("\\", "/", dirname($_SERVER["SCRIPT_NAME"] ?? ""));
        $base = rtrim($protocol . $host . $scriptDir, "/");

        $result = [];
        foreach ($payments as $p) {
            $parts = explode(" ", $p["periode"]);
            $bulan = $parts[0] ?? $p["periode"];
            $tahun = $parts[1] ?? "";

            $buktiUrl = null;
            if (!empty($p["bukti_bayar"])) {
                $buktiUrl = $base . "/uploads/bukti/" . $p["bukti_bayar"];
            }

            $result[] = [
                "id_pembayaran" => $p["id_pembayaran"],
                "id_tagihan"    => $p["id_tagihan"],
                "periode"       => $p["periode"],
                "bulan"         => $bulan,
                "tahun"         => $tahun,
                "nominal"       => (float)$p["nominal"],
                "metode"        => $p["metode_bayar"],
                "va"            => $p["va"],
                "status"        => $p["status_transaksi"],
                "tanggal_bayar" => $p["waktu_bayar"],
                "bukti_bayar"   => $p["bukti_bayar"],
                "bukti_url"     => $buktiUrl,
            ];
        }

        return $this->respond([
            "status" => true,
            "data"   => $result
        ]);
    }

    public function midtransSnap()
    {
        $nis = $this->getAuthNis();
        if (!$nis) {
            return $this->failUnauthorized("Autentikasi diperlukan");
        }

        $idTagihan = $this->request->getPost("id_tagihan");
        if (empty($idTagihan)) {
            $json = $this->request->getJSON(true);
            $idTagihan = $json["id_tagihan"] ?? null;
        }

        if (empty($idTagihan)) {
            return $this->fail(["status" => false, "message" => "id_tagihan wajib diisi"], 400);
        }

        $tagihan = $this->tagihanModel->where("nis", $nis)->find($idTagihan);
        if (!$tagihan) {
            return $this->failNotFound("Tagihan tidak ditemukan atau bukan milik akun Anda");
        }

        if ($tagihan["status_bayar"] === "lunas") {
            return $this->fail(["status" => false, "message" => "Tagihan ini sudah lunas"], 400);
        }

        $siswa = $this->siswaModel->find($nis);
        $namaSiswa = $siswa["nama_murid"] ?? "Siswa $nis";

        $serverKey = env('MIDTRANS_SERVER_KEY');
        if (empty($serverKey)) {
            return $this->fail(["status" => false, "message" => "Server Key Midtrans belum dikonfigurasi"], 500);
        }

        $orderId = $tagihan['id_tagihan'] . '-' . time();
        $grossAmount = (int)$tagihan['nominal'];

        $params = [
            'transaction_details' => [
                'order_id'     => $orderId,
                'gross_amount' => $grossAmount,
            ],
            'customer_details' => [
                'first_name' => $namaSiswa,
                'email'      => $nis . '@siswa.sekolah.id',
            ],
            'item_details' => [
                [
                    'id'       => $tagihan['id_tagihan'],
                    'price'    => $grossAmount,
                    'quantity' => 1,
                    'name'     => 'SPP Periode ' . $tagihan['periode'],
                ]
            ]
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "https://app.sandbox.midtrans.com/snap/v1/transactions");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($params));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Content-Type: application/json",
            "Accept: application/json",
            "Authorization: Basic " . base64_encode($serverKey . ":")
        ]);
        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode == 201) {
            $resp = json_decode($result, true);
            $token = $resp['token'] ?? '';
            $redirectUrl = $resp['redirect_url'] ?? '';

            // Insert initial record into pembayaran
            $this->pembayaranModel->insert([
                'id_pembayaran'    => 'PAY-' . time() . rand(10, 99),
                'id_tagihan'       => $tagihan['id_tagihan'],
                'metode_bayar'     => 'Midtrans (Virtual Account)',
                'va'               => $orderId,
                'status_transaksi' => 'pending',
                'bukti_bayar'      => null,
                'waktu_bayar'      => date('Y-m-d H:i:s'),
            ]);

            // Update tagihan status
            $this->tagihanModel->update($tagihan['id_tagihan'], ['status_bayar' => 'pending']);

            return $this->respond([
                'status'  => true,
                'message' => 'Token Midtrans berhasil dibuat',
                'data'    => [
                    'order_id'     => $orderId,
                    'token'        => $token,
                    'redirect_url' => $redirectUrl,
                    'gross_amount' => $grossAmount,
                    'periode'      => $tagihan['periode'],
                ]
            ]);
        }

        return $this->fail([
            'status'  => false,
            'message' => 'Gagal membuat sesi pembayaran Midtrans. HTTP: ' . $httpCode,
            'details' => json_decode($result, true)
        ], 500);
    }

    public function midtransStatus($orderId = null)
    {
        $nis = $this->getAuthNis();
        if (!$nis) {
            return $this->failUnauthorized("Autentikasi diperlukan");
        }

        if (empty($orderId)) {
            return $this->fail(["status" => false, "message" => "order_id diperlukan"], 400);
        }

        $serverKey = env('MIDTRANS_SERVER_KEY');
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "https://api.sandbox.midtrans.com/v2/" . $orderId . "/status");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Accept: application/json",
            "Authorization: Basic " . base64_encode($serverKey . ":")
        ]);
        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode == 200) {
            $resp = json_decode($result, true);
            $txStatus = $resp['transaction_status'] ?? 'pending';
            $paymentType = $resp['payment_type'] ?? 'midtrans';

            $statusTransaksi = 'pending';
            $statusBayar = 'pending';

            if ($txStatus === 'settlement' || ($txStatus === 'capture' && ($resp['fraud_status'] ?? '') === 'accept')) {
                $statusTransaksi = 'sukses';
                $statusBayar = 'lunas';
            } elseif (in_array($txStatus, ['cancel', 'deny', 'expire'])) {
                $statusTransaksi = 'gagal';
                $statusBayar = 'belum_lunas';
            }

            // Extract id_tagihan
            $lastDash = strrpos($orderId, '-');
            $idTagihan = $lastDash !== false ? substr($orderId, 0, $lastDash) : $orderId;

            // Update pembayaran
            $pembayaran = $this->pembayaranModel->where('va', $orderId)->first();
            if ($pembayaran) {
                $this->pembayaranModel->update($pembayaran['id_pembayaran'], [
                    'status_transaksi' => $statusTransaksi,
                    'metode_bayar'     => 'Midtrans: ' . ucwords(str_replace('_', ' ', $paymentType)),
                    'waktu_bayar'      => date('Y-m-d H:i:s'),
                ]);
            }

            // Update tagihan
            $this->tagihanModel->update($idTagihan, ['status_bayar' => $statusBayar]);

            return $this->respond([
                'status'  => true,
                'data'    => [
                    'order_id'           => $orderId,
                    'transaction_status' => $txStatus,
                    'status_transaksi'   => $statusTransaksi,
                    'status_bayar'       => $statusBayar,
                    'payment_type'       => $paymentType,
                    'va_numbers'         => $resp['va_numbers'] ?? null,
                ]
            ]);
        }

        return $this->fail([
            'status'  => false,
            'message' => 'Gagal memeriksa status ke Midtrans',
        ], 500);
    }
}
