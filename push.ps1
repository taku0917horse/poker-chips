# push.ps1 — コード変更をコミット後、version.js を自動更新してプッシュする
# 使い方: .\push.ps1 "コミットメッセージ"
#
# 手順:
#   1. 引数のメッセージで git commit（staged ファイル対象）
#   2. そのコミットハッシュと現在日時を version.js に書き込む
#   3. version.js のみを "chore: bump version" としてコミット
#   4. git push

param(
    [Parameter(Mandatory=$false)]
    [string]$Message = "update"
)

# 1. 現在の変更をコミット（staged のみ; add は手動で先にやること）
git commit -m $Message
if (-not $?) { Write-Error "git commit failed"; exit 1 }

# 2. そのコミットハッシュを取得
$hash = git rev-parse --short HEAD
$date = Get-Date -Format "yyyy-MM-dd"

# 3. version.js を更新
$content = "window.APP_VERSION = { hash: '$hash', date: '$date' };"
Set-Content -Path "version.js" -Value $content -Encoding utf8
Write-Host "version.js updated: $hash ($date)"

# 4. version.js だけを chore コミット
git add version.js
git commit -m "chore: bump version to $hash"

# 5. プッシュ
git push origin main
Write-Host "Pushed! rev. $hash · $date"
