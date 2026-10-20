$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..\webapppolimusicv1_asp'
$common = Get-Content (Join-Path $root 'includes\common.asp') -Raw -Encoding UTF8
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('polimusic-' + [guid]::NewGuid().ToString('N') + '.vbs')
try {
    foreach ($page in Get-ChildItem $root -Filter '*.asp') {
        $source = Get-Content $page.FullName -Raw -Encoding UTF8
        $source = [regex]::Replace($source, '<%@.*?%>', '', 'Singleline')
        $source = $source.Replace('<!--#include file="includes/common.asp"-->', $common)
        $matches = [regex]::Matches($source, '<%(.*?)%>', 'Singleline')
        $code = New-Object Text.StringBuilder
        [void]$code.AppendLine('Option Explicit')
        [void]$code.AppendLine('WScript.Quit 0')
        # Las variables ASP se declaran para poder compilar con Windows Script Host.
        [void]$code.AppendLine('Dim Response, Request, Server, Session')
        foreach ($match in $matches) {
            $block = $match.Groups[1].Value
            if ($block.StartsWith('=')) {
                [void]$code.AppendLine('WScript.Echo ' + $block.Substring(1))
            } else {
                [void]$code.AppendLine(($block -replace '(?im)^\s*Option Explicit\s*$', ''))
            }
        }
        [IO.File]::WriteAllText($temporary, $code.ToString(), [Text.Encoding]::Unicode)
        $output = & cscript.exe //nologo $temporary 2>&1
        if ($LASTEXITCODE -ne 0) { throw "$($page.Name): $output" }
        Write-Output "Sintaxis VBScript OK: $($page.Name)"
    }
} finally { Remove-Item -LiteralPath $temporary -ErrorAction SilentlyContinue }
