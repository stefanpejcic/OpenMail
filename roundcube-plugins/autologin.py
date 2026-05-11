<?php
$token = $_GET['token'] ?? '';

// 1. validate token
if (!preg_match('/^[a-zA-Z0-9_\-]{32,64}$/', $token)) {
    die('Invalid token format.');
}

$token_file = '/tmp/wmt_' . $token;

if (!file_exists($token_file)) {
    die("Error: Token file does not exist.");
}

// 2. Read
$raw_content = file_get_contents($token_file);

if ($raw_content === false) {
    die("Error: Could not read file contents.");
}

$data = json_decode($raw_content, true);

if (!$data) {
    if (empty(trim($raw_content))) {
        echo "<b>Note:</b> The file appears to be empty.";
    }
    die('<br>Terminating due to invalid data.');
}

// 3. Expiration Logic
$expires = new DateTime($data['expires'], new DateTimeZone('UTC'));
$now     = new DateTime('now', new DateTimeZone('UTC'));

if ($now > $expires) {
    unlink($token_file);
    die('<b>Result:</b> Token expired.');
}

// 4. Extract and unlink
$imap_user = $data['imap_user'];
$imap_pass = $data['imap_pass'];
unlink($token_file);

// 5. Roundcube Login Logic
$rc_url     = 'http://localhost/'; 
$cookie_jar = tempnam('/tmp', 'rc_');

$ch = curl_init($rc_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, true);
curl_setopt($ch, CURLOPT_COOKIEJAR, $cookie_jar);
curl_setopt($ch, CURLOPT_COOKIEFILE, $cookie_jar);
$login_page = curl_exec($ch);

preg_match('/name="_token"\s+value="([^"]+)"/', $login_page, $matches);
$csrf_token = $matches[1] ?? '';

curl_setopt($ch, CURLOPT_URL, $rc_url . '?_task=login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    '_user'   => $imap_user,
    '_pass'   => $imap_pass,
    '_task'   => 'login',
    '_action' => 'login',
    '_token'  => $csrf_token,
]));
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, false);
$response    = curl_exec($ch);
$header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$headers     = substr($response, 0, $header_size);
curl_close($ch);

// Forward Cookies
preg_match_all('/^Set-Cookie:\s*([^\r\n]+)/mi', $headers, $cookie_matches);
foreach ($cookie_matches[1] as $cookie) {
    header("Set-Cookie: $cookie", false);
}

@unlink($cookie_jar);
header('Location: /?_task=mail');
exit;
