<?php
/**
 * Sigma BI - Omie CORS Proxy
 * Este arquivo resolve o erro de CORS ao rodar o app em produção.
 * Suba este arquivo na raiz do seu domínio (adm.gestaobi.com.br).
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Responde imediatamente a requisições de preflight do navegador
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

// O endpoint vem como parâmetro na URL, ex: proxy.php?endpoint=financas/resumo/
$endpoint = $_GET['endpoint'] ?? '';

if (empty($endpoint)) {
    http_response_code(400);
    echo json_encode(["error" => "Endpoint da Omie não especificado."]);
    exit;
}

// Monta a URL final da Omie
$url = "https://app.omie.com.br/api/v1/" . ltrim($endpoint, '/');

// Captura o corpo da requisição (JSON vindo do Flutter)
$inputJSON = file_get_contents('php://input');

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
curl_setopt($ch, CURLOPT_POSTFIELDS, $inputJSON);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true); 
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/json',
    'Content-Length: ' . strlen($inputJSON)
));

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

if (curl_errno($ch)) {
    http_response_code(500);
    echo json_encode(["error" => "Erro no Proxy: " . curl_error($ch)]);
} else {
    http_response_code($httpCode);
    header('Content-Type: application/json');
    echo $response;
}

curl_close($ch);
?>
