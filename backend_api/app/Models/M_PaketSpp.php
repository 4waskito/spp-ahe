<?php

namespace App\Models;

use CodeIgniter\Model;

class M_PaketSpp extends Model
{
    protected $table         = 'paket_spp';
    protected $primaryKey    = 'id_paket';
    protected $useAutoIncrement = false;
    protected $returnType    = 'array';
    protected $allowedFields = ['id_paket', 'nama_paket', 'nominal'];
}
