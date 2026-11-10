<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;
use App\Models\M_Pembayaran;
use App\Models\M_Tagihan;

class MidtransWebhook extends ResourceController
{
    protected $pembayaranModel;
    protected $tagihanModel;

    public function __construct()
    {
        $this->pembayaranModel = new M_Pembayaran();
        $this->tagihanModel = new M_Tagihan();
    }

    public function notification()
    {
        $payload = $this->request->getBody();
        $notification = json_decode($payload, true);

        if (!$notification) {
            return $this->fail('Invalid payload');
        }

        $serverKey = env('MIDTRANS_SERVER_KEY');
        $orderId = $notification['order_id'];
        $statusCode = $notification['status_code'];
        $grossAmount = $notification['gross_amount'];
        $signatureKey = $notification['signature_key'];

        // Verify signature
        $expectedSignature = hash("sha512", $orderId . $statusCode . $grossAmount . $serverKey);
        
        if ($expectedSignature !== $signatureKey) {
            return $this->failUnauthorized('Invalid signature');
        }

        $transactionStatus = $notification['transaction_status'];
        $paymentType = $notification['payment_type'];
        $fraudStatus = $notification['fraud_status'] ?? '';

        // Extract id_tagihan from order_id (format: id_tagihan-timestamp)
        // id_tagihan can contain dashes (e.g. TGH-2605001), so we take everything before the LAST dash
        $lastDash = strrpos($orderId, '-');
        $idTagihan = $lastDash !== false ? substr($orderId, 0, $lastDash) : $orderId;

        // Find existing payment or create one if we missed the pending state
        $pembayaran = $this->pembayaranModel->where('va', $orderId)->first();

        // Determine status
        $statusTransaksi = 'pending';
        $statusBayar = 'pending';

        if ($transactionStatus == 'capture') {
            if ($fraudStatus == 'challenge') {
                $statusTransaksi = 'pending';
            } else if ($fraudStatus == 'accept') {
                $statusTransaksi = 'sukses';
                $statusBayar = 'lunas';
            }
        } else if ($transactionStatus == 'settlement') {
            $statusTransaksi = 'sukses';
            $statusBayar = 'lunas';
        } else if ($transactionStatus == 'cancel' || $transactionStatus == 'deny' || $transactionStatus == 'expire') {
            $statusTransaksi = 'gagal';
            $statusBayar = 'belum_lunas'; // Reset tagihan
        } else if ($transactionStatus == 'pending') {
            $statusTransaksi = 'pending';
        }

        // Update Pembayaran table
        if ($pembayaran) {
            $this->pembayaranModel->update($pembayaran['id_pembayaran'], [
                'status_transaksi' => $statusTransaksi,
                'metode_bayar' => 'Midtrans: ' . $paymentType,
                'waktu_bayar' => date('Y-m-d H:i:s')
            ]);
        } else {
            // If somehow payment record doesn't exist yet
            $this->pembayaranModel->insert([
                'id_pembayaran' => 'PAY-' . time() . rand(10,99),
                'id_tagihan' => $idTagihan,
                'metode_bayar' => 'Midtrans: ' . $paymentType,
                'va' => $orderId,
                'status_transaksi' => $statusTransaksi,
                'waktu_bayar' => date('Y-m-d H:i:s')
            ]);
        }

        // Update Tagihan table
        $this->tagihanModel->update($idTagihan, ['status_bayar' => $statusBayar]);

        return $this->respond(['status' => 'success'], 200);
    }
}
