$ErrorActionPreference = 'SilentlyContinue'
$out = "audit_report.md"
Set-Content $out "# QA Audit Report
"

function Add-Section($title, $pattern, $caseSensitive) {
    Add-Content $out "## $title"
    $matches = if ($caseSensitive) {
        Get-ChildItem lib -Recurse -Filter *.dart | Select-String -Pattern $pattern -CaseSensitive
    } else {
        Get-ChildItem lib -Recurse -Filter *.dart | Select-String -Pattern $pattern
    }
    
    if ($matches) {
        $matches | ForEach-Object {
            $file = $_.Filename
            $line = $_.LineNumber
            $text = $_.Line.Trim() -replace '\|', ' '
            Add-Content $out "- **$($file):$($line)**: ``"
        }
    } else {
        Add-Content $out "No matches found."
    }
    Add-Content $out "
"
}

Add-Section "Providers" 'final.*Provider|StateNotifierProvider|FutureProvider|StreamProvider|ChangeNotifierProvider|Provider\(' $true
Add-Section "Direct Supabase" 'Supabase\.instance\.client' $true
Add-Section "Prints" '\bprint\(|debugPrint\(' $true
Add-Section "TODOs" 'TODO|FIXME|HACK|XXX|\bTEMP\b' $true
Add-Section "Hardcoded URLs" 'http://|https://|127\.0\.0\.1|localhost' $true
Add-Section "Deprecated" '@deprecated|\.deprecated' $true

Add-Content $out "## God Files (>500 lines)"
$godFiles = Get-ChildItem -Path lib -Recurse -File -Filter *.dart | ForEach-Object { [PSCustomObject]@{Lines=(Get-Content $_.FullName | Measure-Object -Line).Lines; File=$_.FullName} } | Where-Object { $_.Lines -gt 500 } | Sort-Object Lines -Descending
if ($godFiles) {
    $godFiles | ForEach-Object {
        $lines = $_.Lines
        $file = $_.File -replace [regex]::Escape("f:\EWUmate\EWUmate_Clean\ewumate_v2\ewumate_production_build\"), ""
        Add-Content $out "- **$lines lines**: $file"
    }
} else {
    Add-Content $out "No god files found."
}
