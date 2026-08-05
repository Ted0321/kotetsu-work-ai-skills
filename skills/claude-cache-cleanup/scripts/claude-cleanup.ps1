<#
claude-cleanup.ps1 — Claude Code が溜め込む古いデータを安全に片付ける週次スクリプト (Windows)
配布元: https://github.com/Ted0321/kotetsu-work-ai-skills (skills/claude-cache-cleanup)

安全設計（このスクリプトが守ること）:
  1. $targets に列挙した場所しか触らない（allowlist方式）
  2. 保持日数より新しいファイルには触らない → アクティブ・直近のものは構造的に対象外
  3. ファイル単位で削除する。フォルダ丸ごとの削除はしない
     （削除後に空になったサブフォルダのみ削除する）
  4. projects\ 配下は *.jsonl（セッションログ）だけを対象にする
     → 同居している自動メモリ (memory\) 等は消さない
  5. 保持日数 7日未満では起動を拒否する

使い方:
  powershell -NoProfile -ExecutionPolicy Bypass -File claude-cleanup.ps1 -DryRun  # 一覧のみ
  powershell -NoProfile -ExecutionPolicy Bypass -File claude-cleanup.ps1          # 実行

注意: このファイルは UTF-8 (BOM付き) で保存すること（Windows PowerShell 5.1 の文字化け対策）
#>
param(
  [int]$RetentionDays = 30,
  [int]$SnapshotRetentionDays = 14,
  [switch]$DryRun
)

# 安全装置: 保持日数7日未満では動かない
if ($RetentionDays -lt 7 -or $SnapshotRetentionDays -lt 7) {
  Write-Error ("保持日数7日未満は許可されていません (RetentionDays={0}, SnapshotRetentionDays={1})" -f $RetentionDays, $SnapshotRetentionDays)
  exit 1
}

$claudeDir = Join-Path $HOME '.claude'
$logFile   = Join-Path $claudeDir 'cleanup\cleanup.log'
New-Item -ItemType Directory -Force -Path (Split-Path $logFile) | Out-Null

function Write-Log([string]$Message) {
  $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
  Write-Output $line
  Add-Content -Path $logFile -Value $line
}

function Format-Size([double]$MB) {
  if ($MB -ge 1024) { return ('約{0}GB' -f [math]::Round($MB / 1024, 1)) }
  return ('約{0}MB' -f [math]::Round($MB, 1))
}

# 掃除対象のallowlist（ここに無い場所は絶対に触らない。存在しない場所は自動でスキップ）
# Filter='*.jsonl' は projects\ でセッションログだけを対象にするため
$targets = @(
  @{ Path = (Join-Path $claudeDir 'projects');        Days = $RetentionDays;         Filter = '*.jsonl' }
  @{ Path = (Join-Path $claudeDir 'todos');           Days = $RetentionDays;         Filter = '*' }
  @{ Path = (Join-Path $claudeDir 'tasks');           Days = $RetentionDays;         Filter = '*' }
  @{ Path = (Join-Path $claudeDir 'shell-snapshots'); Days = $SnapshotRetentionDays; Filter = '*' }
  @{ Path = (Join-Path $claudeDir 'file-history');    Days = $RetentionDays;         Filter = '*' }
  @{ Path = (Join-Path $claudeDir 'backups');         Days = $RetentionDays;         Filter = '*' }
  @{ Path = (Join-Path $claudeDir 'statsig');         Days = $RetentionDays;         Filter = '*' }
)
if ($env:LOCALAPPDATA) {
  $targets += @{ Path = (Join-Path $env:LOCALAPPDATA 'claude-cli-nodejs'); Days = $RetentionDays; Filter = '*' }
}
# 一時フォルダの claude-*（Claude Code セッションの作業ディレクトリ）
foreach ($d in @(Get-ChildItem -Path $env:TEMP -Directory -Filter 'claude-*' -ErrorAction SilentlyContinue)) {
  $targets += @{ Path = $d.FullName; Days = $RetentionDays; Filter = '*' }
}

$totalFiles = 0
$totalMB    = 0.0
$mode = if ($DryRun) { 'dry_run' } else { 'run' }
Write-Log ("===== claude-cleanup 開始 (retention={0}d / snapshots={1}d, {2}) =====" -f $RetentionDays, $SnapshotRetentionDays, $mode)

foreach ($t in $targets) {
  if (-not (Test-Path -LiteralPath $t.Path)) { continue }
  $full = (Resolve-Path -LiteralPath $t.Path).Path

  # 安全装置: HOME / TEMP / LOCALAPPDATA の配下以外は何があっても触らない
  $allowedRoots = @($HOME, $env:TEMP, $env:LOCALAPPDATA) | Where-Object { $_ }
  $isAllowed = $false
  foreach ($root in $allowedRoots) {
    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { $isAllowed = $true }
  }
  if (-not $isAllowed) { Write-Log ("SKIP(unsafe path): {0}" -f $full); continue }

  $cutoff = (Get-Date).AddDays(-1 * $t.Days)
  $files = @(Get-ChildItem -LiteralPath $full -File -Recurse -Force -Filter $t.Filter -ErrorAction SilentlyContinue |
             Where-Object { $_.LastWriteTime -lt $cutoff })
  $sum = ($files | Measure-Object -Property Length -Sum).Sum
  if (-not $sum) { $sum = 0 }
  $mb = $sum / 1MB

  if ($DryRun) {
    Write-Log ("DRY-RUN: {0} : {1}件 / {2} が対象（{3}日より古いもの）" -f $full, $files.Count, (Format-Size $mb), $t.Days)
  }
  else {
    $files | Remove-Item -Force -ErrorAction SilentlyContinue
    # 空になったサブフォルダを削除（対象ルート自体は残す）
    Get-ChildItem -LiteralPath $full -Directory -Recurse -Force -ErrorAction SilentlyContinue |
      Sort-Object -Property @{ Expression = { $_.FullName.Length }; Descending = $true } |
      Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue) } |
      Remove-Item -Force -ErrorAction SilentlyContinue
    if ($files.Count -gt 0) {
      Write-Log ("CLEAN: {0} : {1}件削除 / {2}回収" -f $full, $files.Count, (Format-Size $mb))
    }
  }
  $totalFiles += $files.Count
  $totalMB    += $mb
}

if ($DryRun) {
  Write-Log "===== ドライラン終了（何も削除していません） ====="
}
else {
  Write-Log ("===== 完了: 合計 {0}件削除 / {1}回収 =====" -f $totalFiles, (Format-Size $totalMB))
}

# ログ肥大化防止（直近400行のみ保持）
if (Test-Path -LiteralPath $logFile) {
  $tail = Get-Content -LiteralPath $logFile -Tail 400
  Set-Content -Path $logFile -Value $tail
}

exit 0
