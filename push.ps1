# push.ps1 — セマンティックバージョニングで自動バージョン管理してプッシュ
# 使い方:
#   .\push.ps1 "コミットメッセージ"        → パッチ繰り上げ (0.1.0 → 0.1.1)  ※バグ修正
#   .\push.ps1 "コミットメッセージ" feat   → マイナー繰り上げ (0.1.0 → 0.2.0) ※機能追加

param(
    [Parameter(Mandatory=$false)]
    [string]$Message = "update",
    [string]$Type = "fix"
)

$versionFile = "version.js"

# 1. 現在のバージョンを version.js から読み込む
$raw = Get-Content $versionFile -Raw
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
$date = Get-Date -Format "yyyy-MM-dd"

# 3. コード変更をコミット（staged のみ; add は手動で先にやること）
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed"; exit 1 }

# 4. version.js を更新（ASCII 書き込みで BOM なし）
$newContent = "window.APP_VERSION = { version: '$newVersion', date: '$date' };"
Set-Content $versionFile -Value $newContent -Encoding ASCII
Write-Host "version.js -> v$newVersion ($date)"

# 5. version.js だけをコミット
git add -- $versionFile
git commit -m "chore: bump version to $newVersion"

# 6. プッシュ
git push origin main
Write-Host "Pushed! v$newVersion"
