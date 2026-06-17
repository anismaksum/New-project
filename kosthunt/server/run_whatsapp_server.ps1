param(
  [Parameter(Mandatory = $true)]
  [string] $Token,

  [string] $Port = "8787"
)

$env:FONNTE_TOKEN = $Token
$env:WHATSAPP_PORT = $Port

dart run server\whatsapp_server.dart
