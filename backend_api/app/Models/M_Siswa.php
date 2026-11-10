<?php

namespace App\Models;

use CodeIgniter\Model;

class M_Siswa extends Model
{
    protected $table         = 'siswa';
    protected $primaryKey    = 'nis';
    protected $useAutoIncrement = false;
    protected $returnType    = 'array';
    protected $allowedFields = ['nis', 'nama_murid', 'jenis_kelamin', 'id_paket', 'level', 'alamat', 'tanggal_lahir', 'password'];
}
