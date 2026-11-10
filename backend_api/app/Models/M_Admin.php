<?php

namespace App\Models;

use CodeIgniter\Model;

class M_Admin extends Model
{
    protected $table         = 'admin';
    protected $primaryKey    = 'id_admin';
    protected $useAutoIncrement = false;
    protected $returnType    = 'array';
    protected $allowedFields = ['id_admin', 'username', 'password'];
}
