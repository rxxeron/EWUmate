$u = Get-Content tmp/users_full.json | ConvertFrom-Json
$u.users | Where-Object { $_.email -like '*rakibul*' } | Select-Object email, id
