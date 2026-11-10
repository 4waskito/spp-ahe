<?php

namespace App\Libraries;

use Exception;

class JWT
{
    private static string $secretKey = "SPP_MOBILE_SECURE_JWT_SECRET_KEY_2026_!@#$%^&*()";

    public static function getKey(): string
    {
        return getenv("JWT_SECRET_KEY") ?: self::$secretKey;
    }

    public static function encode(array $payload, ?string $key = null): string
    {
        $key = $key ?? self::getKey();
        $header = ["typ" => "JWT", "alg" => "HS256"];

        $segments = [];
        $segments[] = self::urlSafeB64Encode(json_encode($header));
        $segments[] = self::urlSafeB64Encode(json_encode($payload));
        $signingInput = implode(".", $segments);

        $signature = hash_hmac("sha256", $signingInput, $key, true);
        $segments[] = self::urlSafeB64Encode($signature);

        return implode(".", $segments);
    }

    public static function decode(string $jwt, ?string $key = null): array
    {
        $key = $key ?? self::getKey();
        $parts = explode(".", $jwt);

        if (count($parts) !== 3) {
            throw new Exception("Invalid token format");
        }

        list($headb64, $bodyb64, $cryptob64) = $parts;

        $header = json_decode(self::urlSafeB64Decode($headb64), true);
        if (!$header || ($header["alg"] ?? "") !== "HS256") {
            throw new Exception("Unsupported or invalid algorithm");
        }

        $payload = json_decode(self::urlSafeB64Decode($bodyb64), true);
        if (!$payload) {
            throw new Exception("Invalid token payload");
        }

        $sig = self::urlSafeB64Decode($cryptob64);
        $expectedSig = hash_hmac("sha256", "$headb64.$bodyb64", $key, true);

        if (!hash_equals($expectedSig, $sig)) {
            throw new Exception("Signature verification failed");
        }

        if (isset($payload["exp"]) && time() >= $payload["exp"]) {
            throw new Exception("Token has expired");
        }

        return $payload;
    }

    private static function urlSafeB64Encode(string $data): string
    {
        return str_replace(["+", "/", "="], ["-", "_", ""], base64_encode($data));
    }

    private static function urlSafeB64Decode(string $data): string
    {
        $remainder = strlen($data) % 4;
        if ($remainder) {
            $padlen = 4 - $remainder;
            $data .= str_repeat("=", $padlen);
        }
        return base64_decode(strtr($data, "-_", "+/"));
    }
}