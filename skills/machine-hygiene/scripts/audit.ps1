<#
machine-hygiene / audit.ps1  (Windows PowerShell 5.1 / PowerShell 7)

読み取り専用のマシン監査。何も終了せず、何も削除しない。
Markdownで出すので、そのままAIに読ませて「次に自動化できること」を出させる。

  powershell -NoProfile -File audit.ps1
  powershell -NoProfile -File audit.ps1 -Root C:\path\to\project
#>
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)

$ErrorActionPreference = 'SilentlyContinue'
$Root = (Get-Item -LiteralPath $Root -Force).FullName.TrimEnd('\')

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

$browserRe = '(chrome|chromium|msedge|microsoft-edge|firefox|headless_shell|chromedriver|geckodriver|msedgedriver|operadriver)'
$headlessRe = '(--headless|--remote-debugging-port|--remote-debugging-pipe|ms-playwright|puppeteer_dev_chrome_profile|chromedriver|geckodriver|msedgedriver|selenium-manager)'
$realProfileRe = '(AppData\\Local\\Google\\Chrome\\User Data|AppData\\Local\\Microsoft\\Edge\\User Data|AppData\\Roaming\\Mozilla\\Firefox|AppData\\Local\\Chromium\\User Data)'
$systemPathRe = '[A-Za-z]:\\Windows\\'
$runnerRe = '(vitest|jest|playwright|pytest|mocha|karma|cypress|webdriver)'

Write-Output ("# マシン監査 — " + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
Write-Output ''
Write-Output ('対象プロジェクト: `' + $Root + '`')
Write-Output ''

# ---- 1) テストの残骸 ---------------------------------------------------------
$now = Get-Date
$procs = @(Get-CimInstance -ClassName Win32_Process | Where-Object { $_.CommandLine })
$headless = @($procs | Where-Object {
  $_.CommandLine -notmatch 'machine-hygiene' -and
  $_.CommandLine -match $browserRe -and
  $_.CommandLine -match $headlessRe -and
  $_.CommandLine -notmatch $realProfileRe -and
  $_.CommandLine -notmatch $systemPathRe
})
$hlMem = ($headless | Measure-Object -Property WorkingSetSize -Sum).Sum
$hlOldMin = 0
if ($headless.Count -gt 0) {
  $hlOldMin = [int](($headless | ForEach-Object { ($now - $_.CreationDate).TotalMinutes } | Measure-Object -Maximum).Maximum)
}
$stale = @($procs | Where-Object {
  $_.CommandLine -notmatch 'machine-hygiene' -and
  $_.CommandLine -match $runnerRe -and
  $_.CreationDate -and (($now - $_.CreationDate).TotalMinutes -ge 15)
})

Write-Output '## 1. テストの残骸'
Write-Output ''
Write-Output '| 項目 | 値 |'
Write-Output '|---|---|'
Write-Output ("| 残っているヘッドレスブラウザ | {0}件 |" -f $headless.Count)
Write-Output ("| そのメモリ合計 | {0} |" -f (Format-Size ([double]$hlMem)))
Write-Output ("| 最も古い残骸の経過時間 | {0}分 |" -f $hlOldMin)
Write-Output ("| 15分以上生きているテストランナー | {0}件 |" -f $stale.Count)
Write-Output ''

# ---- 2) 重いプロセス ---------------------------------------------------------
Write-Output '## 2. いま重いプロセス（上位5）'
Write-Output ''
Write-Output '```'
Get-Process | Sort-Object -Property WorkingSet64 -Descending | Select-Object -First 5 |
  ForEach-Object { Write-Output ("MEM {0,7:N0}MB  CPU {1,8:N0}s  {2}" -f ($_.WorkingSet64 / 1MB), $_.CPU, $_.ProcessName) }
Write-Output '```'
Write-Output ''

# ---- 3) プロジェクト内のキャッシュ ------------------------------------------
$cacheDirs = @(
  'node_modules\.cache', 'node_modules\.vite', '.next\cache', '.turbo', '.parcel-cache',
  '.vite', '.nuxt', '.svelte-kit', '.astro', '.angular\cache', '.eslintcache',
  'coverage', '.nyc_output', 'test-results', 'playwright-report', 'blob-report',
  '.pytest_cache', '.mypy_cache', '.ruff_cache'
)
Write-Output '## 3. 消していいキャッシュ（プロジェクト内）'
Write-Output ''
Write-Output '| パス | サイズ |'
Write-Output '|---|---|'
$total = [double]0
$found = 0
foreach ($rel in $cacheDirs) {
  $t = Join-Path $Root $rel
  if (-not (Test-Path -LiteralPath $t)) { continue }
  $s = Get-PathSize $t
  $total += $s; $found++
  Write-Output ("| ``{0}`` | {1} |" -f $rel, (Format-Size $s))
}
$pyc = @(Get-ChildItem -LiteralPath $Root -Recurse -Force -Directory -Filter '__pycache__' |
  Where-Object { $_.FullName -notmatch '\\(\.git|node_modules)\\' })
if ($pyc.Count -gt 0) {
  $s = [double]0
  foreach ($d in $pyc) { $s += Get-PathSize $d.FullName }
  $total += $s; $found++
  Write-Output ("| ``__pycache__``（再帰） | {0} |" -f (Format-Size $s))
}
if ($found -eq 0) { Write-Output '| （なし） | - |' }
Write-Output ''
Write-Output ("**合計: {0}**" -f (Format-Size $total))
Write-Output ''

# ---- 4) TEMP の自動化残骸 -----------------------------------------------------
$tmp = $env:TEMP
$patterns = @('playwright*', 'puppeteer_dev_*', 'chromedriver*', 'scoped_dir*', 'geckodriver*', 'rust_mozprofile*')
$tmpN = 0; $tmpSize = [double]0
foreach ($pat in $patterns) {
  foreach ($d in @(Get-ChildItem -LiteralPath $tmp -Filter $pat -Force)) {
    $tmpN++; $tmpSize += Get-PathSize $d.FullName
  }
}
Write-Output '## 4. 一時フォルダに残った自動化プロファイル'
Write-Output ''
Write-Output ("``{0}`` に {1}件 / {2}" -f $tmp, $tmpN, (Format-Size $tmpSize))
Write-Output ''

# ---- 5) ディスク --------------------------------------------------------------
Write-Output '## 5. ディスク'
Write-Output ''
Write-Output '```'
$drive = Get-PSDrive -Name ($Root.Substring(0, 1))
if ($drive) {
  Write-Output ("{0}: 空き {1} / 全体 {2}" -f $drive.Name, (Format-Size ([double]$drive.Free)), (Format-Size ([double]($drive.Free + $drive.Used))))
}
Write-Output '```'
Write-Output ''

# ---- 6) 判定 -----------------------------------------------------------------
Write-Output '## 6. 判定'
Write-Output ''
$need = 0
if ($headless.Count -gt 0) { Write-Output ("- ヘッドレス残骸が {0}件（{1}）。テスト後の自動終了フックを入れる価値あり。" -f $headless.Count, (Format-Size ([double]$hlMem))); $need++ }
if ($stale.Count -gt 0) { Write-Output ("- 15分以上生きているテストランナーが {0}件。ハングしたまま放置されている可能性。" -f $stale.Count); $need++ }
if ($total -gt 512MB) { Write-Output ("- プロジェクト内キャッシュが {0}。セッション終了時の自動削除が効く。" -f (Format-Size $total)); $need++ }
if ($tmpSize -gt 512MB) { Write-Output ("- 一時フォルダの自動化残骸が {0}。``sweep.ps1 -Apply -Deep`` の対象。" -f (Format-Size $tmpSize)); $need++ }
if ($need -eq 0) { Write-Output '- 特に問題なし。掃除不要。' }
Write-Output ''
Write-Output '> 実行するには: `powershell -NoProfile -File scripts\sweep.ps1`（確認）→ `-Apply` を付けて実行'
