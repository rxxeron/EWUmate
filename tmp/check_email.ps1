$u = Get-Content tmp/users.json | ConvertFrom-Json
$u.users | Where-Object { $_.id -eq 'f40f1035-303a-4f2f-a314-eeab07a253bc' } | Select-Object email
