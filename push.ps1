# push.ps1 — セマンティックバージョニングで自動バージョン管理してプッシュ
# 使い方:
#   .\push.ps1 "コミットメッセージ"        → パッチ繰り上げ (0.1.0 → 0.1.1)  ※バグ修正
#   .\push.ps1 "コミットメッセージ" feat   → マイナー繰り上げ (0.1.0 → 0.2.0) ※機能追加

param(
    [Parameter(Mandatory=$false)]
    [string]$Message = "update",
    [string]$Type = "fix"
)

# スクリプトと同じディレクトリの version.js を使う
$versionFile = Join-Path $PSScriptRoot "version.js"

# 1. 現在のバージョンを version.js から読み込む
$raw = [IO.File]::ReadAllText($versionFile, [Text.Encoding]::UTF8)
if ($raw -match "version:\s*'(\d+)\.(\d+)\.(\d+)'") {
    [int]$major = $Matches[1]
    [int]$minor = $Matches[2]
    [int]$patch = $Matches[3]
} else {
    $major = 0; $minor = 1; $patch = 0
}

# 2. バージョンを繰り上げ
if ($Type -eq "feat") {
    $minor++; $patch = 0
} else {
    $patch++
}
$newVersion = "$major.$minor.$patch"

# 3. コード変更をコミット（staged のみ; add は手動で先にやること）
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed (exit $LASTEXITCODE)"; exit 1 }

# 4. version.js を更新（BOMなし UTF-8 で書き込み）
$date = Get-Date -Format "yyyy-MM-dd"
$newContent = "window.APP_VERSION = { version: '$newVersion', date: '$date' };"
[IO.File]::WriteAllText($versionFile, $newContent, (New-Object Text.UTF8Encoding $false))
Write-Host "version.js updated: v$newVersion ($date)"

# 5. version.js だけをコミット
git add -- version.js
git commit -m "chore: bump version to $newVersion"
if ($LASTEXITCODE -ne 0) { Write-Error "version commit failed"; exit 1 }

# 6. プッシュ
git push origin main
Write-Host "Pushed! v$newVersion"
