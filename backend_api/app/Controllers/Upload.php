<?php

namespace App\Controllers;

class Upload extends BaseController
{
    /**
     * Serve uploaded bukti images from writable/uploads/bukti/
     */
    public function bukti($filename)
    {
        $path = WRITEPATH . 'uploads/bukti/' . $filename;

        if (!file_exists($path)) {
            throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound('File not found');
        }

        $mime = mime_content_type($path);

        return $this->response
            ->setHeader('Content-Type', $mime)
            ->setHeader('Cache-Control', 'public, max-age=86400')
            ->setBody(file_get_contents($path));
    }
}
