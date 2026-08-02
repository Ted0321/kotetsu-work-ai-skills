<#
machine-hygiene / sweep.ps1  (Windows PowerShell 5.1 / PowerShell 7)

テスト実行で残ったヘッドレスブラウザを終了し、再生成可能なキャッシュを削除する。
既定は DRY-RUN。実際に終了・削除するには -Apply を付ける。

  powershell -NoProfile -File sweep.ps1
  powershell -NoProfile -File sweep.ps1 -Apply
  powershell -NoProfile -File sweep.ps1 -Apply -Deep

終了コードは常に 0（フックを止めないため）。
#>
[CmdletBinding()]
param(
  [switch]$Apply,
  [switch]$Deep,
  [switch]$Quiet,
  [switch]$NoProcs,
  [switch]$NoCaches,
  [string]$Root = (Get-Location).Path,
  [int]$MinAge = 3,
  [string[]]$Exclude = @()
)

$ErrorActionPreference = 'SilentlyContinue'
$Version = '0.1.0'
$lines = New-Object System.Collections.ArrayList

function Add-Line([string]$s) { [void]$lines.Add($s) }
function Format-Size([double]$bytes) {
  if ($bytes -ge 1GB) { '{0:N1}GB' -f ($bytes / 1GB) }
  elseif ($bytes -ge 1MB) { '{0:N0}MB' -f ($bytes / 1MB) }
  else { '{0:N0}KB' -f ($bytes / 1KB) }
}
function Get-PathSize([string]$p) {
  $item = Get-Item -LiteralPath $p -Force
  if (-not $item) { return 0 }
  if (-not $item.PSIsContainer) { return [double]$item.Length }
  $m = Get-ChildItem -LiteralPath $p -Recurse -Force -File | Measure-Object -Property Length -Sum
  if ($m.Sum) { return [double]$m.Sum } else { return 0 }
}

