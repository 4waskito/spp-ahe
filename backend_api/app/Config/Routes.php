<?php

namespace Config;

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */

// Root health check endpoint
$routes->get('/', static function () {
    return service('response')->setJSON([
        'status'    => true,
        'service'   => 'SPP Mobile Dedicated CI4 REST API',
        'version'   => '1.0.0',
        'database'  => 'pembayaran_spp_revisi',
        'timestamp' => date('Y-m-d H:i:s'),
    ]);
});

// Midtrans Webhook
$routes->post('pembayaran/midtrans-notification', 'MidtransWebhook::notification');

// Uploaded receipt images
$routes->get('uploads/bukti/(:any)', 'Upload::bukti/$1');

// REST API Group for Flutter Mobile Client
$routes->group('api', static function ($routes) {
    // Public Authentication
    $routes->post('auth/login_unified', 'Api\AuthController::loginUnified');
    $routes->post('auth/login', 'Api\AuthController::login');
    $routes->post('auth/login_admin', 'Api\AdminController::login');
    $routes->post('auth/logout', 'Api\AuthController::logout');

    // Protected Admin Endpoints (JWT Bearer Token)
    $routes->group('admin', ['filter' => 'jwtAuth'], static function ($routes) {
        $routes->get('dashboard', 'Api\AdminController::dashboard');
        $routes->get('pembayaran', 'Api\AdminController::pembayaran');
        $routes->post('pembayaran/approve/(:any)', 'Api\AdminController::approve/$1');
        $routes->post('pembayaran/reject/(:any)', 'Api\AdminController::reject/$1');

        // Tagihan
        $routes->get('tagihan', 'Api\AdminController::tagihanList');
        $routes->post('tagihan/generate', 'Api\AdminController::tagihanGenerate');
        $routes->delete('tagihan/(:any)', 'Api\AdminController::tagihanDelete/$1');

        // Siswa
        $routes->get('siswa', 'Api\AdminController::siswaList');
        $routes->post('siswa', 'Api\AdminController::siswaCreate');
        $routes->put('siswa/(:any)', 'Api\AdminController::siswaUpdate/$1');
        $routes->delete('siswa/(:any)', 'Api\AdminController::siswaDelete/$1');

        // Paket SPP
        $routes->get('paket', 'Api\AdminController::paketList');
    });

    // Protected Siswa Endpoints (JWT Bearer Token)
    $routes->group('siswa', ['filter' => 'jwtAuth'], static function ($routes) {
        $routes->get('profile', 'Api\SiswaController::profile');
        $routes->get('tagihan', 'Api\SiswaController::tagihan');
        $routes->post('bayar', 'Api\SiswaController::bayar');
        $routes->get('riwayat', 'Api\SiswaController::riwayat');
        $routes->post('midtrans/snap-token', 'Api\SiswaController::midtransSnap');
        $routes->get('midtrans/status/(:any)', 'Api\SiswaController::midtransStatus/$1');
    });
});
