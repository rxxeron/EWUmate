$u = Get-Content tmp/users.json | ConvertFrom-Json
$u.users | Where-Object { $_.email -like '*rakibul*' } | Select-Object email, id
