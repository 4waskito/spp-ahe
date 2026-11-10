<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use App\Libraries\JWT;
use Exception;

class JwtAuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $authHeader = $request->getServer("HTTP_AUTHORIZATION");
        if (!$authHeader) {
            $authHeader = $request->getHeaderLine("Authorization");
        }

        if (!$authHeader) {
            $response = service("response");
            return $response->setStatusCode(401)->setJSON([
                "status"  => false,
                "message" => "Header Authorization Bearer token diperlukan"
            ]);
        }

        $arr = explode(" ", $authHeader);
        $token = $arr[1] ?? "";

        if (empty($token)) {
            $response = service("response");
            return $response->setStatusCode(401)->setJSON([
                "status"  => false,
                "message" => "Format token Bearer tidak valid"
            ]);
        }

        try {
            $decoded = JWT::decode($token);
            $db = \Config\Database::connect();
            
            if (isset($decoded["role"]) && $decoded["role"] === "admin") {
                $admin = $db->table("admin")->where("id_admin", $decoded["sub"] ?? "")->get()->getRowArray();
                if (!$admin) {
                    $response = service("response");
                    return $response->setStatusCode(401)->setJSON([
                        "status"  => false,
                        "message" => "Admin pemilik token tidak ditemukan"
                    ]);
                }
                $_SERVER["AUTH_ADMIN_ID"] = $decoded["sub"];
                $_SERVER["AUTH_ADMIN"] = json_encode($admin);
            } else {
                $siswa = $db->table("siswa")->where("nis", $decoded["sub"] ?? "")->get()->getRowArray();
                if (!$siswa) {
                    $response = service("response");
                    return $response->setStatusCode(401)->setJSON([
                        "status"  => false,
                        "message" => "Siswa pemilik token tidak ditemukan"
                    ]);
                }
                $_SERVER["AUTH_SISWA_NIS"] = $decoded["sub"];
                $_SERVER["AUTH_SISWA"] = json_encode($siswa);
            }
        } catch (Exception $e) {
            $response = service("response");
            return $response->setStatusCode(401)->setJSON([
                "status"  => false,
                "message" => "Token otentikasi tidak valid atau kedaluwarsa: " . $e->getMessage()
            ]);
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // No action needed after request
    }
}
