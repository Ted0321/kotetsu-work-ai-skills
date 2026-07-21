param(
  [Parameter(Mandatory = $true)][string]$Id,
  [string]$Title = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

if ($Id -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
  throw "skill-id must be kebab-case (e.g. deliverable-review)"
}

if ([string]::IsNullOrWhiteSpace($Title)) { $Title = $Id }

$Dest = Join-Path $Root "skills\$Id"
if (Test-Path $Dest) { throw "Already exists: $Dest" }

New-Item -ItemType Directory -Path (Join-Path $Dest "examples") -Force | Out-Null
Copy-Item (Join-Path $Root "skills\_template\SKILL.md") (Join-Path $Dest "SKILL.md")
Copy-Item (Join-Path $Root "skills\_template\README.md") (Join-Path $Dest "README.md")
Copy-Item (Join-Path $Root "skills\_template\examples\sample_input_output.md") (Join-Path $Dest "examples\sample_input_output.md")

$skill = Get-Content (Join-Path $Dest "SKILL.md") -Raw -Encoding UTF8
$skill = $skill -replace 'name: skill-id-here', "name: $Id"
$skill = $skill -replace '# スキル名', "# $Title"
Set-Content -Path (Join-Path $Dest "SKILL.md") -Value $skill -Encoding UTF8

$readme = Get-Content (Join-Path $Dest "README.md") -Raw -Encoding UTF8
$readme = $readme -replace '# （スキル名）', "# $Title"
Set-Content -Path (Join-Path $Dest "README.md") -Value $readme -Encoding UTF8

$catalogPath = Join-Path $Root "CATALOG.md"
$catalog = Get-Content $catalogPath -Raw -Encoding UTF8
if ($catalog -notmatch [regex]::Escape("| $Id |")) {
  $date = Get-Date -Format "yyyy-MM-dd"
  $line = "| $date | $Id | $Title | draft | [skills/$Id](./skills/$Id/) | （一言を書く） |"
  Add-Content -Path $catalogPath -Value $line -Encoding UTF8
}

Write-Host "Created: $Dest"
Write-Host "Next: edit SKILL.md, examples, CATALOG one-liner, then git commit && push"
