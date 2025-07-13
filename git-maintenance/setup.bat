@echo off
chcp 932 >nul

echo ========================================
echo Git AutoCRLF ツール 初回セットアップ
echo ========================================
echo.

rem confディレクトリの確認
if not exist "conf" (
    echo confディレクトリを作成します...
    mkdir conf
)

rem 設定ファイルのコピー
if not exist "conf\config.txt" (
    if exist "conf\config.txt.sample" (
        echo config.txt を作成します...
        copy "conf\config.txt.sample" "conf\config.txt" >nul
        echo 作成完了: conf\config.txt
    ) else (
        echo エラー: conf\config.txt.sample が見つかりません。
    )
) else (
    echo conf\config.txt は既に存在します。
)

if not exist "conf\repositories.txt" (
    if exist "conf\repositories.txt.sample" (
        echo repositories.txt を作成します...
        copy "conf\repositories.txt.sample" "conf\repositories.txt" >nul
        echo 作成完了: conf\repositories.txt
    ) else (
        echo エラー: conf\repositories.txt.sample が見つかりません。
    )
) else (
    echo conf\repositories.txt は既に存在します。
)

rem ディレクトリ作成
if not exist "log" (
    echo logディレクトリを作成します...
    mkdir log
)

if not exist "backup" (
    echo backupディレクトリを作成します...
    mkdir backup
)

echo.
echo ========================================
echo セットアップ完了
echo ========================================
echo.
echo 次の手順:
echo 1. conf\config.txt を編集してBASE_DIRを設定
echo 2. conf\repositories.txt を編集して対象リポジトリを追加
echo 3. git-autocrlf-recovery.bat を実行
echo.

echo セットアップが完了しました。
pause
