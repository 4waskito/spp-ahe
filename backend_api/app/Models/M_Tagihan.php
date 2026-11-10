<?php

namespace App\Models;

use CodeIgniter\Model;

class M_Tagihan extends Model
{
    protected $table         = 'tagihan';
    protected $primaryKey    = 'id_tagihan';
    protected $useAutoIncrement = false;
    protected $returnType    = 'array';
    protected $allowedFields = ['id_tagihan', 'nis', 'status_bayar', 'nominal', 'periode', 'jatuh_tempo'];

    /**
     * Count tagihan by status
     */
    public function countByStatus(string $status): int
    {
        return $this->where('status_bayar', $status)->countAllResults();
    }

    /**
     * Get tagihan grouped by periode and status for chart data
     */
    public function getChartData(int $months = 5): array
    {
        $db = \Config\Database::connect();
        $builder = $db->table('tagihan');

        $builder->select("periode, status_bayar, COUNT(*) as total")
                ->groupBy('periode, status_bayar')
                ->orderBy('jatuh_tempo', 'ASC');

        $results = $builder->get()->getResultArray();

        $periodeMap = [];
        foreach ($results as $row) {
            $periode = $row['periode'];
            if (!isset($periodeMap[$periode])) {
                $periodeMap[$periode] = ['lunas' => 0, 'belum lunas' => 0, 'pending' => 0];
            }
            $periodeMap[$periode][$row['status_bayar']] = (int)$row['total'];
        }

        // Take last N months
        $periodeMap = array_slice($periodeMap, -$months, $months, true);

        $labels = array_keys($periodeMap);
        $lunas  = array_column(array_values($periodeMap), 'lunas');
        $belum  = array_map(function ($p) {
            return $p['belum lunas'] + $p['pending'];
        }, array_values($periodeMap));

        return [
            'labels' => $labels,
            'lunas'  => $lunas,
            'belum'  => $belum,
        ];
    }
}
