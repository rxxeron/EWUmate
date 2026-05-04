$u = Get-Content tmp/users.json | ConvertFrom-Json
$target = $u.users | Where-Object { $_.email -eq 'rhrakibulhasan279@gmail.com' }
if ($target) {
    $target.id
} else {
    "Not Found"
}