# ---- ルートの安全確認 -------------------------------------------------------
$rootItem = Get-Item -LiteralPath $Root -Force
if (-not $rootItem) { Write-Error "sweep.ps1: -Root が見つかりません"; exit 0 }
$Root = $rootItem.FullName.TrimEnd('\')
# 削除を伴うときだけ、危険なルートを弾く（プロセス掃除だけなら関係ない）
if ((-not $NoCaches) -or $Deep) {
  if ($Root -eq $env:USERPROFILE -or $Root -match '^[A-Za-z]:\\?$') {
    Write-Warning "sweep.ps1: 安全のためドライブ直下と %USERPROFILE% 直下ではキャッシュ削除をしません"
    $NoCaches = $true
    $Deep = $false
  }
}

# ---- 1) 残ったヘッドレスブラウザ --------------------------------------------
# 自動化でしか付かないフラグ／パスだけを対象にする。
$headlessRe = '(--headless|--remote-debugging-port|--remote-debugging-pipe|ms-playwright|puppeteer_dev_chrome_profile|\.cache\\puppeteer|chromedriver|geckodriver|msedgedriver|selenium-manager)'
# 普段使いのブラウザ（実プロファイル）は絶対に触らない。
$realProfileRe = '(AppData\\Local\\Google\\Chrome\\User Data|AppData\\Local\\Microsoft\\Edge\\User Data|AppData\\Roaming\\Mozilla\\Firefox|AppData\\Local\\Chromium\\User Data)'

$victims = @()
if (-not $NoProcs) {
  $now = Get-Date
  $victims = @(Get-CimInstance -ClassName Win32_Process |
    Where-Object {
      $_.CommandLine -and
      $_.ProcessId -ne $PID -and
      $_.CommandLine -notmatch 'machine-hygiene' -and
      $_.CommandLine -match $headlessRe -and
      $_.CommandLine -notmatch $realProfileRe -and
      $_.CreationDate -and (($now - $_.CreationDate).TotalSeconds -ge $MinAge)
    })
}

if ($victims.Count -gt 0) {
  $mem = ($victims | Measure-Object -Property WorkingSetSize -Sum).Sum
  if ($Apply) {
    foreach ($v in $victims) { Stop-Process -Id $v.ProcessId -Force }
    Add-Line ("ヘッドレス残骸を終了: {0}件（メモリ約 {1} 解放）" -f $victims.Count, (Format-Size $mem))
  } else {
    Add-Line ("[dry-run] 終了対象のヘッドレス残骸: {0}件（メモリ約 {1}） pid: {2}" -f `
      $victims.Count, (Format-Size $mem), (($victims | ForEach-Object { $_.ProcessId }) -join ' '))
  }
}

# ---- 2) プロジェクト内のキャッシュ ------------------------------------------
# すべて「消しても再生成される」ものだけ。ソース・.git・.env は対象外。
$cacheDirs = @(
  'node_modules\.cache', 'node_modules\.vite', '.next\cache', '.turbo', '.parcel-cache',
  '.vite', '.nuxt', '.svelte-kit', '.astro', '.angular\cache', '.eslintcache',
  'coverage', '.nyc_output', 'test-results', 'playwright-report', 'blob-report',
  '.pytest_cache', '.mypy_cache', '.ruff_cache'
)

$removed = 0
$freed = [double]0
if (-not $NoCaches) {
  foreach ($rel in $cacheDirs) {
    if ($Exclude -contains $rel) { continue }
    $target = Join-Path $Root $rel
    if (-not (Test-Path -LiteralPath $target)) { continue }
    # ルート配下であることを再確認
    $full = (Get-Item -LiteralPath $target -Force).FullName
    if (-not $full.StartsWith($Root + '\', [StringComparison]::OrdinalIgnoreCase)) { continue }

    $size = Get-PathSize $full
    $freed += $size
    $removed++
    if ($Apply) { Remove-Item -LiteralPath $full -Recurse -Force }
    else { Add-Line ("[dry-run] 削除対象: {0}（{1}）" -f $rel, (Format-Size $size)) }
  }

  # __pycache__ は再帰的に（.git と node_modules の中は見ない）
  $pycache = @(Get-ChildItem -LiteralPath $Root -Recurse -Force -Directory -Filter '__pycache__' |
    Where-Object { $_.FullName -notmatch '\\(\.git|node_modules)\\' })
  foreach ($d in $pycache) {
    $size = Get-PathSize $d.FullName
    $freed += $size
    $removed++
    if ($Apply) { Remove-Item -LiteralPath $d.FullName -Recurse -Force }
  }
}

# ---- 3) -Deep: TEMP に残った自動化プロファイル -------------------------------
if ($Deep) {
  $tmp = $env:TEMP
  $patterns = @('playwright*', 'puppeteer_dev_*', 'chromedriver*', 'scoped_dir*', 'geckodriver*', 'rust_mozprofile*')
  $cut = (Get-Date).AddMinutes(-60)
  foreach ($pat in $patterns) {
    foreach ($d in (Get-ChildItem -LiteralPath $tmp -Filter $pat -Force | Where-Object { $_.LastWriteTime -lt $cut })) {
      $size = Get-PathSize $d.FullName
      $freed += $size
      $removed++
      if ($Apply) { Remove-Item -LiteralPath $d.FullName -Recurse -Force }
      else { Add-Line ("[dry-run] TEMP削除対象: {0}（{1}）" -f $d.FullName, (Format-Size $size)) }
    }
  }
}

if ($removed -gt 0 -and $Apply) {
  Add-Line ("キャッシュ／残骸を削除: {0}箇所（{1} 解放）" -f $removed, (Format-Size $freed))
}

if ($lines.Count -eq 0) {
  if (-not $Quiet) { Write-Output '[machine-hygiene] 掃除するものはありませんでした' }
  exit 0
}

Write-Output "[machine-hygiene v$Version]"
$lines | ForEach-Object { Write-Output $_ }
exit 0
