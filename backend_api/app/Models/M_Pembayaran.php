<?php

namespace App\Models;

use CodeIgniter\Model;

class M_Pembayaran extends Model
{
    protected $table         = 'pembayaran';
    protected $primaryKey    = 'id_pembayaran';
    protected $useAutoIncrement = false;
    protected $returnType    = 'array';
    protected $allowedFields = ['id_pembayaran', 'id_tagihan', 'metode_bayar', 'va', 'status_transaksi', 'bukti_bayar', 'waktu_bayar'];

    /**
     * Get recent payments with siswa name and periode (JOIN tagihan + siswa)
     */
    public function getRecentPayments(int $limit = 5): array
    {
        $db = \Config\Database::connect();
        $builder = $db->table('pembayaran p');

        $builder->select('p.id_pembayaran, p.metode_bayar, p.status_transaksi, p.waktu_bayar, p.bukti_bayar, t.nominal, t.periode, s.nama_murid')
                ->join('tagihan t', 't.id_tagihan = p.id_tagihan')
                ->join('siswa s',   's.nis = t.nis')
                ->orderBy('p.waktu_bayar', 'DESC')
                ->limit($limit);

        return $builder->get()->getResultArray();
    }

    /**
     * Get payments filtered by date range and/or NIS
     */
    public function getFilteredPayments(?string $startDate = null, ?string $endDate = null, ?string $nis = null, int $limit = 100): array
    {
        $db = \Config\Database::connect();
        $builder = $db->table('pembayaran p');

        $builder->select('p.id_pembayaran, p.metode_bayar, p.status_transaksi, p.waktu_bayar, p.bukti_bayar, t.nominal, t.periode, s.nama_murid, s.nis')
                ->join('tagihan t', 't.id_tagihan = p.id_tagihan')
                ->join('siswa s',   's.nis = t.nis')
                ->orderBy('p.waktu_bayar', 'DESC');

        if ($startDate) {
            $builder->where('DATE(p.waktu_bayar) >=', $startDate);
        }
        if ($endDate) {
            $builder->where('DATE(p.waktu_bayar) <=', $endDate);
        }
        if ($nis) {
            $builder->like('s.nis', $nis);
        }

        $builder->limit($limit);

        return $builder->get()->getResultArray();
    }

    /**
     * Count pending verifications
     */
    public function countPending(): int
    {
        return $this->where('status_transaksi', 'pending')->countAllResults();
    }

    /**
     * Sum total successful payments
     */
    public function totalPendapatan(): float
    {
        $db = \Config\Database::connect();
        $builder = $db->table('pembayaran p');

        $builder->selectSum('t.nominal')
                ->join('tagihan t', 't.id_tagihan = p.id_tagihan')
                ->where('p.status_transaksi', 'sukses');

        $result = $builder->get()->getRowArray();
        return (float)($result['nominal'] ?? 0);
    }
}
