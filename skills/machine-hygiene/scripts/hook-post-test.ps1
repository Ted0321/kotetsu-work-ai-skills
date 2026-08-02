<#
machine-hygiene / hook-post-test.ps1

Claude Code の PostToolUse フック用。標準入力でフックJSONを受け取り、
「いま実行されたBashコマンドがテストだったか」を判定して、
テストだったときだけ残ったヘッドレスブラウザを終了する。

キャッシュはここでは消さない（coverage / test-results を直後に読みたいことがあるため）。
キャッシュ削除は SessionEnd フック側で行う。

終了コードは常に 0。フックがClaude Codeの動作を止めないようにする。
#>
$ErrorActionPreference = 'SilentlyContinue'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

$payload = [Console]::In.ReadToEnd()
if (-not $payload) { exit 0 }

$cmd = ''
$cwd = (Get-Location).Path
try {
  $json = $payload | ConvertFrom-Json
  if ($json.tool_input -and $json.tool_input.command) { $cmd = [string]$json.tool_input.command }
  if ($json.cwd) { $cwd = [string]$json.cwd }
} catch {
  # JSONとして読めなければ、payload全体をコマンド文字列とみなす
  $cmd = $payload
}
if (-not $cmd) { $cmd = $payload }

$testRe = '(npm|pnpm|yarn|bun|npx)\s+([a-z:-]+\s+)*(test|e2e)|vitest|jest|playwright\s+test|cypress\s+run|pytest|go\s+test|cargo\s+test|mvn\s+test|gradle\s+test|rspec|phpunit'
if ($cmd -notmatch $testRe) { exit 0 }

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir 'sweep.ps1') -Apply -Quiet -NoCaches -Root $cwd
exit 0
